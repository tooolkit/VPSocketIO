//
//  VPSocketOnAckCallback.h
//  VPSocketIO
//
//  Created by Vasily Popov on 9/26/17.
//  Copyright © 2017 Vasily Popov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VPSocketIOClientProtocol.h"

@interface VPSocketOnAckCallback : NSObject

//binary default YES
-(instancetype)initAck:(int)ack items:(NSArray*)items socket:(id<VPSocketIOClientProtocol>)socket binary:(BOOL)binary;
-(void)timingOutAfter:(double)seconds callback:(VPScoketAckArrayCallback)callback;

@end
