//
//  VPSocketOnAckCallback.m
//  VPSocketIO
//
//  Created by Vasily Popov on 9/26/17.
//  Copyright © 2017 Vasily Popov. All rights reserved.
//

#import "VPSocketOnAckCallback.h"
#import "VPSocketAckManager.h"
#import "VPSocketIOClient.h"
#import "VPSocketManager.h"

@interface VPSocketOnAckCallback()

@property (nonatomic, weak) VPSocketIOClient *socket;
@property (nonatomic, strong) NSArray* items;
@property (nonatomic) int ackNum;
@property (nonatomic) BOOL binary;

@end

@implementation VPSocketOnAckCallback

-(instancetype)initAck:(int)ack items:(NSArray*)items socket:(id<VPSocketIOClientProtocol>)socket binary:(BOOL)binary
{
    self = [super init];
    if(self) {
        _socket = socket;
        self.ackNum = ack;
        self.items = items;
        self.binary = binary;
    }
    return self;
}


-(void)timingOutAfter:(double)seconds callback:(VPScoketAckArrayCallback)callback {
    
    if (self.socket != nil && _ackNum != -1) {
        
        [self.socket.ackHandlers addAck:_ackNum callback:callback];
        [self.socket emit:_items ack:_ackNum binary:self.binary isAck:NO];
        if(seconds >0 ) {
            
            __weak typeof(self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), self.socket.manager.handleQueue, ^
            {
                @autoreleasepool
                {
                    __strong typeof(self) strongSelf = weakSelf;
                    if(strongSelf) {
                        [strongSelf.socket.ackHandlers timeoutAck:strongSelf.ackNum];
                    }
                }
            });
        }
    }
}

@end
