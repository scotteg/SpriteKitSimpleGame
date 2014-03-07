//
//  MyScene.m
//  SpriteKitSimpleGame
//
//  Created by Scott Gardner on 3/7/14.
//  Copyright (c) 2014 Optimac, Inc. All rights reserved.
//

#import "MyScene.h"
#import "GameOverScene.h"

static const uint32_t kProjectileCategory = 0x1 << 0;
static const uint32_t kMonsterCategory = 0x1 << 1;
static const NSInteger kMonstersToDestroyToWin = 5;

static inline CGPoint rwAdd(CGPoint a, CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint rwSub(CGPoint a, CGPoint b)
{
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint rwMult(CGPoint a, CGFloat b)
{
    return CGPointMake(a.x * b, a.y * b);
}

static inline CGFloat rwLength(CGPoint a)
{
    return sqrtf(a.x * a.x + a.y * a.y);
}

static inline CGPoint rwNormalize(CGPoint a)
{
    CGFloat length = rwLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

@interface MyScene () <SKPhysicsContactDelegate>
@property (strong, nonatomic) SKSpriteNode *player;
@property (assign, nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (assign, nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (assign, nonatomic) NSInteger monstersDestroyed;
@end

@implementation MyScene

- (id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        NSLog(@"Size: %@", NSStringFromCGSize(size));
        self.backgroundColor = [SKColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
        self.player = [SKSpriteNode spriteNodeWithImageNamed:@"player"];
        self.player.position = CGPointMake(CGRectGetWidth(self.player.frame) / 2.0f, CGRectGetMidY(self.frame));
        [self addChild:self.player];
        
        self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f);
        self.physicsWorld.contactDelegate = self;
    }
    
    return self;
}

- (void)addMonster
{
    SKSpriteNode *monster = [SKSpriteNode spriteNodeWithImageNamed:@"monster"];
    SKPhysicsBody *physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:monster.size];
    physicsBody.dynamic = YES;
    physicsBody.categoryBitMask = kMonsterCategory;
    physicsBody.contactTestBitMask = kProjectileCategory;
    physicsBody.collisionBitMask = 0;
    monster.physicsBody = physicsBody;
    
    NSInteger minY = CGRectGetMidY(monster.frame);
    NSInteger maxY = self.frame.size.height - minY;
    NSInteger rangeY = maxY - minY;
    NSInteger actualY = (arc4random() % rangeY) + minY;
    
    NSInteger monsterMidX = CGRectGetMidX(monster.frame);
    
    monster.position = CGPointMake(CGRectGetWidth(self.frame) + monsterMidX, actualY);
    [self addChild:monster];
    
    NSInteger minDuration = 2;
    NSInteger maxDuration = 4;
    NSInteger rangeDuration = maxDuration - minDuration;
    NSInteger actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    SKAction *actionMove = [SKAction moveTo:CGPointMake(-monsterMidX, actualY) duration:actualDuration];
    SKAction *actionMoveDone = [SKAction removeFromParent];
    
//    [monster runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
    SKAction *loseAction = [SKAction runBlock:^{
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:NO];
        [self.view presentScene:gameOverScene transition:reveal];
    }];
    [monster runAction:[SKAction sequence:@[actionMove, loseAction, actionMoveDone]]]; // Actually, actionMoveDone doesn't need to be called
}

- (void)update:(NSTimeInterval)currentTime
{
    CFTimeInterval timeSinceLastUpdate = currentTime - self.lastUpdateTimeInterval;
    
    if (timeSinceLastUpdate > 1.0) {
        timeSinceLastUpdate = 1.0f/60.0f;
    }
    
    self.lastUpdateTimeInterval = currentTime;
    [self updateWithTimeSinceLastUpdate:timeSinceLastUpdate];
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLastUpdate
{
    self.lastSpawnTimeInterval += timeSinceLastUpdate;
    
    if (self.lastSpawnTimeInterval > 1) {
        self.lastSpawnTimeInterval = 0;
        [self addMonster];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self runAction:[SKAction playSoundFileNamed:@"pew-pew-lei.caf" waitForCompletion:NO]];
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    
    SKSpriteNode *projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projectile"];
    projectile.position = self.player.position;
    
    SKPhysicsBody *physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:CGRectGetMidX(projectile.frame)];
    physicsBody.dynamic = YES;
    physicsBody.categoryBitMask = kProjectileCategory;
    physicsBody.contactTestBitMask = kMonsterCategory;
    physicsBody.collisionBitMask = 0;
    physicsBody.usesPreciseCollisionDetection = YES;
    projectile.physicsBody = physicsBody;
    
    CGPoint offset = rwSub(location, projectile.position);
    
    if (offset.x <= 0) return; // Bail out if shooting down or backward
    
    [self addChild:projectile];
    CGPoint direction = rwNormalize(offset);
    
    CGFloat screenWidth = CGRectGetWidth(self.frame);
    CGFloat screenAndProjectileWidth = CGRectGetWidth(self.frame) + CGRectGetWidth(projectile.frame);
    CGPoint shootAmount = rwMult(direction, screenWidth + screenAndProjectileWidth); // Make it shoot off screen
    
    CGPoint realDestination = rwAdd(shootAmount, projectile.position);
    
    CGFloat velocity = 480.0f/1.0f;
    CGFloat realMoveDuration = screenWidth / velocity;
    SKAction *actionMove = [SKAction moveTo:realDestination duration:realMoveDuration];
    SKAction *actionMoveDone = [SKAction removeFromParent];
    [projectile runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
}

- (void)projectile:(SKSpriteNode *)projectile didCollideWithMonster:(SKSpriteNode *)monster
{
    NSLog(@"Hit");
    [projectile removeFromParent];
    [monster removeFromParent];
    self.monstersDestroyed++;
    
    if (self.monstersDestroyed > kMonstersToDestroyToWin) {
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:YES];
        [self.view presentScene:gameOverScene transition:reveal];
    }
}

#pragma mark - SKPhysicsContactDelegate

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if ((firstBody.categoryBitMask & kProjectileCategory) != 0 && (secondBody.categoryBitMask & kMonsterCategory) != 0) {
        [self projectile:(SKSpriteNode *)firstBody.node didCollideWithMonster:(SKSpriteNode *)secondBody.node];
    }
}

@end
