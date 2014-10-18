//
//  KXMenu.h
//  Space Cannon
//
//  Created by Kenneth Wilcox on 10/14/14.
//  Copyright (c) 2014 Kenneth Wilcox. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface KXMenu : SKNode

@property (nonatomic) int score;
@property (nonatomic) int topScore;
@property (nonatomic) BOOL touchable;

- (void)hide;
- (void)show;

@end
