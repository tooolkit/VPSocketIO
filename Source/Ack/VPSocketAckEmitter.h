//
//  VPSocketAckEmitter.h
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/24.
//  Copyright © 2018年 bngj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VPSocketIOClientProtocol.h"

@interface VPSocketAckEmitter : NSObject

-(instancetype)initWithSocket:(id<VPSocketIOClientProtocol>)socket ackNum:(int)ack;
-(void)emitWith:(NSArray*) items;
-(BOOL)expcted;

@end
