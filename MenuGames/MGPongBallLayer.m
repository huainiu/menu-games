//
//  MGPongBallLayer.m
//  MenuGames
//
//  Created by Rasmus Andersson on 6/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MGPongBallLayer.h"
#import "MGPongPaddleLayer.h"
#import "MGPongView.h"
#include <math.h>


#define CP(__X__,__Y__) CGPointMake(__X__,__Y__)

static CGPoint cp_mul(const CGPoint v, const CGFloat s) {
	return CP(v.x*s, v.y*s);
}
static CGPoint cp_mul2(const CGPoint v1, const CGPoint v2) {
	return CP(v1.x*v2.x, v1.y*v2.y);
}
static CGPoint cp_div(const CGPoint v, const CGFloat s) {
	return CP(v.x/s, v.y/s);
}
static CGPoint cp_add(const CGPoint v1, const CGPoint v2) {
	return CP(v1.x + v2.x, v1.y + v2.y);
}
static CGPoint cp_sub(const CGPoint v1, const CGPoint v2) {
	return CP(v1.x - v2.x, v1.y - v2.y);
}
static CGFloat cp_dot(const CGPoint v1, const CGPoint v2) {
	return v1.x*v2.x + v1.y*v2.y;
}
static CGFloat cp_len(const CGPoint v) {
	return sqrtf(cp_dot(v, v));
}
static CGPoint cp_norm(const CGPoint v) {
	return cp_mul(v, 1.0 / cp_len(v));
}
static CGFloat deg2rad(const CGFloat degrees) {
  return degrees * (M_PI / 180);
}
static CGFloat rad2deg(const CGFloat radians) {
  return radians * (180 / M_PI);
}


@implementation MGPongBallLayer

@synthesize gameView = gameView_;

- (id)init {
  self = [super init];
  if (self) {
    [self resetBasedOnCurrentScore:0.0];
  }
  return self;
}


- (void)dealloc {
  [super dealloc];
}


- (void)resetBasedOnCurrentScore:(CGFloat)score {
  // How far the ball moves during 1 second:
  const CGFloat speed = 40.0;
  
  // Initial angle
  CGFloat radians;
  if (score < 0.01 && score > -0.01) {
    // Totally random who gets the ball
    radians = ((CGFloat)random() / RAND_MAX) * (M_PI * 2);
    score = 0.0;
  } else if (score < 0.0) {
    // Right player shoots the ball
    const CGFloat minAngle = 2.1;
    const CGFloat maxAngle = 4.2;
    radians = (((CGFloat)random() / RAND_MAX) * (maxAngle - minAngle)) + minAngle;
  } else {
    // Left player shoots the ball
    const CGFloat minAngle = 1.05;
    const CGFloat maxAngle = 5.25;
    radians = (((CGFloat)random() / RAND_MAX) * (maxAngle + minAngle));
    if (radians > maxAngle)
      radians -= maxAngle;
  }
  
  // Clamp the angle so the ball has an interesting starting vector
  const CGFloat kRadians60deg = 1.0471975512;
  const CGFloat kRadians120deg = 2.0943951024;
  const CGFloat kRadians240deg = 4.1887902048;
  const CGFloat kRadians300deg = 5.2359877560;
  
  if (radians < kRadians120deg && radians > kRadians60deg) {
    NSLog(@"clamped radians to outside 60-120");
    if (score < 0.0) { // Right player shoots
      radians = kRadians120deg;
    } else if (score > 0.0) { // Left player shoots
      radians = kRadians60deg;
    } else if ((kRadians120deg - radians) < (kRadians60deg - radians)) {
      radians = kRadians120deg;
    } else {
      radians = kRadians60deg;
    }
  } else if (radians < kRadians300deg && radians > kRadians240deg) {
    NSLog(@"clamped radians to outside 240-300");
    if (score < 0.0) { // Right player shoots
      NSLog(@"R player shoots -- 240 deg");
      radians = kRadians240deg;
    } else if (score > 0.0) { // Left player shoots
      NSLog(@"L player shoots -- 300 deg");
      radians = kRadians300deg;
    } else if ((kRadians300deg - radians) < (kRadians240deg - radians)) {
      radians = kRadians300deg;
    } else {
      radians = kRadians240deg;
    }
  }
  velocity_.x = speed * cos(radians);
  velocity_.y = speed * sin(radians);
}



- (BOOL)collideWithPaddle:(MGPongPaddleLayer*)paddle
                ballFrame:(CGRect)ballFrame
             isLeftPaddle:(BOOL)isLeftPaddle {
  // Check for paddle collisions
  CGRect paddleFrame = paddle.presentationFrame;
  if (CGRectIntersectsRect(ballFrame, paddleFrame)) {
    CGPoint paddleCenter =
        CP((paddleFrame.origin.x - (paddleFrame.size.width / 2.0)),
           paddleFrame.origin.y - (paddleFrame.size.width / 2.0));
    CGPoint ballCenter =
        CP((ballFrame.origin.x - (ballFrame.size.width / 2.0)),
           (ballFrame.origin.y - (ballFrame.size.height / 2.0)) );
    
    CGFloat cd; // distance between ball centers, aka Collision Distance 
    CGFloat rd; // the sum of the two ball's radii 
    CGFloat ballRadius = ballFrame.size.height / 2.0;
    CGFloat paddleRadius = paddleFrame.size.width / 2.0;
    
    cd = cp_len(cp_sub(ballCenter, paddleCenter));
    rd = ballRadius + paddleRadius; 
    
    CGFloat a =
        (ballRadius * ballRadius - paddleRadius * paddleRadius + rd * rd)
        / (2 * rd);
    // the point on the line that lays between both circles that is centered in
    // the middle of the collision sector of the overlapping/touching circles 
    // cp = ball1.Location + a * (ball2.Location - ball1.Location) / rd;
    // cp = ((ball1.Location + a) * (ball2.Location - ball1.Location)) / rd;
    CGPoint cp = cp_div(
                        cp_mul2(
                                cp_add(ballCenter, CP(a, a)),
                                cp_sub(paddleCenter, ballCenter)
                                ),
                        rd);
    
    
    CGPoint collisionNormal = cp_norm(cp_sub(cp, paddleCenter));
    CGFloat dot = cp_dot(collisionNormal, cp_norm(velocity_));
    
    // TODO: test on radians and limit angle based on "if v1 < r...
    //CGFloat radians = acos(dot);
    //if (isLeftPaddle && radians < ) {...
    
    #if 0  // DEBUG: draw collision normals extending from paddle center
    CGFloat radians = acos(dot);
    CALayer *lineLayer = [CALayer layer];
    lineLayer.backgroundColor = CGColorCreateGenericGray(0.0, 0.6);
    lineLayer.position = paddleCenter;
    lineLayer.bounds = (CGRect) { {0, 0}, {100.0, 1.0} };
    lineLayer.transform = CATransform3DMakeRotation(radians, 0, 0, 1);
    [paddle.superlayer addSublayer:lineLayer];
    //NSLog(@"collisionNormal: %@ (%f)", NSStringFromPoint(collisionNormal),
    //      rad2deg(radians));
    #endif
    
    velocity_ = cp_mul(
                       cp_norm(
                               cp_mul(
                                      cp_mul(collisionNormal, dot - -1.0),
                                      2.0f
                                      )
                               ),
                       cp_len(velocity_) * -1.0);
    
    return YES;
  }
  return NO;
}


- (CGPoint)positionInFuture:(NSTimeInterval)period {
  CGPoint ballPos = self.position;
  ballPos.x += period * velocity_.x;
  ballPos.y += period * velocity_.y;
  return ballPos;
}


- (void)update:(NSTimeInterval)period {
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  
  // The ball's visual frame and position (center point)
  CGRect frame = self.frame;
  CGPoint ballPos = self.position;
  
  // Advance the ball
  ballPos.x += period * velocity_.x;
  ballPos.y += period * velocity_.y;
  self.position = ballPos;
  
  MGPongPaddleLayer *rightPaddle = gameView_.rightPaddle;
  MGPongPaddleLayer *leftPaddle = gameView_.leftPaddle;
  
  // Check for paddle collisions
  if ([self collideWithPaddle:rightPaddle ballFrame:frame isLeftPaddle:NO]) {
    // ok, hit right paddle. Trigger some event or something in the future
    NSLog(@"hit right paddle");
    ballPos.x += period * velocity_.x;
    ballPos.y += period * velocity_.y;
    self.position = ballPos;
  } else if ([self collideWithPaddle:leftPaddle ballFrame:frame isLeftPaddle:YES]) {
    // ok, hit left paddle. Trigger some event or something in the future
    NSLog(@"hit left paddle");
    ballPos.x += period * velocity_.x;
    ballPos.y += period * velocity_.y;
    self.position = ballPos;
  } else {
    // Check for wall collisions
    frame = self.frame;
    CGRect gameBounds = rightPaddle.superlayer.bounds;
    BOOL checkCornerCollision = NO;
    if (frame.origin.y + frame.size.height > gameBounds.size.height) {
      // top wall
      frame.origin.y = gameBounds.size.height - frame.size.height;
      velocity_.y = -velocity_.y;
      checkCornerCollision = YES;
    } else if (frame.origin.x + frame.size.width > gameBounds.size.width) {
      // right wall
      frame.origin.x = gameBounds.size.width - frame.size.width;
      velocity_.x = -velocity_.x;
      [gameView_ ballHitRightWall:self];
    } else if (frame.origin.y < 0.0) {
      // bottom wall
      frame.origin.y = 0.0;
      velocity_.y = -velocity_.y;
      checkCornerCollision = YES;
    } else if (frame.origin.x < 0.0) {
      // left wall
      frame.origin.x = 0;
      velocity_.x = -velocity_.x;
      [gameView_ ballHitLeftWall:self];
    }
    
    if (checkCornerCollision) {
      // Handle corner collisions
      if (frame.origin.x + frame.size.width >
          gameBounds.size.width - frame.size.width) {
        velocity_.x = -velocity_.x;
        [gameView_ ballHitRightWall:self];
      } else if (frame.origin.x < frame.size.width) {
        velocity_.x = -velocity_.x;
        [gameView_ ballHitLeftWall:self];
      }
    }
    
    self.frame = frame;
  }
  
  [CATransaction commit];
}


@end
