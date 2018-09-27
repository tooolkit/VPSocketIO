//
//  VPSocketSideEffectTest.m
//  VPIFMSocketIOTests
//
//  Created by yangguang on 2018/7/31.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VPSocketIOClient.h"
#import "VPSocketManager.h"
#import "VPSocketOnAckCallback.h"
#import "JFRWebSocket.h"

@interface TestEngine:NSObject<VPSocketEngineProtocol>

@property (nonatomic) BOOL closed;
@property (nonatomic) BOOL compress;
@property (nonatomic) BOOL connected;
@property (nonatomic, strong) NSMutableDictionary *connectParams;
@property (nonatomic, strong) NSMutableArray<NSHTTPCookie*>* cookies;
@property (nonatomic, strong) dispatch_queue_t engineQueue;
@property (nonatomic, strong) NSMutableDictionary*extraHeaders;
@property (nonatomic) BOOL fastUpgrade;
@property (nonatomic) BOOL forcePolling;
@property (nonatomic) BOOL forceWebsockets;
@property (nonatomic) BOOL polling;
@property (nonatomic) BOOL probing;
@property (nonatomic, strong) NSString *sid;
@property (nonatomic, strong) NSString *socketPath;
@property (nonatomic, strong) NSURL *urlPolling;
@property (nonatomic, strong) NSURL *urlWebSocket;
@property (nonatomic) BOOL websocket;
@property (nonatomic, strong) JFRWebSocket *ws;

@end

@implementation TestEngine

@synthesize client;

@synthesize closed;

@synthesize connected;

- (instancetype)initWithClient:(id<VPSocketEngineClient>)client url:(NSURL *)url options:(NSDictionary *)options {
    self = [super init];
    if (self) {
        [self setup];
        self.client = client;
    }
    return self;
}

- (void)setup {
    self->closed = false;
    self.compress = false;
    self.connected = false;
    self.connectParams = nil;
    self.cookies = nil;
    self.engineQueue = dispatch_queue_create("com.socketio.engineHandleQueue.test", NULL);
    self.extraHeaders = nil;
    self.fastUpgrade = false;
    self.forcePolling = false;
    self.polling = false;
    self.forceWebsockets = false;
    self.probing = false;
    self.sid = @"";
    self.socketPath = @"";
    self.urlPolling = [NSURL URLWithString:@"http://localhost/"];
    self.urlWebSocket = [NSURL URLWithString:@"http://localhost/"];
    self.websocket = false;
    self.ws = nil;
}

- (void)connect {
    [self.client engineDidOpen:@"Connect"];
}

- (void)disconnect:(NSString *)reason {
    
}

- (void)send:(NSString *)msg withData:(NSArray<NSData *> *)data {
    
}

- (void)syncResetClient {
    
}

@end



@interface VPSocketSideEffectTest : XCTestCase

@property (nonatomic, strong) VPSocketManager *manager;
@property (nonatomic, strong) VPSocketIOClient *socket;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSData *data2;
@property (nonatomic, assign) NSInteger currentAck;
@property (nonatomic, copy) NSString *logType;
@property (nonatomic, copy) NSString *nsp;

@end

@implementation VPSocketSideEffectTest

- (void)setUp {
    [super setUp];
    self.manager = [[VPSocketManager alloc]initWithURL:[NSURL URLWithString:@"http://localhost/"] config:@{@"log":@false}];
    self.socket = self.manager.defaultSocket;
    [self.socket setTestable];
    self.data = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    self.data2 = [@"test2" dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testInitialCurrentAck {
    XCTAssertEqual(self.socket.currentAck, -1);
}

- (void)testFirstAck {
    [[self.socket emitWithAck:@"test" items:@[]] timingOutAfter:0 callback:^(NSArray *array) {
    }];
    XCTAssertEqual(self.socket.currentAck, 0);
}

- (void)testSecondAck {
    [[self.socket emitWithAck:@"test" items:@[]] timingOutAfter:0 callback:^(NSArray *array) {
    }];
    [[self.socket emitWithAck:@"test" items:@[]] timingOutAfter:0 callback:^(NSArray *array) {
    }];
    XCTAssertEqual(self.socket.currentAck, 1);
}

- (void)testhandleAck {
    XCTestExpectation *expect = [self expectationWithDescription:@"handled ack"];
    [[self.socket emitWithAck:@"test" items: nil] timingOutAfter:0 callback:^(NSArray *array) {
        XCTAssertEqualObjects(array[0], @"hello world");
        [expect fulfill];
    }];
    [self.manager parseEngineMessage:@"30[\"hello world\"]"];
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testHandleAckWithAckEmit {
    XCTestExpectation *expect = [self expectationWithDescription:@"handled ack"];
    [[self.socket emitWithAck:@"test" items: nil] timingOutAfter:0 callback:^(NSArray *array) {
        XCTAssertEqualObjects(array[0], @"hello world");
        [[self.socket emitWithAck:@"test" items:nil] timingOutAfter:0 callback:^(NSArray *array) {
            
        }];
        [expect fulfill];
    }];
    [self.manager parseEngineMessage:@"30[\"hello world\"]"];
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testHandleAck2 {
    XCTestExpectation *expect = [self expectationWithDescription:@"handled ack2"];
    [[self.socket emitWithAck:@"test" items: nil] timingOutAfter:0 callback:^(NSArray *array) {
        XCTAssertTrue(array.count == 2);
        [expect fulfill];
    }];
    [self.manager parseEngineMessage:@"61-0[{\"_placeholder\":true,\"num\":0},{\"test\":true}]"];
    
    [self.manager parseEngineBinaryData:self.data];
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testhandleEvent {
    XCTestExpectation *expect = [self expectationWithDescription:@"handled event"];
    [self.socket on:@"test" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        XCTAssertEqualObjects(array[0], @"hello world");
        [expect fulfill];
    }];
    [self.manager parseEngineMessage:@"2[\"test\",\"hello world\"]"];
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
}

- (void)testHandleStringEventWithQutoes {
    XCTestExpectation *expect = [self expectationWithDescription:@"handled event"];
    [self.socket on:@"test" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        XCTAssertEqualObjects(array[0], @"\"hello world\"");
        [expect fulfill];
    }];
    [self.manager parseEngineMessage:@"2[\"test\",\"\\\"hello world\\\"\"]"];
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testHandleOnceEvent {
    XCTestExpectation *expect = [self expectationWithDescription:@"handled event"];
    [self.socket once:@"test" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        XCTAssertEqualObjects(array[0], @"hello world");
        XCTAssertEqual([self.socket testHandlers].count, 0);
        [expect fulfill];
    }];
    [self.manager parseEngineMessage:@"2[\"test\",\"hello world\"]"];
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testHandleOnceClientEvent {
    XCTestExpectation *expect = [self expectationWithDescription:@"handled event"];
    [self.socket setTestStatus:VPSocketIOClientStatusConnecting];
    [self.socket once:@"connect" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        XCTAssertEqual([self.socket testHandlers].count, 0);
        [expect fulfill];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.manager parseEngineMessage:@"0/"];
    });
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testOffWithEvent {
    [self.socket on:@"test" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        
    }];
    [self.socket on:@"test" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        
    }];
    XCTAssertEqual(self.socket.testHandlers.count, 2);
    [self.socket off:@"test"];
    XCTAssertEqual(self.socket.testHandlers.count, 0);
}

- (void)testOffClientEvent {
    [self.socket on:@"connect" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        
    }];
    [self.socket on:@"disconnect" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        
    }];
    XCTAssertEqual(self.socket.testHandlers.count, 2);
    [self.socket off:@"disconnect"];
    XCTAssertEqual(self.socket.testHandlers.count, 1);
    BOOL hasConnectHandle = NO;
    for (VPSocketEventHandler *h in self.socket.testHandlers) {
        if ([h.event isEqualToString:@"connect"]) {
            hasConnectHandle = YES;
        }
    }
    XCTAssertTrue(hasConnectHandle);
}

- (void)testOffWithId {
    NSUUID *uid = [self.socket on:@"test" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        
    }];
    XCTAssertEqual(self.socket.testHandlers.count, 1);
    [self.socket on:@"test" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        
    }];
    XCTAssertEqual(self.socket.testHandlers.count, 2);
    [self.socket offWithID:uid];
    XCTAssertEqual(self.socket.testHandlers.count, 1);
}

- (void)testHandlesErrorPacket {
    XCTestExpectation *expect = [self expectationWithDescription:@"Handled error"];
    [self.socket on:@"error" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        NSString *error = array[0];
        if ([error isEqualToString:@"test error"]) {
            [expect fulfill];
        }
    }];
    [self.manager parseEngineMessage:@"4\"test error\""];
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testHandleBinaryEvent{
    XCTestExpectation *expect = [self expectationWithDescription:@"handled binary event"];
    [self.socket on:@"test" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        NSDictionary *dict = array[0];
        NSData *data = dict[@"test"];
        if ([data isKindOfClass:[NSData class]]) {
            XCTAssertEqual(data, self.data);
            [expect fulfill];
        }
    }];
    [self.manager parseEngineMessage:@"51-[\"test\",{\"test\":{\"_placeholder\":true,\"num\":0}}]"];
    [self.manager parseEngineBinaryData:self.data];
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testHandleMultipleBinaryEvent {
    XCTestExpectation *expect = [self expectationWithDescription:@"handled multiple binary event"];
    [self.socket on:@"test" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        NSDictionary *dict = array[0];
        NSData *data = dict[@"test"];
        NSData *data2 = dict[@"test2"];
        
        if ([data isKindOfClass:[NSData class]] && [data2 isKindOfClass:[NSData class]]) {
            XCTAssertEqual(data, self.data);
            XCTAssertEqual(data2, self.data2);
            [expect fulfill];
        }
    }];
    [self.manager parseEngineMessage:@"52-[\"test\",{\"test\":{\"_placeholder\":true,\"num\":0},\"test2\":{\"_placeholder\":true,\"num\":1}}]"];
    [self.manager parseEngineBinaryData:self.data];
    [self.manager parseEngineBinaryData:self.data2];
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testChangingStatusCallsStatusChangeHandler {
    XCTestExpectation *expect = [self expectationWithDescription:@"The client should announce when the status changes"];
    VPSocketIOClientStatus statusChange = VPSocketIOClientStatusConnecting;
    [self.socket on:@"statusChange" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        int status = [array[0] intValue];
        if (status < VPSocketIOClientStatusNotConnected || status > VPSocketIOClientStatusConnected) {
            XCTFail(@"Status should be one of the defined statuses");
            return;
        }
        XCTAssertEqual(status, statusChange);
        [expect fulfill];
    }];
    [self.socket setTestStatus:statusChange];
    [self waitForExpectationsWithTimeout:0.2 handler:nil];
}

//要支持event? 通过enum.rawValue 调用了on :string
//- (void)testOnClientEvent {
//    XCTestExpectation *expect = [self expectationWithDescription:@"The client should call client event handlers"];
//    VPSocketClientEvent event = VPSocketClientEventDisconnect;
//    NSString *closeReason = @"testing";
//
//    [self.socket on:@"disconnect" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
//        NSString *reason = array[0];
//        if (![reason isKindOfClass:[NSString class]]) {
//            XCTFail(@"Client should pass data for client events");
//            return;
//        }
//        XCTAssertEqualObjects(closeReason, reason);
//        [expect fulfill];
//    }];
//
//    [self.socket handleClientEvent:@"disconnect" withData:@[closeReason]];
//    [self waitForExpectationsWithTimeout:0.2 handler:nil];
//}

- (void)testClientEventsAreBackwardsCompatible {
    XCTestExpectation *expect = [self expectationWithDescription:@"The client should call old style client event handlers"];
    VPSocketClientEvent event = VPSocketClientEventDisconnect;
    NSString *closeReason = @"testing";
    
    [self.socket on:@"disconnect" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        NSString *reason = array[0];
        if (![reason isKindOfClass:[NSString class]]) {
            XCTFail(@"Client should pass data for client events");
            return;
        }
        XCTAssertEqualObjects(closeReason, reason);
        [expect fulfill];
    }];
    
    [self.socket handleClientEvent:@"disconnect" withData:@[closeReason]];
    [self waitForExpectationsWithTimeout:0.2 handler:nil];
}

- (void)testConnectTimesOutIfNotConnected {
    XCTestExpectation *expect = [self expectationWithDescription:@"The client should call the timeout function"];
    self.socket = [self.manager socketFor:@"/someNamespace"];
    self.manager.engine = [[TestEngine alloc]initWithClient:self.manager url:self.manager.socketURL options:nil];
    [self.socket connectWithTimeoutAfter:0.5 withHandler:^{
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:0.8 handler:nil];
    
}
- (void)testConnectCallsConnectEventImmediatelyIfManagerAlreadyConnected {
    XCTestExpectation *expect = [self expectationWithDescription:@"The client should call the connect handler"];
    self.socket = [self.manager defaultSocket];
    [self.socket setTestStatus:VPSocketIOClientStatusNotConnected];
    [self.manager setTestStatus:VPSocketIOClientStatusConnected];
    [self.socket on:@"connect" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        [expect fulfill];
    }];
    [self.socket connectWithTimeoutAfter:0.3 withHandler:nil];
    [self waitForExpectationsWithTimeout:0.8 handler:nil];
}

- (void)testConnectDoesNotTimeOutIfConnected {
    XCTestExpectation *expect = [self expectationWithDescription:@"The client should not call the timeout function"];
    [self.socket setTestStatus:VPSocketIOClientStatusNotConnected];
    self.manager.engine = [[TestEngine alloc]initWithClient:self.manager url:self.manager.socketURL options:nil];
    [self.socket on:@"connect" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        [expect fulfill];
    }];
    [self.socket connectWithTimeoutAfter:0.5 withHandler:^{
        XCTFail(@"Should not call timeout handler if status is connected");
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.manager parseEngineMessage:@"0/"];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testClientCallsConnectOnEngineOpen {
    XCTestExpectation *expect = [self expectationWithDescription:@"The client call the connect handler"];
    [self.socket setTestStatus:VPSocketIOClientStatusNotConnected];
    self.manager.engine = [[TestEngine alloc] initWithClient:self.manager url:self.manager.socketURL options:nil];
    [self.socket on:@"connect" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        [expect fulfill];
    }];
    [self.socket connectWithTimeoutAfter:0.5 withHandler:^{
        XCTFail(@"Should not call timeout handler if status is connected");
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testConnectIsCalledWithNamespace {
    XCTestExpectation *expect = [self expectationWithDescription:@"The client should not call the timeout function"];
    NSString *nspString = @"/swift";
    self.socket = [self.manager socketFor:@"/swift"];
    [self.socket setTestStatus:VPSocketIOClientStatusNotConnected];
    self.manager.engine = [[TestEngine alloc]initWithClient:self.manager url:self.manager.socketURL options:nil];
    [self.socket on:@"connect" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        NSString *nsp = array[0];
        if (![nsp isKindOfClass:[NSString class]]) {
            XCTFail(@"Connect should be called with a namespace");
            return;
        }
        XCTAssertEqualObjects(nspString, nsp);
        [expect fulfill];
    }];
    
    [self.socket connectWithTimeoutAfter:0.3 withHandler:^{
        XCTFail(@"Should not call timeout handler if status is connected");
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.manager parseEngineMessage:@"0/swift"];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
    
}

//throw error
//- (void)testErrorInCustomSocketDataCallsErrorHandler {
//    XCTestExpectation *expect = [self expectationWithDescription:@"The client should call the error handler for emit errors because of custom data"];
//    [self.socket on:@"error" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
//        if (array.count != 3) {
//            XCTFail(@"Incorrect error call");
//            return ;
//        }
//        if (![array[0] isEqualToString:@"myEvent"]) {
//            XCTFail(@"Incorrect error call");
//            return ;
//        }
//        [expect fulfill];
//    }];
//    [self.socket emit:@"myEvent" items:@[@"error"]];
//    [self waitForExpectationsWithTimeout:0.2 handler:nil];
//
//}
//throw error 内部还没改
//- (void)testErrorInCustomSocketDataCallsErrorHandler_ack {
//    XCTestExpectation *expect = [self expectationWithDescription:@"The client should call the error handler for emit errors because of custom data"];
//    [self.socket on:@"error" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
//        if (array.count != 3) {
//            XCTFail(@"Incorrect error call");
//            return ;
//        }
//        if (![array[0] isEqualToString:@"myEvent"]) {
//            XCTFail(@"Incorrect error call");
//            return ;
//        }
//        [expect fulfill];
//    }];
//    [self.socket emit:@"myEvent" items:@[@"error"]];
//    [self waitForExpectationsWithTimeout:0.2 handler:nil];
//
//}

// config 需要提出来到.h
//- (void)testSettingConfigAfterInit {
//    [self.socket setTestStatus:VPSocketIOClientStatusNotConnected];
//
//}

// config需要提出来.h
//- (void)testSettingConfigAfterDisconnect {
//
//}

//- (void)testSettingConfigAfterInitWhenConnectedDoesNotIgnoreChanges {
//
//}

- (void)testClientCallsSentPingHandler {
    XCTestExpectation *expect = [self expectationWithDescription:@"The client should emit a ping event"];
    [self.socket on:@"ping" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        [expect fulfill];
    }];
    [self.manager engineDidSendPing];
    [self waitForExpectationsWithTimeout:0.2 handler:nil];
}

- (void)testClientCallsGotPongHandler {
    XCTestExpectation *expect = [self expectationWithDescription:@"The client should emit a pong event"];
    [self.socket on:@"pong" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        [expect fulfill];
    }];
    [self.manager engineDidReceivePong];
    [self waitForExpectationsWithTimeout:0.2 handler:nil];
}




@end

