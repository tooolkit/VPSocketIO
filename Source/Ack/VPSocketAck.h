//
//  VPSocketAck.h
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/24.
//  Copyright © 2018年 bngj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VPSocketIOClientProtocol.h"

@interface VPSocketAck : NSObject

@property (nonatomic, readonly) NSInteger ack;
@property (nonatomic, strong, readonly) VPScoketAckArrayCallback callback;

-(instancetype)initWithAck:(int)ack andCallBack:(VPScoketAckArrayCallback)callback;
@end
