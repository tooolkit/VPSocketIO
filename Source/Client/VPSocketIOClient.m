//
//  VPSocketIOClient.m
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/24.
//  Copyright © 2018年 bngj. All rights reserved.
//

#import "VPSocketIOClient.h"
#import "VPSocketManager.h"
#import "DefaultSocketLogger.h"
#import "VPSocketManager.h"
#import "VPSocketAckManager.h"
#import "VPSocketPacket.h"
#import "VPSocketOnAckCallback.h"



NSString *const kSocketEventConnect            = @"connect";
NSString *const kSocketEventDisconnect         = @"disconnect";
NSString *const kSocketEventError              = @"error";
NSString *const kSocketEventPing               = @"ping";
NSString *const kSocketEventPong               = @"pong";
NSString *const kSocketEventReconnect          = @"reconnect";
NSString *const kSocketEventReconnectAttempt   = @"reconnectAttempt";
NSString *const kSocketEventStatusChange       = @"statusChange";


@interface VPSocketIOClient(){
    int currentAck;
    
    NSDictionary *eventStrings;
    NSDictionary *statusStrings;
}

@property (nonatomic, strong, readonly) NSString* logType;


@end

@implementation VPSocketIOClient

@synthesize anyHandler;

@synthesize handlers;

@synthesize manager;

@synthesize nsp;

@synthesize status;

- (NSString *)logType {
    return [NSString stringWithFormat:@"SocketIOClient %@ ", self->nsp];
}

- (instancetype)initWith:(VPSocketManager *)manager namesp:(NSString *)namesp {
    self = [super init];
    if (self) {
        [self setDefaultValues];
        self.manager = manager;
        nsp = namesp;
    }
    return self;
}

- (void)dealloc {
    [DefaultSocketLogger.logger log:@"Client is being released"
                               type:[self logType]];
}

- (void)connect {
    [self connectWithTimeoutAfter:0 withHandler:nil];
}

- (void)connectWithTimeoutAfter:(double)timeout withHandler:(VPSocketIOVoidHandler)handler {
    NSString *reason = [NSString stringWithFormat:@"Invalid timeout %f",timeout];
    NSAssert((timeout >= 0), reason);

    if (!(self.manager && self->status != VPSocketIOClientStatusConnected)) {
        [DefaultSocketLogger.logger log:@"Tried connecting on an already connected socket" type:self.logType];
        return;
    }
    [self changeStatus:VPSocketIOClientStatusConnecting];
    [self joinNamespace];
    
    if ([self.manager status] == VPSocketIOClientStatusConnected && [nsp isEqualToString:@"/"]) {
        // We might not get a connect event for the default nsp, fire immediately
        [self didConnect:nsp];
        return;
    }
    
    if (timeout == 0) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), self.manager.handleQueue, ^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.status == VPSocketIOClientStatusConnecting || strongSelf.status == VPSocketIOClientStatusNotConnected) {
            [strongSelf changeStatus:VPSocketIOClientStatusDisconnected];
            [strongSelf leaveNamespace];
            handler();
        }else{
            return;
        }
        
    });
    
}

- (void)didConnect:(NSString *)namespace {
    if (status == VPSocketIOClientStatusConnected) {
        return;
    }
    [DefaultSocketLogger.logger log:@"Socket connected" type:self.logType];
    [self changeStatus:VPSocketIOClientStatusConnected];
    [self handleClientEvent:eventStrings[@(VPSocketClientEventConnect)] withData:@[namespace]];
}

- (void)didDisconnect:(NSString *)reason {
    if (status == VPSocketIOClientStatusDisconnected) {
        return;
    }
    [DefaultSocketLogger.logger log:[NSString stringWithFormat:@"Disconnected: %@", reason] type:self.logType];
    [self changeStatus:VPSocketIOClientStatusDisconnected];
    [self handleClientEvent:eventStrings[@(VPSocketClientEventDisconnect)] withData:@[reason]];
}

- (void)didError:(NSString *)reason {
    [DefaultSocketLogger.logger error:reason type:self.logType];
    [self handleClientEvent:eventStrings[@(VPSocketClientEventError)] withData:@[reason]];
}

- (void)disconnect {
    [DefaultSocketLogger.logger log:@"Closing socket" type:self.logType];
    [self leaveNamespace];
}


- (void)emit:(NSString *)event items:(NSArray *)items {
    [self emit:@[event, items] ack:-1 binary:YES isAck:false];
}


- (void)emitAck:(NSInteger)ack withItems:(NSArray *)items {
    [self emit:items ack:ack binary:YES isAck:YES];
}

- (void)emit:(NSArray *)items ack:(NSInteger)ack binary:(BOOL)binary isAck:(BOOL)isAck {
    if (self->status == VPSocketIOClientStatusConnected) {
        NSInteger aId = -1;
        if (ack>=0) {
            aId = ack;
        }
        VPSocketPacket *packet = [VPSocketPacket packetFromEmit:items id:aId nsp:nsp ack:isAck checkForBinary:binary];
        NSString* str = packet.packetString;
        [DefaultSocketLogger.logger log:[NSString stringWithFormat:@"Emitting: %@", str] type:self.logType];
        [self.manager.engine send:str withData:packet.binary];
    }else{
        [self handleClientEvent:eventStrings[@(VPSocketClientEventError)] withData:@[@"Tried emitting when not connected"]];
    }
}

- (VPSocketOnAckCallback *)emitWithAck:(NSString *)event items:(NSArray *)items {
    NSMutableArray *array = [NSMutableArray arrayWithObject:event];
    [array addObjectsFromArray:items];
    return [self createOnAck:array];
}

- (VPSocketOnAckCallback *)createOnAck:(NSArray *)items {
    currentAck += 1;
    return [[VPSocketOnAckCallback alloc]initAck:currentAck items:items socket:self binary:YES];
}

//TODO: remove onQueue parameter
- (void)handleAck:(int)ack withData:(NSArray *)data {
    if (status != VPSocketIOClientStatusConnected) {
        return;
    }
    [DefaultSocketLogger.logger log:[NSString stringWithFormat:@"Handling ack: %d with data: %@", ack, data] type:self.logType];
    [_ackHandlers executeAck:ack withItems:data];
}

- (void)handleClientEvent:(NSString *)event
                 withData:(NSArray *)data {
    [self handleEvent:event withData:data isInternalMessage:YES];
}

-(void)handleEvent:(NSString*)event
          withData:(NSArray*) data
 isInternalMessage:(BOOL)internalMessage
{
    [self handleEvent:event withData:data
    isInternalMessage:internalMessage withAck:-1];
}

- (void)handleEvent:(NSString *)event
           withData:(NSArray *)data
  isInternalMessage:(BOOL)internalMessage
            withAck:(int)ack {
    if (status == VPSocketIOClientStatusConnected || internalMessage) {
        [DefaultSocketLogger.logger log:[NSString stringWithFormat:@"Handling event: %@ with data: %@", event, data] type:self.logType];
        if (anyHandler) {
            anyHandler([[VPSocketAnyEvent alloc] initWithEvent:event andItems:data]);
        }
        for (VPSocketEventHandler *hdl in handlers) {
            if ([hdl.event isEqualToString: event]) {
                [hdl executeCallbackWith:data withAck:ack withSocket:self];
            }
        }
    }
}

- (void)handlePacket:(VPSocketPacket *)packet {
    if (![packet.nsp isEqualToString:nsp]) {
        return;
    }
    switch (packet.type) {
        case VPPacketTypeEvent:
        case VPPacketTypeBinaryEvent:
            [self handleEvent:packet.event withData:packet.args isInternalMessage:NO withAck:packet.id];
            break;
        case VPPacketTypeAck:
        case VPPacketTypeBinaryAck:
            [self handleAck:packet.id withData:packet.data];
            break;
        case VPPacketTypeConnect:
            [self didConnect:nsp];
            break;
        case VPPacketTypeDisconnect:
            [self didDisconnect:@"Got Disconnect"];
            break;
        case VPPacketTypeError:
            [self handleEvent:@"error" withData:packet.data isInternalMessage:YES withAck:packet.id];
            break;
        default:
            [DefaultSocketLogger.logger log:[NSString stringWithFormat:@"Got invalid packet: %@", packet.description]
                                       type:@"SocketParser"];
            break;
    }
}

- (void)joinNamespace {
    NSString *msg = [NSString stringWithFormat:@"Joining namespace %@", self->nsp];
    [DefaultSocketLogger.logger log:msg type:self.logType];
    [self.manager connectSocket:self];
}

- (void)leaveNamespace {
    [self.manager disconnectSocket:self];
}

- (void)off:(NSString *)event {
    [DefaultSocketLogger.logger log:[NSString stringWithFormat:@"Removing handler for event: %@", event] type:self.logType];
    NSPredicate *predicate= [NSPredicate predicateWithFormat:@"SELF.event != %@", event];
    [handlers filterUsingPredicate:predicate];
}

- (void)offWithID:(NSUUID *)UUID {
    [DefaultSocketLogger.logger log:[NSString stringWithFormat:@"Removing handler with id: %@", UUID.UUIDString] type:self.logType];
    
    NSPredicate *predicate= [NSPredicate predicateWithFormat:@"SELF.uuid != %@", UUID];
    [handlers filterUsingPredicate:predicate];
}

- (NSUUID *)on:(NSString *)event callback:(VPSocketOnEventCallback)callback {
    [DefaultSocketLogger.logger log:[NSString stringWithFormat:@"Adding handler for event: %@", event] type:self.logType];
    VPSocketEventHandler *handler = [[VPSocketEventHandler alloc] initWithEvent:event
                                                                           uuid:[NSUUID UUID]
                                                                    andCallback:callback];
    [handlers addObject:handler];
    return handler.uuid;
}

- (void)onAny:(VPSocketAnyEventHandler)handler {
    anyHandler = handler;
}

- (NSUUID *)once:(NSString *)event callback:(VPSocketOnEventCallback)callback {
    [DefaultSocketLogger.logger log:[NSString stringWithFormat:@"Adding once handler for event: %@", event] type:self.logType];
    NSUUID *uuid = [NSUUID UUID];
    __weak typeof(self) weakSelf = self;
    VPSocketEventHandler *handler = [[VPSocketEventHandler alloc] initWithEvent:event
                                                                           uuid:uuid
                                                                andCallback:^(NSArray *data, VPSocketAckEmitter *emiter) {
                                                                        __strong typeof(self) strongSelf = weakSelf;
                                                                        if(strongSelf) {
                                                                            [strongSelf offWithID:uuid];
                                                                            callback(data, emiter);
                                                                        }
                                                                    }];
    [handlers addObject:handler];
    return handler.uuid;
}

- (void)removeAllHandlers {
    [handlers removeAllObjects];
    
}

//deprecatedcall  manager's reconnect 
- (void)tryReconnect:(NSString *)reason {
}

#pragma mark - interal methods
-(void)setDefaultValues {
    [self changeStatus:VPSocketIOClientStatusNotConnected];
    nsp = @"/";
    currentAck = -1;
    self.ackHandlers = [[VPSocketAckManager alloc] init];
    handlers = [NSArray array].mutableCopy;
    
    eventStrings =@{ @(VPSocketClientEventConnect)          : kSocketEventConnect,
                     @(VPSocketClientEventDisconnect)       : kSocketEventDisconnect,
                     @(VPSocketClientEventError)            : kSocketEventError,
                     @(VPSocketClientEventPing):
                         kSocketEventPing,
                     @(VPSocketClientEventPong):
                         kSocketEventPong,
                     @(VPSocketClientEventReconnect)        : kSocketEventReconnect,
                     @(VPSocketClientEventReconnectAttempt) : kSocketEventReconnectAttempt,
                     @(VPSocketClientEventStatusChange)     : kSocketEventStatusChange};
    
    
    statusStrings = @{ @(VPSocketIOClientStatusNotConnected) : @"notconnected",
                       @(VPSocketIOClientStatusDisconnected) : @"disconnected",
                       @(VPSocketIOClientStatusConnecting) : @"connecting",
                       @(VPSocketIOClientStatusOpened) : @"opened",
                       @(VPSocketIOClientStatusConnected) : @"connected"};
}

- (void)changeStatus:(VPSocketIOClientStatus)status {
    self->status = status;
    [self handleClientEvent:@"statusChange" withData:@[@(status)]];
    
}

- (void)setReconnecting:(NSString *)reason {
    self->status = VPSocketIOClientStatusConnecting;
    [self handleClientEvent:eventStrings[@(VPSocketClientEventReconnect)] withData:@[reason]];
}

- (void)setTestable {
    [self changeStatus:VPSocketIOClientStatusConnected];
}

- (NSInteger)currentAck {
    return self->currentAck;
}

- (void)setTestStatus:(VPSocketIOClientStatus)status {
    [self changeStatus:status];
}

- (NSArray *)testHandlers {
    return handlers;
}


@end
