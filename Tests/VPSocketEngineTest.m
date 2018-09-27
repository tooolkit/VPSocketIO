//
//  VPSocketEngineTest.m
//  VPIFMSocketIOTests
//
//  Created by yangguang on 2018/8/1.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VPSocketManager.h"
#import "VPSocketIOClient.h"
#import "VPSocketEngine.h"
#import "VPSocketEngine+EnginePollable.h"
#import "VPSocketEngine+Private.h"

@interface VPSocketEngineTest : XCTestCase

@property (nonatomic, strong) VPSocketManager *manager;
@property (nonatomic, strong) VPSocketIOClient *socket;
@property (nonatomic, strong) VPSocketEngine *engine;

@end

@implementation VPSocketEngineTest

- (void)setUp {
    [super setUp];
    
    self.manager = [[VPSocketManager alloc]initWithURL:[NSURL URLWithString:@"http://localhost"] config:nil];
    self.socket = [self.manager defaultSocket];
    self.engine = [[VPSocketEngine alloc]initWithClient:self.manager url:[NSURL URLWithString:@"http://localhost"] options:nil];
    [self.socket setTestable];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testBasicPollingMessage {
    XCTestExpectation *expect = [self expectationWithDescription:@"Basic polling test"];
    [self.socket on:@"blankTest" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        [expect fulfill];
    }];
    [self.engine parsePollingMessage:@"15:42[\"blankTest\"]"];
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testTwoPacketsInOnePollTest{
    XCTestExpectation *finalExpectation = [self expectationWithDescription:@"Final packet in poll test"];
    __block BOOL gotBlank = false;
    [self.socket on:@"blankTest" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        gotBlank = YES;
    }];
    [self.socket on:@"stringTest" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        NSString *str = array[0];
        if ([str isKindOfClass:[NSString class]] && gotBlank) {
            if ([str isEqualToString:@"hello"]) {
                [finalExpectation fulfill];
            }
        }
    }];
    [self.engine parsePollingMessage:@"15:42[\"blankTest\"]24:42[\"stringTest\",\"hello\"]"];
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testEngineDoesErrorOnUnknownTransport {
    XCTestExpectation *finalExpectation = [self expectationWithDescription:@"Unknown Transport"];
    [self.socket on:@"error" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        NSString *error = array[0];
        if ([error isKindOfClass:[NSString class]] && [error isEqualToString:@"Unknown transport"]) {
            [finalExpectation fulfill];
        }
    }];
    [self.engine parsePollingMessage:@"{\"code\": 0, \"message\": \"Unknown transport\"}"];
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testEngineDoesErrorOnUnknownMessage {
    XCTestExpectation *finalExpectation = [self expectationWithDescription:@"Engine Errors"];
    [self.socket on:@"error" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        [finalExpectation fulfill];
    }];
    [self.engine parsePollingMessage:@"afafafda"];
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testEngineDecodesUTF8Properly {
    XCTestExpectation *expect = [self expectationWithDescription:@"Engine Decodes utf8"];
    [self.socket on:@"stringTest" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        NSString *str = array[0];
        XCTAssertEqualObjects(str, @"lïne one\nlīne \rtwo𦅙𦅛");
        [expect fulfill];
    }];
    
    NSString *stringMessage = @"42[\"stringTest\",\"lïne one\\nlīne \\rtwo𦅙𦅛\"]";
    NSString *str = [NSString stringWithFormat:@"%lu:%@",(unsigned long)stringMessage.length, stringMessage];
    [self.engine parsePollingMessage:str];
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

//TODO:
//- (void)testEncodeURLProperly {
//    self.engine setConnect
//}

- (void)testBase64Data {
    XCTestExpectation *expect = [self expectationWithDescription:@"Engine Decodes base64 data"];
    NSString *b64String = @"b4aGVsbG8NCg==";
    NSString *packetString = @"451-[\"test\",{\"test\":{\"_placeholder\":true,\"num\":0}}]";
    [self.socket on:@"test" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        NSData *data = array[0];
        if ([data isKindOfClass:[NSData class]]) {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            XCTAssertEqualObjects(string, @"hello");
        }
        [expect fulfill];
    }];
    [self.engine parseEngineMessage:packetString];
    [self.engine parseEngineMessage:b64String];
    
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

//TODO:
//- (void)testSettingExtraHeadersBeforeConnectSetsEngineExtraHeaders {
//    NSDictionary *newValue = @{@"hello":@"world"};
//    self.manager.engine = self.engine;
//    [self.manager setTestStatus:VPSocketIOClientStatusNotConnected];
//    self.manager.
//}

//TODO
- (void)testSettingExtraHeadersAfterConnectDoesNotIgnoreChanges {
    
}
//TODO
- (void)testSettingPathAfterConnectDoesNotIgnoreChanges{
    
}

//TODO
- (void)testSettingCompressAfterConnectDoesNotIgnoreChanges{
    
}
//TODO
- (void)testSettingForcePollingAfterConnectDoesNotIgnoreChanges {
    
}
//TODO
- (void)testSettingForceWebSocketsAfterConnectDoesNotIgnoreChanges {
    
}
//TODO
- (void)testChangingEngineHeadersAfterInit {
    
}


@end
