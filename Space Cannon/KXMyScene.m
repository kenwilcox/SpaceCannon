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

static inline CGVector radiansToVector(CGFloat radians)
{
  CGVector vector;
  vector.dx = cosf(radians);
  vector.dy = sinf(radians);
  return vector;
}

- (id)initWithSize:(CGSize)size {
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

- (void)shoot
{
  // Create ball node.
  SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"Ball"];
  CGVector rotationVector = radiansToVector(_cannon.zRotation);
  ball.position = CGPointMake(_cannon.position.x + (_cannon.size.width * 0.5 * rotationVector.dx),
                              _cannon.position.y + (_cannon.size.width * 0.5 * rotationVector.dy));
  [_mainLayer addChild:ball];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  /* Called when a touch begins */
  
  for (UITouch *touch in touches) {
    [self shoot];
  }
}

- (void)update:(CFTimeInterval)currentTime {
  /* Called before each frame is rendered */
}

@end
