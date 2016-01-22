//
//  CameraInterface.h
//  Theta_Test
//
//  Created by BjornC on 1/4/16.
//  Copyright © 2016 Builtlight. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CameraSession : NSObject

#pragma mark - Recommended api

// This is the one and only approved way of making a CameraSession
+(void) newCameraSessionWithBlock:(void(^)(CameraSession*))bloc;

-(void) setOptions:(NSDictionary*)optsDict withCompBlock:(void(^)(NSError*))bloc;
-(void) getOptions:(NSArray*)opts withCompBlock:(void(^)(NSError*,NSArray*))bloc;

// waits for completion and returns fileUri in the bloc
-(void) takePictureWithCompBlock:(void(^)(NSError*, NSString*))bloc;

-(void) findOptimalExposureTimeWithCompBlock:(void(^)(NSError*,NSNumber*))bloc;


#pragma mark - You shouldn't need the stuff below, but it's here just in case

@property (nonatomic,strong) NSURLSession *ourURLSession;
@property (nonatomic,strong) NSString *sessionId;


@end
