//
//  MGPongView.h
//  MenuGames
//
//  Created by Rasmus Andersson on 6/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "MGPeriodicTimerDelegate.h"

@class MGPongBallLayer, MGPongPaddleLayer, MGPeriodicTimer, MGPongPlayer;

@interface MGPongView : NSView <NSWindowDelegate> {
  NSSize baseSize_;
  NSTimer *animationTimer_;
  MGPongBallLayer *ball_;
  MGPongPaddleLayer *leftPaddle_;
  MGPongPaddleLayer *rightPaddle_;
  MGPongPlayer *player1_; // left-hand side
  MGPongPlayer *player2_; // right-hand side
  CALayer *pauseIcon_;
  CALayer *banner_;
  __weak MGPongPaddleLayer *localPlayerPaddle_;
  __weak MGPongPaddleLayer *remotePlayerPaddle_; // AI or non-local human
  CALayer *vDividerLayer_;
  CALayer *leftDividerLayer_;
  CALayer *rightDividerLayer_;
  CGFloat score_;
  BOOL up1KeyPressed_;
  BOOL down1KeyPressed_;
  BOOL up2KeyPressed_;
  BOOL down2KeyPressed_;
  BOOL waitingToStartGame_;
  uint64_t timeOfLastUpdate_;
}

@property (readonly) MGPongPaddleLayer *rightPaddle;
@property (readonly) MGPongPaddleLayer *leftPaddle;

@property (readonly) MGPongPaddleLayer *firstPlayerPaddle;
@property (readonly) MGPongPaddleLayer *secondPlayerPaddle;

@property (assign, nonatomic) CGFloat score;

- (void)toggleFullscreen:(id)sender;
- (void)resetGame:(id)sender;
- (void)startGame:(id)sender;
- (void)newGame:(id)sender;

- (void)resumeUpdating;
- (void)pauseUpdating;

- (void)showBanner:(NSString*)imageName duration:(NSTimeInterval)duration;
- (void)hideBanner:(id)sender;

- (void)paddle:(MGPongPaddleLayer*)paddle
destinationChangedFrom:(CGFloat)startYPosition
  withDuration:(CFTimeInterval)duration;

- (void)ballHitLeftWall:(MGPongBallLayer*)ball;
- (void)ballHitRightWall:(MGPongBallLayer*)ball;

@end
