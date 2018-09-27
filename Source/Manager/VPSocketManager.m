//
//  VPSocketManager.m
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/24.
//  Copyright © 2018年 bngj. All rights reserved.
//

#import "VPSocketManager.h"
#import "VPSocketPacket.h"
#import "DefaultSocketLogger.h"
#import "VPStringReader.h"
#import "NSString+VPSocketIO.h"

@interface VPSocketManager()
{
    NSInteger currentReconnectAttempt;
    NSInteger reconnectAttempts;
    BOOL reconnecting;
}

@property (nonatomic, strong, readonly) NSString *logType;
@property (nonatomic, strong) NSMutableDictionary *config;
@property (nonatomic, strong) NSMutableArray<VPSocketPacket *> *waitingPackets;

@end

@implementation VPSocketManager

#pragma mark - properties
- (NSString *)logType {
    return @"SocketManager";
}


- (NSMutableArray<VPSocketPacket *> *)waitingPackets {
    if (!_waitingPackets) {
        _waitingPackets = @[].mutableCopy;
    }
    return _waitingPackets;
}

- (void)setConfig:(NSMutableDictionary *)config {
    if (status == VPSocketIOClientStatusConnected || status == VPSocketIOClientStatusConnecting) {
        [DefaultSocketLogger.logger log:@"Setting configs on active manager. Some configs may not be applied until reconnect" type:self.logType];
    }
    [self setConfigs:config];
}

- (VPSocketIOClient *)defaultSocket {
    return [self socketFor:@"/"];
}

- (instancetype)initWithURL:(NSURL *)socketURL
                     config:(NSMutableDictionary *)config {
    self = [super init];
    if (self) {
        [self setDefault];
        self.config = config;
        self->socketURL = socketURL;
        if ([socketURL.absoluteString hasPrefix:@"https://"]) {
            _config[@"secure"] = @(YES);
        }
        [self setConfigs:_config];
    }
    return self;
}

- (void)dealloc {
    [DefaultSocketLogger.logger log:@"Manager is being released" type:[self logType]];
    [self->engine disconnect:@"Manager Deinit"];
}

#pragma marks - methods
- (void)setConfigs:(NSMutableDictionary *)config {
    for (NSString *key in config.allKeys) {
        id value = [config valueForKey:key];
        if ([key isEqualToString:@"forceNew"]) {
            self->forceNew = [value boolValue];
        }
        if([key isEqualToString:@"handleQueue"])
        {
            self->handleQueue = value;
        }
        if([key isEqualToString:@"reconnects"])
        {
            self->reconnects = [value boolValue];
        }
        if([key isEqualToString:@"reconnectAttempts"])
        {
            self->reconnectAttempts = [value intValue];
        }
        if([key isEqualToString:@"reconnectWait"])
        {
            self->reconnectWait = abs([value intValue]);
        }
        if([key isEqualToString:@"log"])
        {
            DefaultSocketLogger.logger.log = [value boolValue];
        }
        if (DefaultSocketLogger.logger == nil) {
            [DefaultSocketLogger setLogger:[VPSocketLogger new]];
        }
    }
    _config = config.mutableCopy;
    _config[@"path"] = @"/socket.io/";

}

- (void)setDefault {
    forceNew = NO;
//    handleQueue = dispatch_get_main_queue();
    handleQueue = dispatch_queue_create("com.socketio.managerHandleQueue", DISPATCH_QUEUE_SERIAL);
    nsps = @{}.mutableCopy;
    reconnects = YES;
    reconnectWait = 10;
    status = VPSocketIOClientStatusNotConnected;
    reconnectAttempts = -1;
    currentReconnectAttempt = 0;
    reconnecting = NO;
    _config = @{}.mutableCopy;
    self.waitingPackets;//call initial
}

- (void)addEngine {
    [DefaultSocketLogger.logger log:@"Adding engine" type:self.logType];
    if (self->engine) {
        [self->engine syncResetClient];
    }
    self->engine = [[VPSocketEngine alloc]initWithClient:self url:self->socketURL options:_config];
}


#pragma mark - socket manager protocol
@synthesize defaultSocket;

@synthesize engine;

@synthesize forceNew;

@synthesize handleQueue;

@synthesize nsps;

@synthesize reconnects;

@synthesize reconnectWait;

@synthesize socketURL;

@synthesize status;

- (void)engineDidClose:(NSString *)reason {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self->handleQueue, ^{
        @autoreleasepool {
            __strong typeof(self) strongSelf = weakSelf;
            if(strongSelf) {
                [strongSelf _engineDidClose:reason];
            }
        }
    });
}

- (void)_engineDidClose:(NSString *)reason {
    [_waitingPackets removeAllObjects];
    if (self->status != VPSocketIOClientStatusDisconnected) {
        self->status = VPSocketIOClientStatusNotConnected;
    }
    if (self->status == VPSocketIOClientStatusDisconnected || !self->reconnects) {
        [self didDisconnect:reason];
    }else if(! reconnecting){
        reconnecting = YES;
        [self tryReconnect:reason];
    }
}

- (void)tryReconnect:(NSString *)reason {
    if (!reconnecting) {
        return;
    }
    [DefaultSocketLogger.logger log:@"Starting reconnect" type:self.logType];
    for (VPSocketIOClient *socket in self->nsps.allValues) {
        if (socket.status == VPSocketIOClientStatusConnected) {
        }else{
            continue;
        }
        [socket setReconnecting:reason];
    }
    [self _tryReconnect];
}

- (void)_tryReconnect {
    if (!(reconnects && reconnecting && status != VPSocketIOClientStatusDisconnected)) {
        return;
    }
    if (reconnectAttempts != -1 && currentReconnectAttempt + 1 > reconnectAttempts) {
        return [self didDisconnect:@"Reconnect Failed"];
    }
    
    [DefaultSocketLogger.logger log:@"Trying to reconnect" type:self.logType];
    //TODO: eventString[reconnectAttempt] 需要提出来可以使用
    [self emitAllClient:@"reconnectAttempt" withData:@[@(reconnectAttempts - currentReconnectAttempt)]];
    currentReconnectAttempt += 1;
    [self connect];
    [self setTimer];
}

- (void)setTimer {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self->reconnectWait * NSEC_PER_SEC)), self->handleQueue, ^{
        @autoreleasepool {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf _tryReconnect];
        }
    });
}

- (void)engineDidError:(NSString *)reason {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self->handleQueue, ^{
        @autoreleasepool {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf _engineDidError:reason];
        }
    });
}

- (void)_engineDidError:(NSString *)reason {
    [DefaultSocketLogger.logger error:reason type:self.logType];
    //TODO VPSocketClientEventError string 提取出来
    [self emitAllClient:@"error" withData:@[reason]];
}

- (void)engineDidOpen:(NSString *)reason {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self->handleQueue, ^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf _engineDidOpen:reason];
    });
}

- (void)_engineDidOpen:(NSString *)reason {
    NSString *msg = [NSString stringWithFormat:@"Engine opened %@", reason];
    [DefaultSocketLogger.logger log:msg type:self.logType];
    self->status = VPSocketIOClientStatusConnected;
    //just hack for didSet
    self->reconnecting = NO;
    self->currentReconnectAttempt = 0;
    
    [self->nsps[@"/"] didConnect:@"/"];
    
    for (NSString *key in self->nsps.allKeys) {
        VPSocketIOClient *socket = self->nsps[key];
        if ((![key isEqualToString:@"/"] && socket.status == VPSocketIOClientStatusConnecting)) {
            [self connectSocket:socket];
        }
    }
}

- (void)engineDidReceivePong {
    dispatch_async(self->handleQueue, ^{
        [self _engineDidReceivePong];
    });
}

- (void)_engineDidReceivePong {
    //TODO:
    [self emitAllClient:@"pong" withData:@[]];
}

- (void)engineDidSendPing {
    dispatch_async(self->handleQueue, ^{
        [self _engineDidSendPing];
    });
}

- (void)_engineDidSendPing {
    //TODO:
    [self emitAllClient:@"ping" withData:@[]];
}

- (void)parseEngineBinaryData:(NSData *)data {
    dispatch_async(self->handleQueue, ^{
        [self _parseEngineBinaryData:data];
    });
}

- (void)_parseEngineBinaryData:(NSData *)data {
    VPSocketPacket *packet = [self parseBinaryData:data];
    if (!packet) {
        return;
    }else{
        [self->nsps[packet.nsp] handlePacket:packet];
    }
}

- (VPSocketPacket *)parseBinaryData:(NSData *)data {
    if (_waitingPackets.count == 0) {
        [DefaultSocketLogger.logger error:@"Got data when not remaking packet"
                                     type:@"SocketParser"];
        return nil;
    }
    VPSocketPacket *lastPacket = _waitingPackets.lastObject;
    BOOL success = [lastPacket addData:data];
    if (!success) {
        return nil;
    }
    [_waitingPackets removeLastObject];
    return lastPacket;
}

- (void)parseEngineMessage:(NSString *)msg {
    [DefaultSocketLogger.logger log:[NSString stringWithFormat:@"Should parse message: %@", msg] type:self.logType];
    __weak typeof(self) weakSelf = self;
    dispatch_async(self->handleQueue, ^{
        @autoreleasepool{
            __strong typeof(self) strongSelf = weakSelf;
            if(strongSelf) {
                [strongSelf _parseEngineMessage:msg];
            }
        }
    });
}

- (void)_parseEngineMessage:(NSString *)msg {
    VPSocketPacket *packet = [self parseSocketMessage:msg];
    if (!packet) {
        return;
    }
    if (packet.type != VPPacketTypeBinaryAck && packet.type != VPPacketTypeBinaryEvent) {
        [self->nsps[packet.nsp] handlePacket:packet];
    }else{
        [_waitingPackets addObject:packet];
        return;
    }
}

- (VPSocketPacket *)parseSocketMessage:(NSString *)msg {
    if (msg.length == 0) {
        return nil;
    }

    [DefaultSocketLogger.logger log:[NSString stringWithFormat:@"Parsing %@", msg] type:@"SocketParser"];
    
    VPSocketPacket *packet = [self parseString:msg];
    if (packet) {
        [DefaultSocketLogger.logger log:[NSString stringWithFormat:@"Decoded packet as: %@", packet.description] type:@"SocketParser"];
        return packet;
    }else{
        [DefaultSocketLogger.logger error:@"invalidPacketType" type: @"SocketParser"];
        return nil;
    }
}

- (VPSocketPacket *)parseString:(NSString *)message {
    NSCharacterSet* digits = [NSCharacterSet decimalDigitCharacterSet];
    VPStringReader *reader = [[VPStringReader alloc] init:message];
    NSInteger packetType = [[reader read:1] integerValue];
    if (packetType > VPPacketTypeBinaryAck || packetType < VPPacketTypeConnect) {// ivalide type
        NSLog(@"invalid packet type %ld", packetType);
        return nil;
    }
    if (![reader hasNext]) {
        return [[VPSocketPacket alloc] init:packetType nsp:@"/" placeholders:0];
    }
    NSString *namespace = @"/";
    NSInteger placeholders = -1;
    if (packetType == VPPacketTypeBinaryAck || packetType == VPPacketTypeBinaryEvent) {
        NSString *value = [reader readUntilOccurence:@"-"];
        if ([value rangeOfCharacterFromSet:digits].location == NSNotFound){
            NSLog(@"invalid packet %@", message);
            return nil;
        }else{
            placeholders = [value intValue];
        }
    }

    if ([reader.currentCharacter isEqualToString:@"/"]) {
        namespace = [reader readUntilOccurence:@","];
    }
    if (![reader hasNext]) {
        return [[VPSocketPacket alloc] init:packetType nsp:namespace placeholders:placeholders];
    }

    NSMutableString *idString = @"".mutableCopy;
    if (packetType == VPPacketTypeError) {
        [reader advance:-1];
    }else{
        while ([reader hasNext]) {
            NSString *value = [reader read:1];
            if ([value rangeOfCharacterFromSet:digits].location == NSNotFound) {
                [reader advance:-2];
                break;
                
            }else{
                [idString appendString:value];
            }
        }
    }
    NSString *dataArray = [message substringFromIndex:reader.currentIndex+1];
    if (packetType == VPPacketTypeError && ![dataArray hasPrefix:@"["] && ![dataArray hasSuffix:@"]"]) {
        dataArray =  [NSString stringWithFormat:@"[%@]", dataArray];
    }
    NSArray *data = [dataArray toArray];
    int idValue = -1;
    if(idString.length > 0)
    {
        idValue = [idString intValue];
    }
    return [[VPSocketPacket alloc]init:packetType data:data id:idValue nsp:namespace placeholders:placeholders binary:@[]];
    
    
    
    
//    NSString *packetType = [reader read:1];
//    if ([packetType rangeOfCharacterFromSet:digits].location != NSNotFound) {
//        VPPacketType type = [packetType integerValue];
//        if (![reader hasNext]) {
//            return [[VPSocketPacket alloc]init:type nsp:@"/" placeholders:0];
//        }
//        NSString *namespace = @"/";
//        int placeholders = -1;
//
//        if (type == VPPacketTypeBinaryAck || type == VPPacketTypeBinaryEvent) {
//            NSString *value = [reader readUntilOccurence:@"-"];
//            if ([value rangeOfCharacterFromSet:digits].location == NSNotFound) {
//                return nil;
//            }
//            else {
//                placeholders = [value intValue];
//            }
//        }
//        NSString *charStr = [reader currentCharacter];
//        if([charStr isEqualToString:namespace]) {
//            namespace = [reader readUntilOccurence:@","];
//        }
//        if(![reader hasNext]) {
//            return [[VPSocketPacket alloc] init:type nsp:namespace placeholders:placeholders];
//        }
//        NSMutableString *idString = [NSMutableString string];
//        if(type == VPPacketTypeError) {
//            [reader advance:-1];
//        }else{
//            while ([reader hasNext]) {
//                NSString *value = [reader read:1];
//                if ([value rangeOfCharacterFromSet:digits].location == NSNotFound) {
//                    [reader advance:-2];
//                    break;
//                }
//                else {
//                    [idString appendString:value];
//                }
//            }
//        }
//        NSString *dataArray = [message substringFromIndex:reader.currentIndex+1];
//        if (type == VPPacketTypeError && ![dataArray hasPrefix:@"["] && ![dataArray hasSuffix:@"]"]){
//            dataArray =  [NSString stringWithFormat:@"[%@]", dataArray];
//        }
//        NSArray *data = [dataArray toArray];
//        if(data.count > 0) {
//            int idValue = -1;
//            if(idString.length > 0)
//            {
//                idValue = [idString intValue];
//            }
//            return [[VPSocketPacket alloc] init:type
//                                           data:data
//                                             id:idValue
//                                            nsp:namespace
//                                   placeholders:placeholders
//                                         binary:[NSArray array]];
//        }
//    }
//    return nil;
}

- (void)connect {
    if (self->status == VPSocketIOClientStatusConnected
        || self->status == VPSocketIOClientStatusConnecting) {
        [DefaultSocketLogger.logger log:@"Tried connecting an already active socket" type:self.logType];
        return;
    }
    if (!self->engine || self->forceNew) {
        [self addEngine];
    }
    self->status = VPSocketIOClientStatusConnecting;
    [self->engine connect];
}

- (void)connectSocket:(VPSocketIOClient *)socket {
    if (self->status == VPSocketIOClientStatusConnected) {
        NSString *msg = [NSString stringWithFormat:@"0%@",socket.nsp];
        [self->engine send:msg withData:@[]];
    }else{
        [DefaultSocketLogger.logger log:@"Tried connecting socket when engine isn't open. Connecting" type:self.logType];
        [self connect];
        return;
    }
    
}

- (void)didDisconnect:(NSString *)reason {
    for (VPSocketIOClient *socket in self->nsps.allValues) {
        [socket didDisconnect:reason];
    }
}

- (void)disconnect {
    [DefaultSocketLogger.logger log:@"Closing socket" type:self.logType];
    self->status = VPSocketIOClientStatusDisconnected;
    [self->engine disconnect:@"Disconnect"];
}

- (void)disconnectSocket:(VPSocketIOClient *)socket {
    NSString *msg = [NSString stringWithFormat:@"1%@",socket.nsp];
    [self->engine send:msg withData:@[]];
    [socket didDisconnect:@"Namespace leave"];
}

- (void)disconnectSocketFor:(NSString *)nsp {
    //TODO:
    VPSocketIOClient *socket = nil;
    NSString *sKey = @"";
    for (NSString *key in nsps.allKeys) {
        if ([key isEqualToString:nsp]) {
            socket = nsps[key];
            sKey = key;
        }
    }
    if ([sKey isEqualToString:@""]) {
        [DefaultSocketLogger.logger log:@"Could not find socket for \(nsp) to disconnect" type:self.logType];
        return;
    }
    self->nsps[sKey] = nil;
    [self disconnectSocket:socket];
}

- (void)emitAllClient:(NSString *)event withData:(NSArray *)data {
    for (VPSocketIOClient *socket in self->nsps.allValues) {
        [socket handleClientEvent:event withData:data];
    }
}

- (void)emitAll:(NSString *)event withItems:(NSArray *)items {
    for (VPSocketIOClient *socket in self->nsps.allValues) {
        [socket emit:event items:items];
    }
}

- (void)reconnect {
    if (!self->reconnecting) {
        [self.engine disconnect:@"manual reconnect"];
    }else{
        return;
    }
}

- (VPSocketIOClient *)removeSocket:(VPSocketIOClient *)socket {
    VPSocketIOClient *skt = [self.nsps objectForKey:socket.nsp];
    [self.nsps removeObjectForKey:socket.nsp];
    return skt;
}

- (VPSocketIOClient *)socketFor:(NSString *)nsp {
    NSAssert([nsp hasPrefix:@"/"], @"forNamespace must have a leading /");
    VPSocketIOClient *client = nsps[nsp];
    if (client) {
        return client;
    }
    client = [[VPSocketIOClient alloc] initWith:self namesp:nsp];
    nsps[nsp] = client;
    return client;
}

#pragma mark - out properties methods
- (VPSocketIOClientStatus)status {
    return status;
}

- (void)setTestStatus:(VPSocketIOClientStatus)status {
    self->status = status;
}


@end
