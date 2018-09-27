//
//  VPSocketAckManager.h
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/24.
//  Copyright © 2018年 bngj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VPSocketIOClientProtocol.h"

@interface VPSocketAckManager : NSObject

-(void)addAck:(int)ack callback:(VPScoketAckArrayCallback)callback;
-(void)executeAck:(int)ack withItems:(NSArray*)items;
-(void)timeoutAck:(int)ack;

@end
