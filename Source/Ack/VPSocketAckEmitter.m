//
//  VPSocketAckEmitter.m
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/24.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import "VPSocketAckEmitter.h"

@interface VPSocketAckEmitter()
@property (nonatomic, strong) id<VPSocketIOClientProtocol> socket;
@property(nonatomic) int ackNum;

@end

@implementation VPSocketAckEmitter

- (instancetype)initWithSocket:(id<VPSocketIOClientProtocol>)socket ackNum:(int)ack {
    self = [super init];
    if (self) {
        self.socket = socket;
        self.ackNum = ack;
    }
    return self;
}

-(BOOL)expcted {
    return _ackNum != -1;
}

- (void)emitWith:(NSArray *)items {
    if (_ackNum != -1) {
        [_socket emitAck:_ackNum withItems:items];
    }
}


@end
