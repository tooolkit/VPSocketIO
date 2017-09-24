//
//  VPSocketStremReader.m
//  VPSocketIO
//
//  Created by Vasily Popov on 9/23/17.
//  Copyright © 2017 Vasily Popov. All rights reserved.
//

#import "VPSocketStreamReader.h"

@interface VPSocketStreamReader()

@end

@implementation VPSocketStreamReader

-(instancetype)init:(NSString*)message {
    self = [super init];
    if(self) {
        self.message = message;
        _currentIndex = 0;
    }
    return self;
}

-(BOOL)hasNext {
    return _currentIndex < _message.length -1;
}

-(NSString*)currentCharacter {
    unichar character =  [_message characterAtIndex:_currentIndex];
    
    return [[NSString alloc] initWithBytes:&character length:sizeof(unichar) encoding:NSUTF8StringEncoding];
    
}

-(int)advance:(int)offset
{
    _currentIndex += offset;
    return _currentIndex;
}

-(NSString*)read:(int)count {
    
    if(_currentIndex + count < _message.length) {
        NSString *readString = [_message substringWithRange: NSMakeRange(_currentIndex, count)];
        [self advance:count];
        return readString;
    }
    else {
        return [self readUntilEnd];
    }
}

-(NSString*)readUntilOccurence:(NSString*)string {
    
    NSString *readString = [_message substringFromIndex:_currentIndex];
    NSUInteger loc = [readString rangeOfString:string].location;
    if(loc == NSNotFound) {
        return [self readUntilEnd];
    }
    else {
        NSString *resultString = [readString substringToIndex:loc];
        [self advance:(int)resultString.length + 1];
        return resultString;
    }
}

-(NSString*)readUntilEnd
{
    NSString *resultString =[_message substringFromIndex:_currentIndex];
    _currentIndex = (int)_message.length - 1;
    return resultString;
}

@end

