//
//  Theta_TestTests.m
//  Theta_TestTests
//
//  Created by BjornC on 1/4/16.
//  Copyright © 2016 Builtlight. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CameraSession.h"

@interface CameraSession ()
-(void) ricohPostRequest:(NSString*)reqPath
              withParams:(NSDictionary*)params
            andCompBlock:(void(^)(NSError*,NSDictionary*))bloc;

-(void) getCameraInfoWithCompBlock:(void(^)(NSError*,NSDictionary*))bloc;

-(void) executePostRequestWithParams:(NSDictionary*)params
                       withCompBlock:(void(^)(NSError*,NSDictionary*))bloc;


@end

@interface Theta_TestTests : XCTestCase

@end

@implementation Theta_TestTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void) testCameraInfoReq {
    CameraSession *cs = [[CameraSession alloc] init];
    dispatch_semaphore_t wait_sema = dispatch_semaphore_create(0);

    [cs getCameraInfoWithCompBlock:^(NSError *e, NSDictionary *d) {
        NSLog(@"info req, err= %@, dict= %@",e,d);
        dispatch_semaphore_signal(wait_sema);
    }];
    // wait for semaphore
    while (dispatch_semaphore_wait(wait_sema, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    }
}

-(void) testExecutePostReq {
    CameraSession *cs = [[CameraSession alloc] init];
    NSDictionary *postParm = @{ @"name": @"camera.startSession",
                                @"parameters": @[] };
    dispatch_semaphore_t wait_sema = dispatch_semaphore_create(0);
    
    [cs executePostRequestWithParams:postParm withCompBlock:^(NSError *e, NSDictionary *d) {
        NSLog(@"execute post, err= %@, dict=%@",e,d);
        dispatch_semaphore_signal(wait_sema);
    }];
    // wait for semaphore
    while (dispatch_semaphore_wait(wait_sema, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    }
}

-(void) testStartSession {
    CameraSession *cs = [[CameraSession alloc] init];
    NSDictionary *postParm = @{ @"name": @"camera.startSession",
                                @"parameters": @[] };
    NSString *reqPath = @"/commands/execute";
    
    dispatch_semaphore_t wait_sema = dispatch_semaphore_create(0);
    
    [cs ricohPostRequest:reqPath withParams:postParm andCompBlock:^(NSError *e, NSDictionary *d) {
        NSLog(@"ret block. error= %@, response dict: %@",e,d);
        // all done
        dispatch_semaphore_signal(wait_sema);
    }];
    
    // wait for semaphore
    while (dispatch_semaphore_wait(wait_sema, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    }

}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
