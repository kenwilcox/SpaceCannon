//
//  KXMenu.m
//  Space Cannon
//
//  Created by Kenneth Wilcox on 10/14/14.
//  Copyright (c) 2014 Kenneth Wilcox. All rights reserved.
//

#import "KXMenu.h"

@implementation KXMenu

- (id)init
{
  self = [super init];
  if (self) {
    SKSpriteNode *title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
    title.position = CGPointMake(0, 140);
    [self addChild:title];
    
    SKSpriteNode *scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
    scoreBoard.position = CGPointMake(0, 70);
    [self addChild:scoreBoard];
    
    SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"PLayButton"];
    playButton.name = @"Play";
    playButton.position = CGPointMake(0, 0);
    [self addChild:playButton];
    
  }
  return self;
}
@end
