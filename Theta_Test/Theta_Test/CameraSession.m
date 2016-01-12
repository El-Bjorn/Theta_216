//
//  CameraInterface.m
//  Theta_Test
//
//  Created by BjornC on 1/4/16.
//  Copyright © 2016 Builtlight. All rights reserved.
//

#import "CameraSession.h"

@implementation CameraSession

#pragma mark - Setup Session

-(instancetype) init {
    self = [super init];
    if (self) {
        self.ourURLSession = [NSURLSession sharedSession];
    }
    return self;
}

#pragma mark - Networking wrapper methods

// POST requests
#define EXECUTE_REQ_PATH    @"/commands/execute"
#define STATUS_REQ_PATH     @"/commands/status"
#define STATE_REQ_PATH      @"/state"
#define UPDATES_REQ_PATH    @"/checkForUpdates"

-(void) executePostRequestWithParams:(NSDictionary*)params
                       withCompBlock:(void(^)(NSError*,NSDictionary*))bloc
{
    [self ricohPostRequest:EXECUTE_REQ_PATH withParams:params
              andCompBlock:^(NSError *err, NSDictionary *dict)
    {
        bloc(err,dict);
    }];
}

-(void) statusPostRequestWithParmams:(NSDictionary*)params
                       withCompBlock:(void(^)(NSError*,NSDictionary*))bloc
{
    [self ricohPostRequest:STATUS_REQ_PATH withParams:params
              andCompBlock:^(NSError *err, NSDictionary *dict)
    {
        bloc(err,dict);
    }];
}

-(void) updatePostRequestWithParams:(NSDictionary*)params
                      withCompBlock:(void(^)(NSError*,NSDictionary*))bloc
{
    [self ricohPostRequest:UPDATES_REQ_PATH withParams:params
              andCompBlock:^(NSError *err, NSDictionary *dict)
    {
        bloc(err,dict);
    }];
    
}

#pragma mark - All actual networking done below here

// This is the only GET
#define INFO_REQ_PATH       @"/info"

#define CAMERA_URL @"http://192.168.1.1/osc"

-(void) getCameraInfoWithCompBlock:(void(^)(NSError*,NSDictionary*))bloc {
    NSString *urlPath = [CAMERA_URL stringByAppendingString:INFO_REQ_PATH];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlPath]];
    NSLog(@"cam info request: %@",request);
    
    NSURLSessionTask *infoTask = [self.ourURLSession dataTaskWithRequest:request
                                                       completionHandler:^(NSData * _Nullable data,
                                                                           NSURLResponse * _Nullable response,
                                                                           NSError * _Nullable error)
    {
        // check for session task (network) error
        if (error != nil){
            NSLog(@"error doing request %@: %@",request,[error localizedDescription]);
            dispatch_async(dispatch_get_main_queue(), ^{
                bloc(error,nil);
            });
            return;
        }
        // get info json
        NSDictionary *resultData = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:&error];
        if (error != nil) {
            NSLog(@"json decoding error %@",[error localizedDescription]);
            dispatch_async(dispatch_get_main_queue(), ^{
                bloc(error,nil);
            });
            return;
        }
        // We're good
        dispatch_async(dispatch_get_main_queue(), ^{
            bloc(nil,resultData);
        });
    }];
    [infoTask resume];
    
}

// All POST requests come through here
-(void) ricohPostRequest:(NSString*)reqPath
               withParams:(NSDictionary*)params
            andCompBlock:(void(^)(NSError*, NSDictionary*))bloc
{
    // construct url
    NSString *urlPath = [CAMERA_URL stringByAppendingString:reqPath];
    NSLog(@"url command path: %@",urlPath);
    NSLog(@"command params: %@", params);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlPath]];
    
    // build param and add to request
    NSError *jsonErr = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&jsonErr];
    if (jsonErr != nil) {
        NSLog(@"Error encoding post parameter: %@",[jsonErr localizedDescription]);
        dispatch_async(dispatch_get_main_queue(), ^{
            bloc(jsonErr,nil);
        });
        return;
    }
    [request setHTTPBody:jsonData];
    [request setHTTPMethod:@"POST"];
    
    NSURLSessionTask *task = [self.ourURLSession dataTaskWithRequest:request
                                                   completionHandler:^(NSData *data,
                                                                       NSURLResponse *response,
                                                                       NSError *error)
    {
        // check for session task (network) error
        if (error != nil){
            NSLog(@"error doing request %@: %@",request,[error localizedDescription]);
            dispatch_async(dispatch_get_main_queue(), ^{
                bloc(error,nil);
            });
            return;
        }
        // unpack the response
        NSDictionary *resultData = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:&error];
        if (error != nil) {
            NSLog(@"json decoding error %@",[error localizedDescription]);
            dispatch_async(dispatch_get_main_queue(), ^{
                bloc(error,nil);
            });
            return;
        }
        // We're good
        dispatch_async(dispatch_get_main_queue(), ^{
            bloc(nil,resultData);
        });
    }];
    [task resume];
}


@end
