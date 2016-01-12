//
//  CameraInterface.h
//  Theta_Test
//
//  Created by BjornC on 1/4/16.
//  Copyright © 2016 Builtlight. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CameraSession : NSObject

@property (nonatomic,strong) NSURLSession *ourURLSession;
@property (nonatomic,strong) NSString *sessionId;

@end
