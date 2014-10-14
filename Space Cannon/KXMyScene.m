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
  BOOL _didShoot;
}

// radians = degrees * (π / 180)
// degrees = radians * (180 / π)

static const CGFloat kKXShootSpeed = 1000.0f;
static const CGFloat kKXHaloLowAngle = 200.0 * M_PI / 180.0;
static const CGFloat kKXHaloHighAngle = 340.0 * M_PI / 180.0;
static const CGFloat kKXHaloSpeed = 100.0;

static inline CGVector radiansToVector(CGFloat radians)
{
  CGVector vector;
  vector.dx = cosf(radians);
  vector.dy = sinf(radians);
  return vector;
}

static inline CGFloat randomInRange(CGFloat low, CGFloat high)
{
  CGFloat value = arc4random_uniform(UINT32_MAX) / (CGFloat)UINT32_MAX;
  return value * (high - low) + low;
}

- (id)initWithSize:(CGSize)size {
  if (self = [super initWithSize:size]) {
    /* Setup your scene here */
    
    // Turn off gravity
    self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f);
    
    // Add background
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
    background.position = CGPointZero;
    background.anchorPoint = CGPointZero;
    background.blendMode = SKBlendModeReplace;
    [self addChild:background];
    
    // Add edges
    SKNode *leftEdge = [[SKNode alloc] init];
    leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height)];
    leftEdge.position = CGPointZero;
    [self addChild:leftEdge];

    SKNode *rightEdge = [[SKNode alloc] init];
    rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height)];
    rightEdge.position = CGPointMake(self.size.width, 0.0);
    [self addChild:rightEdge];
    
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
    
    // Create spawn halo actions
    SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange:1],
                                               [SKAction performSelector:@selector(spawnHalo) onTarget:self]]];
    [self runAction:[SKAction repeatActionForever:spawnHalo]];
    
  }
  return self;
}

- (void)shoot
{
  // Create ball node
  SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"Ball"];
  // Give them a name, so we can find them later
  ball.name = @"ball";
  CGVector rotationVector = radiansToVector(_cannon.zRotation);
  ball.position = CGPointMake(_cannon.position.x + (_cannon.size.width * 0.5 * rotationVector.dx),
                              _cannon.position.y + (_cannon.size.width * 0.5 * rotationVector.dy));
  [_mainLayer addChild:ball];
  
  ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];
  ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * kKXShootSpeed, rotationVector.dy * kKXShootSpeed);
  
  // Bounciness
  ball.physicsBody.restitution = 1.0;
  // linear velocity - 0 is off
  ball.physicsBody.linearDamping = 0.0;
  // Turn off friction
  ball.physicsBody.friction = 0.0;
}

-(void)spawnHalo
{
  // Create halo node
  SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
  halo.name = @"halo";
  CGFloat halfHalo = halo.size.width * 0.5;
  halo.position = CGPointMake(randomInRange(halfHalo, self.size.width - halfHalo),self.size.height + halfHalo);
  halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:16.0];
  
  CGVector direction = radiansToVector(randomInRange(kKXHaloLowAngle, kKXHaloHighAngle));
  
  halo.physicsBody.velocity = CGVectorMake(direction.dx * kKXHaloSpeed, direction.dy * kKXHaloSpeed);
  halo.physicsBody.restitution = 1.0;
  halo.physicsBody.linearDamping = 0.0;
  halo.physicsBody.friction = 0.0;
  
  [_mainLayer addChild:halo];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  /* Called when a touch begins */
  
  //for (UITouch *touch in touches) {
  _didShoot = YES;
  //}
}

/* SpriteKit Event loop: update, didEvaluateActions, didSimulatePhysics */

- (void)update:(CFTimeInterval)currentTime {
  /* Called before each frame is rendered */
}

- (void)didEvaluateActions
{
  
}

- (void)didSimulatePhysics
{
  if (_didShoot) {
    [self shoot];
    _didShoot = NO;
  }
  
  // Remove unused nodes
  [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
    if (!CGRectContainsPoint(self.frame, node.position)) {
      [node removeFromParent];
    }
  }];

  // Can't clean up this way - they are created off screen and cleaned up - dooh
//  [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
//    if (!CGRectContainsPoint(self.frame, node.position)) {
//      [node removeFromParent];
//    }
//  }];
}

@end
