//
//  VPSocketAckManagerTest.m
//  VPIFMSocketIOTests
//
//  Created by yangguang on 2018/7/30.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VPSocketAckManager.h"

@interface VPSocketAckManagerTest : XCTestCase

@property (nonatomic, strong) VPSocketAckManager *ackManager;

@end

@implementation VPSocketAckManagerTest

- (void)setUp {
    [super setUp];
    self.ackManager = [[VPSocketAckManager alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testAddAcks {
    XCTestExpectation *callbackExpection = [self expectationWithDescription:@"callbackExpection"];
    NSArray *itemsArray = @[@"Hi", @"ho"];
    
    VPScoketAckArrayCallback callback = ^(NSArray *array) {
        [callbackExpection fulfill];
    };
    [self.ackManager addAck:1 callback:callback];
    [self.ackManager executeAck:1 withItems:itemsArray];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
    
}

- (void) testManagerTimeoutAck {
    XCTestExpectation *callbackExpection = [self expectationWithDescription:@"callbackExpection"];
    NSArray *itemsArray = @[@"Hi", @"ho"];
    VPScoketAckArrayCallback callback = ^(NSArray *items) {
        XCTAssertEqual(items.count, 1, @"Timed out ack should have one value");
        NSString *timeoutReason = items[0];
        if (![timeoutReason isKindOfClass:[NSString class]]) {
            XCTFail(@"Timeout reason should be a string");
            return;
        }
        XCTAssertEqualObjects(timeoutReason, @"NO ACK");
        [callbackExpection fulfill];
    };
    [self.ackManager addAck:1 callback:callback];
    [self.ackManager timeoutAck:1];
    [self waitForExpectationsWithTimeout:0.2 handler:nil];
}

@end
