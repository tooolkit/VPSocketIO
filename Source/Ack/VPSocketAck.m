//
//  VPSocketAck.m
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/24.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import "VPSocketAck.h"

@implementation VPSocketAck

-(instancetype)initWithAck:(int)ack andCallBack:(VPScoketAckArrayCallback)callback
{
    self = [super init];
    if(self) {
        _ack = ack;
        _callback = callback;
    }
    return self;
}


- (NSUInteger)hash
{
    return _ack & 0x0F;
}

@end
