//
//  KXMyScene.m
//  Space Cannon
//
//  Created by Kenneth Wilcox on 10/12/14.
//  Copyright (c) 2014 Kenneth Wilcox. All rights reserved.
//

#import "KXMyScene.h"

@implementation KXMyScene
{
  SKNode *_mainLayer;
  SKSpriteNode *_cannon;
}

-(id)initWithSize:(CGSize)size {
  if (self = [super initWithSize:size]) {
    /* Setup your scene here */
    
    // Add background
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
    background.position = CGPointZero;
    background.anchorPoint = CGPointZero;
    background.blendMode = SKBlendModeReplace;
    [self addChild:background];
    
    // Add main layer
    _mainLayer = [[SKNode alloc] init];
    [self addChild:_mainLayer];
    
    // Add cannon
    _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
    _cannon.position = CGPointMake(self.size.width * 0.5, 0.0);
    [_mainLayer addChild:_cannon];
    
    // Create cannon rotation actions
    SKAction *rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                                  [SKAction rotateByAngle:-M_PI duration:2]]];
    [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
    
  }
  return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  /* Called when a touch begins */
  
  for (UITouch *touch in touches) {

  }
}

-(void)update:(CFTimeInterval)currentTime {
  /* Called before each frame is rendered */
}

@end
