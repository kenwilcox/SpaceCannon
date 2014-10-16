//
//  KXMyScene.m
//  Space Cannon
//
//  Created by Kenneth Wilcox on 10/12/14.
//  Copyright (c) 2014 Kenneth Wilcox. All rights reserved.
//

#import "KXMyScene.h"
#import "KXMenu.h"

@implementation KXMyScene
{
  SKNode *_mainLayer;
  KXMenu *_menu;
  SKSpriteNode *_cannon;
  SKSpriteNode *_ammoDisplay;
  SKLabelNode *_scoreLabel;
  BOOL _didShoot;
  BOOL _gameOver;
  
  // Sound Actions
  SKAction *_bounceSound;
  SKAction *_deepExplosionSound;
  SKAction *_explosionSound;
  SKAction *_laserSound;
  SKAction *_zapSound;
  
  NSUserDefaults *_userDefaults;
}

// radians = degrees * (π / 180)
// degrees = radians * (180 / π)

static const CGFloat kKXShootSpeed = 1000.0f;
static const CGFloat kKXHaloLowAngle = 200.0 * M_PI / 180.0;
static const CGFloat kKXHaloHighAngle = 340.0 * M_PI / 180.0;
static const CGFloat kKXHaloSpeed = 100.0;

// BitMasks
static const uint32_t kKXHaloCategory    = 0x1 << 0;
static const uint32_t kKXBallCategory    = 0x1 << 1;
static const uint32_t kKXEdgeCategory    = 0x1 << 2;
static const uint32_t kKXShieldCategory  = 0x1 << 3;
static const uint32_t kKXLifeBarCategory = 0x1 << 4;

static NSString * const kKXKeyTopScore = @"TopScore";
static NSString * const kKXKeySpawnHalo = @"SpawnHalo";

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
    self.physicsWorld.contactDelegate = self;
    
    // Add background
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
    background.position = CGPointZero;
    background.anchorPoint = CGPointZero;
    background.blendMode = SKBlendModeReplace;
    [self addChild:background];
    
    // Add edges
    SKNode *leftEdge = [[SKNode alloc] init];
    leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100)];
    leftEdge.position = CGPointZero;
    leftEdge.physicsBody.categoryBitMask = kKXEdgeCategory;
    [self addChild:leftEdge];
    
    SKNode *rightEdge = [[SKNode alloc] init];
    rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100)];
    rightEdge.position = CGPointMake(self.size.width, 0.0);
    rightEdge.physicsBody.categoryBitMask = kKXEdgeCategory;
    [self addChild:rightEdge];
    
    // Add main layer
    _mainLayer = [[SKNode alloc] init];
    [self addChild:_mainLayer];
    
    // Add cannon
    _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
    _cannon.position = CGPointMake(self.size.width * 0.5, 0.0);
    [self addChild:_cannon];
    
    // Create cannon rotation actions
    SKAction *rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                                  [SKAction rotateByAngle:-M_PI duration:2]]];
    [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
    
    // Create spawn halo actions
    SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange:1],
                                               [SKAction performSelector:@selector(spawnHalo) onTarget:self]]];
    [self runAction:[SKAction repeatActionForever:spawnHalo] withKey:kKXKeySpawnHalo];
    
    // Setup Ammo Display
    _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
    _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
    _ammoDisplay.position = _cannon.position;
    [self addChild:_ammoDisplay];
    
    SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:1],
                                                   [SKAction runBlock:^{
      self.ammo++;
    }]]];
    [self runAction:[SKAction repeatActionForever:incrementAmmo]];
    
    // Set up score display
    _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    _scoreLabel.position = CGPointMake(15, 10);
    _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _scoreLabel.fontSize = 15;
    [self addChild:_scoreLabel];
    
    _bounceSound = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
    _deepExplosionSound = [SKAction playSoundFileNamed:@"DeepExplosion.caf" waitForCompletion:NO];
    _explosionSound = [SKAction playSoundFileNamed:@"Explosion.caf" waitForCompletion:NO];
    _laserSound = [SKAction playSoundFileNamed:@"Laser.caf" waitForCompletion:NO];
    _zapSound = [SKAction playSoundFileNamed:@"Zap.caf" waitForCompletion:NO];
    
    // Setup menu
    _menu = [[KXMenu alloc] init];
    _menu.position = CGPointMake(self.size.width * 0.5, self.size.height -220);
    [self addChild:_menu];

    // Set initial values
    self.ammo = 5;
    self.score = 0;
    _gameOver = YES;
    _scoreLabel.hidden = YES;
    
    // Load up top score
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _menu.topScore = [_userDefaults integerForKey:kKXKeyTopScore];

  }
  return self;
}

- (void)newGame
{
  [_mainLayer removeAllChildren];
  
  // Setup Sheilds
  for (int i = 0; i < 6; i++) {
    SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
    shield.name = @"shield";
    shield.position = CGPointMake(35 + (50 *i), 90);
    [_mainLayer addChild:shield];
    shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
    shield.physicsBody.categoryBitMask = kKXShieldCategory;
    shield.physicsBody.collisionBitMask = 0;
  }
  
  // Setup Life Bar
  SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
  CGFloat halfLifeBar = lifeBar.size.width * 0.5;
  lifeBar.position = CGPointMake(self.size.width * 0.5, 70);
  lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-halfLifeBar, 0)
                                                     toPoint:CGPointMake(halfLifeBar, 0)];
  lifeBar.physicsBody.categoryBitMask = kKXLifeBarCategory;
  [_mainLayer addChild:lifeBar];
  
  // Set initial values
  [self actionForKey:kKXKeySpawnHalo].speed = 1.0;
  self.ammo = 5;
  self.score = 0;
  _scoreLabel.hidden = NO;
  _menu.hidden = YES;
  _gameOver = NO;

}

-(void)setAmmo:(int)ammo
{
  if (ammo >= 0 && ammo <= 5) {
    _ammo = ammo;
    _ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d", ammo]];
  }
}

- (void)setScore:(int)score
{
  _score = score;
  _scoreLabel.text = [NSString stringWithFormat:@"Score: %d", score];
}

- (void)shoot
{
  if (self.ammo > 0) {
    self.ammo--;
    
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
    
    ball.physicsBody.restitution = 1.0;
    ball.physicsBody.linearDamping = 0.0;
    ball.physicsBody.friction = 0.0;
    ball.physicsBody.categoryBitMask = kKXBallCategory;
    ball.physicsBody.collisionBitMask = kKXEdgeCategory;// | kKXHaloCategory;
    ball.physicsBody.contactTestBitMask = kKXEdgeCategory;
    [self runAction:_laserSound];
    
    // Create trail
    NSString *ballTrailPath = [[NSBundle mainBundle] pathForResource:@"BallTrail" ofType:@"sks"];
    SKEmitterNode *ballTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:ballTrailPath];
    // Without the following line the ball looks more like a spark (kinda cool)
    ballTrail.targetNode = _mainLayer;
    [ball addChild:ballTrail];
  }
}

-(void)spawnHalo
{
  // Increase spawn speed if not on menu
  if (!_gameOver) {
    SKAction *spawnHaloAction = [self actionForKey:kKXKeySpawnHalo];
    if (spawnHaloAction.speed < 1.5) {
      spawnHaloAction.speed += 0.01;
    }
  }
  
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
  halo.physicsBody.categoryBitMask = kKXHaloCategory;
  halo.physicsBody.collisionBitMask = kKXEdgeCategory;
  halo.physicsBody.contactTestBitMask = kKXBallCategory | kKXShieldCategory | kKXLifeBarCategory | kKXEdgeCategory;
  
  [_mainLayer addChild:halo];
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
  // We need to figure out what hit what
  SKPhysicsBody *firstBody;
  SKPhysicsBody *secondBody;
  
  if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
    firstBody = contact.bodyA;
    secondBody = contact.bodyB;
  } else {
    firstBody = contact.bodyB;
    secondBody = contact.bodyA;
  }
  
  if (firstBody.categoryBitMask == kKXHaloCategory && secondBody.categoryBitMask == kKXBallCategory) {
    // Collision between halo and ball
    self.score++;
    [self addExplosion:firstBody.node.position withName:@"NewHaloExplosion"];
    [self runAction:_explosionSound];
    
    // Maybe we want to allow this?
    //firstBody.categoryBitMask = 0;
    [firstBody.node removeFromParent];
    [secondBody.node removeFromParent];
  }
  
  if (firstBody.categoryBitMask == kKXHaloCategory && secondBody.categoryBitMask == kKXShieldCategory) {
    // Collision between halo and shield
    [self addShieldExplosion:firstBody.node.position];
    [self runAction:_explosionSound];
    
    // Clear the categoryBitMask so only one shield can be destroyed at a time
    firstBody.categoryBitMask = 0;
    
    [firstBody.node removeFromParent];
    [secondBody.node removeFromParent];
  }
  
  if (firstBody.categoryBitMask == kKXHaloCategory && secondBody.categoryBitMask == kKXLifeBarCategory) {
    // Collision between halo and life bar
    [self addExplosion:secondBody.node.position withName:@"LifeBarExplosion"];
    [self runAction:_deepExplosionSound];
    [secondBody.node removeFromParent];
    
    [self gameOver];
  }
  
  if (firstBody.categoryBitMask == kKXBallCategory && secondBody.categoryBitMask == kKXEdgeCategory) {
    [self addExplosion:contact.contactPoint withName:@"BounceExplosion"];
    [self runAction:_bounceSound];
  }
  
  if (firstBody.categoryBitMask == kKXHaloCategory && secondBody.categoryBitMask == kKXEdgeCategory) {
    if (!_gameOver) {
      [self runAction:_zapSound];
    }
  }
}

- (void) gameOver
{
  [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
    [self addExplosion:node.position withName:@"HaloExplosion"];
    [node removeFromParent];
  }];
  
  [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
    [node removeFromParent];
  }];
  
  [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
    [self addShieldExplosion:node.position];
    [node removeFromParent];
  }];
  
  // Update the score before we show it
  _menu.score = self.score;
  if (self.score > _menu.topScore) {
    _menu.topScore = self.score;
    [_userDefaults setInteger:self.score forKey:kKXKeyTopScore];
    [_userDefaults synchronize];
  }
  
  // Let's see the animation before the menu
  _gameOver = YES;
  _menu.hidden = NO;
  _scoreLabel.hidden = YES;
}

- (void)addExplosion:(CGPoint)position withName:(NSString*)name
{
  // Load the Resource
  NSString *explosionPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
  SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    
  explosion.position = position;
  [_mainLayer addChild:explosion];
  
  SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                   [SKAction removeFromParent]]];
  [explosion runAction:removeExplosion];
}

- (void)addShieldExplosion:(CGPoint)position
{
  SKEmitterNode *explosion = [SKEmitterNode node];
  explosion.particleTexture = [SKTexture textureWithImageNamed:@"spark"];
  
  explosion.particleLifetime = 1;
  explosion.particleBirthRate = 2000;
  explosion.numParticlesToEmit = 100;
  explosion.emissionAngleRange = 360;
  explosion.particleScale = 0.2;
  explosion.particleScaleSpeed = -0.2;
  explosion.particleSpeed = 100;
  
  explosion.position = position;
  [_mainLayer addChild:explosion];
  
  SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                   [SKAction removeFromParent]]];
  [explosion runAction:removeExplosion];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  /* Called when a touch begins */
  
  //for (UITouch *touch in touches) {
  if (!_gameOver) {
    _didShoot = YES;
  }
  //}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  for (UITouch *touch in touches) {
    if (_gameOver) {
      SKNode *node = [_menu nodeAtPoint:[touch locationInNode:_menu]];
      if ([node.name isEqualToString:@"Play"]) {
        [self newGame];
      }
    }
  }
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
  
  [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
    // Test if we're at the bottom of the screen
    if (node.position.y + node.frame.size.height < 0) {
      [node removeFromParent];
    }
  }];
}

@end
