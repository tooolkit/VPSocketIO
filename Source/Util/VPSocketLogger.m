//
//  BISocketLogger.m
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/23.
//  Copyright © 2018年 bngj. All rights reserved.
//

#import "VPSocketLogger.h"

@implementation VPSocketLogger

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.log = NO;
    }
    return self;
}

-(void) log:(NSString*)message type:(NSString*)type
{
    [self printLog:@"LOG" message:message type:type];
}
-(void) error:(NSString*)message type:(NSString*)type
{
    [self printLog:@"ERROR" message:message type:type];
}

-(void) printLog:(NSString*)logType message:(NSString*)message type:(NSString*)type
{
    if(_log) {
        NSLog(@"%@ %@: %@", logType, type, message);
    }
    
}

-(void)dealloc {
    
}

@end
