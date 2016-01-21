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

// internal use only!
-(instancetype) init {
    self = [super init];
    if (self) {
        self.ourURLSession = [NSURLSession sharedSession];
        self.sessionId = nil;
    }
    return self;
}


// This factory method is the recommended way to start-a-session/create-an-object
+(void) newCameraSessionWithBlock:(void(^)(CameraSession*))bloc {
    CameraSession *camSess = [[CameraSession alloc] init];
    
    if (camSess) { // so far so good
        [camSess startSessionWithCompBlock:^(NSError *err) {
            if (err == nil) {
                bloc(camSess);
            } else {
                bloc(nil);
            }
        }];
    } else { // things are f'd, return right away with nil
        bloc(nil);
    }
}


// starts a session, sets our sessionID property
-(void) startSessionWithCompBlock:(void(^)(NSError*))bloc {
    // check for existing sessionID (this should NEVER happen)
    if (self.sessionId != nil) {
        NSLog(@"starting session with existing session id, wtf is wrong with you!??!");
        assert(0);
    }
    NSDictionary *postParam = @{ @"name": @"camera.startSession",
                                @"parameters": @[] };
    [self executePostRequestWithParams:postParam withCompBlock:^(NSError *e, NSDictionary *d) {
        if (e == nil) { // all is well
            self.sessionId = [d valueForKeyPath:@"results.sessionId"];
            NSLog(@"sessionId set to %@", self.sessionId);
            bloc(nil);
        } else {
            bloc(e);
        }
    }];
}

#pragma mark - Picture Metadata

-(void) exposureTimeFromFileUri:(NSString*)fileUri withCompBlock:(void(^)(NSError*, NSNumber*))bloc {
    NSDictionary *postParam = @{ @"name": @"camera.getMetadata",
                                 @"parameters": @{ @"fileUri": fileUri }};
    [self executePostRequestWithParams:postParam withCompBlock:^(NSError *e, NSDictionary *d) {
        NSLog(@"exposure info: %@, err: %@",d,e);
        if (e == nil) {
            NSNumber *expTime = [d valueForKeyPath:@"results.exif.ExposureTime"];
            bloc(nil,expTime);
        } else {
            bloc(e,nil);
        }
    }];
    
}

#pragma mark - Taking a picture

// sends the command, waits for results and returns fileUri in bloc
-(void) takePictureWithCompBlock:(void(^)(NSError*, NSString*))bloc {
    [self execTakePictureWithCompBlock:^(NSError *takeErr, NSString *commId) {
        if (takeErr != nil) {
            bloc(takeErr, nil); // error returns right away
        } else {
            // wait around for our command to be done
            [self waitForCommand:commId withCompBlock:bloc];
        }
    }];
}


-(void) waitForCommand:(NSString*)commId withCompBlock:(void(^)(NSError*, NSString*))bloc {
    [self statusPostRequestWithParmams:@{ @"id":commId} withCompBlock:^(NSError *e, NSDictionary *d) {
        if (e != nil) {
            bloc(e,nil);
        } else if ([[d valueForKey:@"state"] isEqualToString:@"done"]){
            NSString *fileUri = [d valueForKeyPath:@"results.fileUri"];
            bloc(nil,fileUri);
        } else { // not done yet
            [self waitForCommand:commId withCompBlock:bloc];
        }
    }];
}

// Just gives the command and returns the command id (no waiting)
-(void) execTakePictureWithCompBlock:(void(^)(NSError*, NSString*))bloc {
    NSDictionary *postParam = @{ @"name": @"camera.takePicture",
                                 @"parameters": @{ @"sessionId": self.sessionId }};
    [self executePostRequestWithParams:postParam withCompBlock:^(NSError *e, NSDictionary *d) {
        NSLog(@"take pic, err= %@  dict= %@",e,d);
        if (e == nil) {
            NSString *commId = [d valueForKey:@"id"];
            bloc(nil,commId);
        } else {
            bloc(e,nil);
        }
    }];
}

#pragma mark - Options

-(void) getOptions:(NSArray*)opts withCompBlock:(void(^)(NSError*,NSArray*))bloc {
    NSDictionary *postParam = @{ @"name": @"camera.getOptions",
                                 @"parameters" : @{ @"sessionId": self.sessionId,
                                                    @"optionNames": opts }};
    [self executePostRequestWithParams:postParam withCompBlock:^(NSError *e, NSDictionary *d) {
        NSArray *currOpts = [d valueForKeyPath:@"results.options"];
        NSLog(@"get Options, err= %@ dict= %@",e,currOpts);
        if (e==nil) { // we're golden
            bloc(nil,currOpts);
        } else {
            bloc(e,nil);
        }

    }];
}

-(void) setOptions:(NSDictionary*)optsDict withCompBlock:(void(^)(NSError*))bloc {
    NSDictionary *postParam = @{ @"name": @"camera.setOptions",
                                 @"parameters" : @{ @"sessionId": self.sessionId,
                                                  @"options": optsDict }};
    [self executePostRequestWithParams:postParam withCompBlock:^(NSError *e, NSDictionary *d) {
        NSLog(@"setOptions, err= %@ dict= %@",e,d);
        if (e==nil) { // we're golden
            bloc(nil);
        } else {
            bloc(e);
        }
    }];
}

#pragma mark - General request types (these call the low level methods)

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

#pragma mark - Low level basics. All actual networking done below here

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
