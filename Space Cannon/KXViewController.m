//
//  KXViewController.m
//  Space Cannon
//
//  Created by Kenneth Wilcox on 10/12/14.
//  Copyright (c) 2014 Kenneth Wilcox. All rights reserved.
//

#import "KXViewController.h"
#import "KXMyScene.h"

@implementation KXViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Configure the view.
  SKView * skView = (SKView *)self.view;
  //skView.showsFPS = YES;
  //skView.showsNodeCount = YES;
  
  // Create and configure the scene.
  SKScene * scene = [KXMyScene sceneWithSize:skView.bounds.size];
  scene.scaleMode = SKSceneScaleModeAspectFill;
  
  // Present the scene.
  [skView presentScene:scene];
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

@end
