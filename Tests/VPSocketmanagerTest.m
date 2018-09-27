//
//  VPSocketmanagerTest.m
//  VPIFMSocketIOTests
//
//  Created by yangguang on 2018/7/31.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VPSocketManager.h"
#import "VPSocketIOClient.h"

@interface TestSocket : VPSocketIOClient
@property (nonatomic, copy) NSMutableDictionary *expectations;
@property (nonatomic, copy) NSMutableDictionary *expects;

@end

@implementation TestSocket

- (NSMutableDictionary *)expects {
    if (!_expects) {
        _expects = @{}.mutableCopy;
    }
    return _expects;
}

- (NSMutableDictionary *)expectations {
    if (!_expectations) {
        _expectations = @{}.mutableCopy;
    }
    return _expectations;
}

- (void)didConnect:(NSString *)namespace {
    [self.expectations[@"didConnectCalled"] fulfill];
    self.expectations[@"didConnectCalled"] = nil;
    
    XCTestExpectation *expect = self.expects[@"didConnectCalled"];
    if ([expect isKindOfClass:[XCTestExpectation class]]) {
        [expect fulfill];
        self.expects[@"didConnectCalled"] = nil;
    }
    [super didConnect:namespace];
}

- (void)didDisconnect:(NSString *)reason {
    [self.expectations[@"didDisconnectCalled"] fulfill];
    self.expectations[@"didDisconnectCalled"] = nil;
    XCTestExpectation *expect = self.expects[@"didDisconnectCalled"];
    if ([expect isKindOfClass:[XCTestExpectation class]]) {
        [expect fulfill];
        self.expects[@"didDisconnectCalled"] = nil;
    }
    [super didDisconnect:reason];
}

- (void)emit:(NSString *)event items:(NSArray *)items {
    [self.expectations[@"emitAllEventCalled"] fulfill];
    self.expectations[@"emitAllEventCalled"] = nil;
    XCTestExpectation *expect = self.expects[@"emitAllEventCalled"];
    if ([expect isKindOfClass:[XCTestExpectation class]]) {
        [expect fulfill];
        self.expects[@"emitAllEventCalled"] = nil;
    }
}
@end


@interface TestManager : VPSocketManager

- (TestSocket *)testSocket:(NSString *)nsp;
- (void)fakeConnecting:(NSString *)nsp;
- (void)fakeDisconnecting;
- (void)fakeConnecting;

@end

@implementation TestManager

- (void)disconnect {
    [self setTestStatus:VPSocketIOClientStatusDisconnected];
}

- (TestSocket *)testSocket:(NSString *)nsp {
    return (TestSocket *)[self socketFor:nsp];
}

- (VPSocketIOClient *)socketFor:(NSString *)nsp {
    self.nsps[nsp] = [[TestSocket alloc]initWith:self namesp:nsp];
    return [super socketFor:nsp];
}

- (void)fakeConnecting:(NSString *)nsp {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *msg = [NSString stringWithFormat:@"0%@",nsp];
        [self parseEngineMessage:msg];
    });
}

- (void)fakeDisconnecting {
    [self engineDidClose:@""];
}

- (void)fakeConnecting {
    [self engineDidOpen:@""];
}

@end

@interface VPSocketmanagerTest : XCTestCase

@property (nonatomic, strong) TestManager *manager;
@property (nonatomic, strong) TestSocket *socket;
@property (nonatomic, strong) TestSocket *socket2;

@end

@implementation VPSocketmanagerTest

- (void)setUp {
    [super setUp];
    
    self.manager = [[TestManager alloc]initWithURL:[NSURL URLWithString:@"http://localhost/"] config:@{@"log":@NO}];
    self.socket = nil;
    self.socket2 = nil;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testManagerProperties {
    XCTAssertNotNil(self.manager.defaultSocket);
    XCTAssertNil(self.manager.engine);
    XCTAssertFalse(self.manager.forceNew);
//    XCTAssertEqual(self.manager.handleQueue, dispatch_queue_create("com.socketio.managerHandleQueue", DISPATCH_QUEUE_SERIAL));
    XCTAssertTrue(self.manager.reconnects);
    XCTAssertEqual(self.manager.reconnectWait, 10);
    XCTAssertEqual(self.manager.status, VPSocketIOClientStatusNotConnected);
}

- (void)testManagerCallsConnect {
    [self setUpSockets];
    self.socket.expectations[@"didConnectCalled"] = [self expectationWithDescription:@"The manager should call connect on the default socket"];
    
    self.socket2.expectations[@"didConnectCalled"] = [self expectationWithDescription:@"The manager should call connect on the socket"];
    [self.socket connect];
    [self.socket2 connect];
    [self.manager fakeConnecting];
    [self.manager fakeConnecting:@"/swift"];
    
    [self waitForExpectationsWithTimeout:0.3 handler:nil];
}

- (void)testManagerCallsDisconnect {
    [self setUpSockets];
    self.socket.expectations[@"didDisconnectCalled"] = [self expectationWithDescription:@"The manager should call disconnect on the default socket"];
    
    self.socket2.expectations[@"didDisconnectCalled"] = [self expectationWithDescription:@"The manager should call disconnect on the socket"];
    [self.socket2 on:@"connect" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        [self.manager disconnect];
        [self.manager fakeDisconnecting];
    }];
    [self.socket connect];
    [self.socket2 connect];
    [self.manager fakeConnecting];
    [self.manager fakeConnecting:@"/swift"];
    
    [self waitForExpectationsWithTimeout:0.3 handler:nil];
}

- (void)testManagerEmitAll {
    [self setUpSockets];
    self.socket.expectations[@"emitAllEventCalled"] = [self expectationWithDescription:@"The manager should emit an event to the default socket"];

    self.socket2.expectations[@"emitAllEventCalled"] = [self expectationWithDescription:@"The manager should emit an event to the socket"];
    [self.socket2 on:@"connect" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        [self.manager emitAll:@"event" withItems:@[@"testing"]];
    }];
    [self.socket connect];
    [self.socket2 connect];
    [self.manager fakeConnecting];
    [self.manager fakeConnecting:@"/swift"];

    [self waitForExpectationsWithTimeout:0.3 handler:nil];
}

// reconnectAttempts 没有开放出来?
- (void)testManagerSetsConfigs {
    dispatch_queue_t queue = dispatch_queue_create("testQueue", NULL);
    self.manager = [[TestManager alloc]initWithURL:[NSURL URLWithString:@"http://localhost/"] config:@{@"handleQueue":queue,@"forceNew":@YES,@"reconnects":@NO,@"reconnectWait":@5,@"reconnectAttempts":@5}];
    XCTAssertEqual(self.manager.handleQueue, queue);
    XCTAssertTrue(self.manager.forceNew);
    XCTAssertFalse(self.manager.reconnects);
    XCTAssertEqual(self.manager.reconnectWait, 5);
//    XCTAssertEqual(self.manager.reconnectAttempts, 5);
}

- (void)testManagerRemovesSocket {
    [self setUpSockets];
    [self.manager removeSocket:self.socket];
    XCTAssertNil(self.manager.nsps[self.socket.nsp]);
}

- (void)setUpSockets {
    self.socket = [self.manager testSocket:@"/"];
    self.socket2 = [self.manager testSocket:@"/swift"];
}

@end
