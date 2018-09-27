//
//  VPSocketEngine.h
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/23.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VPSocketEngineProtocol.h"

@interface VPSocketEngine : NSObject<VPSocketEngineProtocol>

-(instancetype)initWithClient:(id<VPSocketEngineClient>)client url:(NSURL*)url options:(NSDictionary*)options;

@end
