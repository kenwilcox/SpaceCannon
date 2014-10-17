//
//  KXBall.m
//  Space Cannon
//
//  Created by Kenneth Wilcox on 10/17/14.
//  Copyright (c) 2014 Kenneth Wilcox. All rights reserved.
//

#import "KXBall.h"

@implementation KXBall

- (void)updateTrail
{
  if (self.trail) {
    self.trail.position = self.position;
  }
}

- (void)removeFromParent
{
  if (self.trail) {
    self.trail.particleBirthRate = 0.0;
    CGFloat duration = self.trail.particleLifetime + self.trail.particleLifetimeRange;
    SKAction *removeTrail = [SKAction sequence:@[[SKAction waitForDuration:duration],
                                                 [SKAction removeFromParent]]];
    [self runAction:removeTrail];
  }
  [super removeFromParent];
}

@end
