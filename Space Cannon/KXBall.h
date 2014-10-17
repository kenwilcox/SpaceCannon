//
//  KXBall.h
//  Space Cannon
//
//  Created by Kenneth Wilcox on 10/17/14.
//  Copyright (c) 2014 Kenneth Wilcox. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface KXBall : SKSpriteNode

@property (nonatomic) SKEmitterNode *trail;
@property (nonatomic) int bounces;

- (void)updateTrail;

@end
