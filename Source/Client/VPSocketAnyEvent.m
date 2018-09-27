//
//  VPSocketAnyEvent.m
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/24.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import "VPSocketAnyEvent.h"
#import "VPSocketAckEmitter.h"

@implementation VPSocketAnyEvent

-(NSString *)description {
    return [NSString stringWithFormat:@"VPSocketAnyEvent: Event: %d items: %@", (int)_event, _items.description];
}

- (instancetype)initWithEvent:(NSString *)event andItems:(NSArray *)items {
    self = [super init];
    if (self) {
        _event = event;
        _items = items;
    }
    return self;
}

@end

@implementation VPSocketEventHandler : NSObject

- (instancetype)initWithEvent:(NSString *)event uuid:(NSUUID *)uuid andCallback:(VPSocketOnEventCallback)callback {
    self = [super init];
    if (self) {
        _event = event;
        _uuid = uuid;
        _callback = callback;
    }
    return self;
}

-(void)executeCallbackWith:(NSArray *)items withAck:(int)ack withSocket:(id<VPSocketIOClientProtocol>)socket {
    self.callback(items, [[VPSocketAckEmitter alloc] initWithSocket:socket ackNum:ack]);
}

@end
