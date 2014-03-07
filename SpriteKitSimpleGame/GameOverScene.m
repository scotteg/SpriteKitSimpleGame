//
//  GameOverScene.m
//  SpriteKitSimpleGame
//
//  Created by Scott Gardner on 3/7/14.
//  Copyright (c) 2014 Optimac, Inc. All rights reserved.
//

#import "GameOverScene.h"
#import "MyScene.h"

@implementation GameOverScene

- (id)initWithSize:(CGSize)size won:(BOOL)won
{
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
        NSString *message = won ? @"You Won!" : @"You Lose :[";
        
        SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        label.text = message;
        label.fontSize = 40.0f;
        label.fontColor = [SKColor blackColor];
        label.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        [self addChild:label];
        
        [self runAction:[SKAction sequence:@[
                                             [SKAction waitForDuration:3.0],
                                             [SKAction runBlock:^{
            SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
            SKScene *myScene = [[MyScene alloc] initWithSize:self.size];
            [self.view presentScene:myScene transition:reveal];
            }]]]];
    }
    
    return self;
}

@end
