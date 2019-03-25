//
//  GameLevelScene.m
//  Base: SuperKoalio
//
//  Base Created by Jake Gundersen on 12/27/13.
//
//  Made by Nick VanCise
//  Metroidvania
//  jun 11 2018
//  this is a game for fun and experience, nothing serious
//  ill give sprite credit in the gameplay when polished


#import "GameLevelScene.h"
#import "GameLevelScene2.h"
#import "SKTUtils.h"
#import "PlayerProjectile.h"
#import "sciserenemy.h"
#import "waver.h"
#import "joystick.h"


@implementation MySlider //created to make a more responsive UISlider
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{//adjust here to adjust the size of the entire slider hit area
  CGRect mybound=CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width+5, self.bounds.size.height+45);
  return CGRectContainsPoint(mybound, point);
}
- (BOOL) beginTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event {
  CGRect bounds = self.bounds;
  float thumbPercent = (self.value - self.minimumValue) / (self.maximumValue - self.minimumValue);
  float thumbPos = [self currentThumbImage].size.height + (thumbPercent * (bounds.size.width+5 - (2 * [self currentThumbImage].size.height)));
  CGPoint touchPoint = [touch locationInView:self];
  return (touchPoint.x >= (thumbPos - 45) && touchPoint.x <= (thumbPos + 25));//adjust where the x pos of your touch falls relative to the slider thumb
}
@end

@implementation GameLevelScene{
  NSString *fintext;
  SKLabelNode *endgamelabel;
  UIButton *_continuebutton,*_replaybutton;
  SKSpriteNode*_pauselabel,*_unpauselabel,*_controlslabel,*_startbutton;
  joystick*myjoystick;
  UITextView *_controlstext;
}

-(instancetype)initWithSize:(CGSize)size {
  self=[super initWithSize:size];
  if (self!=nil) {
    /* Setup scene here */
    //self.view.ignoresSiblingOrder=YES; //for performance optimization every time this class is instanciated
    //self.view.shouldCullNonVisibleNodes=NO; //??? seems to help framerate for now
    
    self.backgroundColor =[SKColor colorWithRed:0.7259 green:0 blue:0.8863 alpha:1.0];
    self.map = [JSTileMap mapNamed:@"level1.tmx"];
    [self addChild:self.map];
    
    self.walls=[self.map layerNamed:@"walls"];
    self.hazards=[self.map layerNamed:@"hazards"];
    self.mysteryboxes=[self.map layerNamed:@"mysteryboxes"];
    
    __weak GameLevelScene *weakself=self;
    self.userInteractionEnabled=NO; //for use with player enter scene
    //player initializiation stuff
    self.player = [[Player alloc] initWithImageNamed:@"samus_standf.png"];
    self.player.position = CGPointMake(100, 150);
    self.player.zPosition = 15;
    
    SKConstraint*plyrconst=[SKConstraint positionX:[SKRange rangeWithLowerLimit:0 upperLimit:(self.map.mapSize.width*self.map.tileSize.width)-33] Y:[SKRange rangeWithUpperLimit:(self.map.tileSize.height*self.map.mapSize.height)-22]];
    plyrconst.referenceNode=self.parent;
    self.player.constraints=@[plyrconst];
    
    [self.map addChild:self.player];
    [self.player runAction:self.player.enterfromportalAnimation completion:^{[weakself.player runAction:[SKAction setTexture:weakself.player.forewards resize:YES]];weakself.userInteractionEnabled=YES;}];
    
    self.player.forwardtrack=YES;
    self.player.backwardtrack=NO;
    
    //camera initialization
    SKCameraNode*mycam=[SKCameraNode new];
    self.camera=mycam;
    [self addChild:mycam];
    SKRange *xrange=[SKRange rangeWithLowerLimit:self.size.width/2 upperLimit:(self.map.mapSize.width*self.map.tileSize.width)-self.size.width/2];
    SKRange *yrange=[SKRange rangeWithLowerLimit:self.size.height/2 upperLimit:(self.map.mapSize.height*self.map.tileSize.height)-self.size.height/2];
    SKConstraint*edgeconstraint=[SKConstraint positionX:xrange Y:yrange];
    self.camera.constraints=@[[SKConstraint distance:[SKRange rangeWithUpperLimit:4] toNode:self.player],edgeconstraint];/*=@[[SKConstraint distance:[SKRange rangeWithConstantValue:0.0] toNode:self.player],edgeconstraint];*/
    
    //health label initialization
    self.healthlabel=[SKLabelNode labelNodeWithFontNamed:@"Marker Felt"];
    self.healthlabel.text=[NSString stringWithFormat:@"Health:%d",self.player.health];
    self.healthlabel.fontSize=15;
    self.healthlabel.zPosition=19;
    self.healthlabel.position=CGPointMake((-4*(self.size.width/10))+3, self.size.height/2-20);
    [self.camera addChild:self.healthlabel];
    
    //health bar initialization
    self.healthbar=[SKSpriteNode spriteNodeWithColor:[UIColor redColor] size:CGSizeMake(200, 20)];
    self.healthbar.zPosition=18;
    self.healthbar.anchorPoint=CGPointMake(0.0, 0.0);
    self.healthbar.position=CGPointMake((-9*(self.size.width/20))-9.5/*self.size.width/20-10*/, self.size.height/2-24);
    [self.camera addChild:self.healthbar];
    _healthbarsize=(double)self.healthbar.size.width;
    
    self.healthbarborder=[SKSpriteNode spriteNodeWithImageNamed:@"healthbarborder.png"];
    self.healthbarborder.anchorPoint=CGPointMake(0.0, 0.0);
    self.healthbarborder.zPosition=19;
    self.healthbarborder.position=CGPointMake((-9*(self.size.width/20))-9.5/*self.size.width/20-10*/, self.size.height/2-24);
    [self.camera addChild:self.healthbarborder];
    
    //gameover buttons/labels
    endgamelabel=[SKLabelNode labelNodeWithFontNamed:@"Marker Felt"];
    endgamelabel.fontSize=40;
    endgamelabel.position=CGPointMake(0,35);
    
    //pause-unpause buttons/labels & pause screen items
    _pauselabel=[SKSpriteNode spriteNodeWithImageNamed:@"pauselabel.png"];
    _pauselabel.position=CGPointMake(0,35);
    _pauselabel.zPosition=18;
    _unpauselabel=[SKSpriteNode spriteNodeWithImageNamed:@"unpauselabel.png"];
    _unpauselabel.position=CGPointMake(0,0);
    _unpauselabel.zPosition=18;
    [_unpauselabel setScale:1.35];
    _controlslabel=[SKSpriteNode spriteNodeWithImageNamed:@"controlslabel.png"];
    _controlslabel.position=CGPointMake(0,-30);
    _controlslabel.zPosition=18;
    
    //portal stuff
    _travelportal=[[TravelPortal alloc] initWithImage:@"travelmirror.png"];
    _travelportal.position=CGPointMake((self.map.mapSize.width * self.map.tileSize.width)-120, 95.0);
    
    //joystick initialization
    myjoystick=[[joystick alloc] initWithPos:CGPointMake(-158.27777099609375, -75)];
    myjoystick.zPosition=18;
    [self.camera addChild:myjoystick];
    
    _startbutton=[SKSpriteNode spriteNodeWithImageNamed:@"startbutton.png"];
    [_startbutton setScale:1.1];
    _startbutton.position=CGPointMake(self.size.width/4+83,self.size.height/2-12);
    _startbutton.zPosition=18;
    [self.camera addChild:_startbutton];
    
    //scene mutable arrays here
    self.bullets=[[NSMutableArray alloc]init];
    self.enemies=[[NSMutableArray alloc]init];
    
    //enemies here
    sciserenemy *enemy=[[sciserenemy alloc] initWithPos:CGPointMake(12.5*self.map.tileSize.width,2.625*self.map.tileSize.height)];
    [self.enemies addObject:enemy];
    [self.map addChild:enemy];
    
    sciserenemy *enemy2=[[sciserenemy alloc] initWithPos:CGPointMake(self.map.mapSize.width * self.map.tileSize.width-400, self.player.position.y-125)];
    [self.enemies addObject:enemy2];
    [self.map addChild:enemy2];
    
    waver*enemy3=[[waver alloc] initWithPosition:CGPointMake(160*self.map.tileSize.width, 8*self.map.tileSize.height)];
    [self.enemies addObject:enemy3];
    [self.map addChild:enemy3];
    
    //door stuff here
    _repeating=NO;
    self.stayPaused=NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setStayPaused) name:@"stayPausedNotification" object:nil];//notification listening for stayPausedNotification
    
  }
  return self;
}

-(void)didMoveToView:(SKView *)view{
  //setup sound
  self.audiomanager=[gameaudio alloc];
  [self.audiomanager runBkgrndMusicForlvl:1];
  
  dispatch_async(dispatch_get_main_queue(), ^{ //deal with certain ui (that could be used immediately) on main thread only
  [self setupVolumeSliderAndReplayAndContinue];
  });
}

-(void)setupVolumeSliderAndReplayAndContinue{//**setup on main thread only**might set call to main thread in this function..
  self.volumeslider=[[MySlider alloc] initWithFrame:CGRectMake(self.view.bounds.size.width*0.746305,self.view.bounds.size.height/2, self.view.bounds.size.width*0.348610, 15.0)];
  
  self.volumeslider.minimumValue=0;
  self.volumeslider.maximumValue=100.0;
  self.volumeslider.continuous=YES;
  self.volumeslider.value=self.audiomanager.currentVolume;
  self.volumeslider.hidden=YES;
  self.volumeslider.minimumTrackTintColor=[UIColor redColor];
  self.volumeslider.maximumTrackTintColor=[UIColor darkGrayColor];
  [self.volumeslider setThumbImage:[UIImage imageNamed:@"supermetroid_sliderbar.png"] forState:UIControlStateNormal];
  [self.volumeslider setTransform:CGAffineTransformRotate(self.volumeslider.transform, M_PI_2)];
  [self.volumeslider setBackgroundColor:[UIColor clearColor]];
  [self.volumeslider addTarget:self action:@selector(slideraction:) forControlEvents:UIControlEventValueChanged];
  [self.view addSubview:self.volumeslider];
  
  _replaybutton=[UIButton buttonWithType:UIButtonTypeCustom]; //replay button
  _replaybutton.tag=666;
  UIImage *replayimage=[UIImage imageNamed:@"replay"];
  [_replaybutton setImage:replayimage forState:UIControlStateNormal];
  [_replaybutton addTarget:self action:@selector(replaybuttonpush:) forControlEvents:UIControlEventTouchUpInside];
  _replaybutton.frame=CGRectMake(self.view.bounds.size.width/2.0-replayimage.size.width/2, self.view.bounds.size.height/2.0-replayimage.size.height/1.5, replayimage.size.width, replayimage.size.height);
  
  _continuebutton=[UIButton buttonWithType:UIButtonTypeCustom]; //continue button
  _continuebutton.tag=888;
  UIImage *continueimage=[UIImage imageNamed:@"continuebutton.png"];
  [_continuebutton setImage:continueimage forState:UIControlStateNormal];
  [_continuebutton addTarget:self action:@selector(continuebuttonpush:) forControlEvents:UIControlEventTouchUpInside];
  _continuebutton.frame=CGRectMake(self.view.bounds.size.width/2.0-continueimage.size.width/2/*/4.0-15*/, self.view.bounds.size.height/2.0-continueimage.size.height/1.5/*4.0+7*/, continueimage.size.width, continueimage.size.height);
  
  _controlstext=[[UITextView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2-(self.view.bounds.size.width*0.7)/2/*/4.0-15*/, self.view.bounds.size.height/4/*4.0+7*/, self.view.bounds.size.width*0.7,self.view.bounds.size.height/2)/*CGRectMake(0, 0, self.size.width/4, self.size.height/4)*/];
  _controlstext.scrollEnabled=YES;
  _controlstext.editable=NO;
  [_controlstext setFont:[UIFont systemFontOfSize:16]];
  _controlstext.backgroundColor=[UIColor darkGrayColor];
  _controlstext.textColor=[UIColor whiteColor];
  _controlstext.text=@"Use the joystick to move around by sliding your finger,\nit is 5 directional allowing you to jump and move foreward or backwards at the same time,\n\nTap the upper right half of the screen to melee\n\nTap the lower right half of the screen to fire your weapon\n\nRemember, one touch at a time, but two fingers to fire are fair game!\n\nHealth Boxes are in all levels, look for the unusual ones\n\nEnemies Guide:\nScisser: melee or fire to kill,\n\nHoneypot (walking cactus): melee or fire to kill, green projectiles means you can damage them with melee, red means they are invincible,\n\nWavers: melee or fire to kill, or simply keep your distance.";
}

-(void)willMoveFromView:(SKView *)view{
  //NSLog(@"moving from view");
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)update:(NSTimeInterval)currentTime{
  
  if(self.gameOver || self.stayPaused)
    return;
  
  NSTimeInterval delta=currentTime-self.storetime;
  
  if(delta>0.2)
    delta=0.2;
  
  self.storetime=currentTime;
  self.delta=delta;
  
  [self.player update:delta];
  
  //do collision detection calls here
  
  [self checkAndResolveCollisionsForPlayer];
  
  [self handleBulletEnemyCollisions];
}



-(NSInteger)tileGIDAtTileCoord:(CGPoint)tilecoordinate forLayer:(TMXLayer *)fnclayer{
  @autoreleasepool{
  TMXLayerInfo *currinfo=fnclayer.layerInfo;
  return [currinfo tileGidAtCoord:tilecoordinate];
  }
}



-(CGRect)tileRectFromTileCoords:(CGPoint)fnccoordinate{
  float levelheightinpixels=self.map.mapSize.height * self.map.tileSize.height;
  
  CGPoint origin=CGPointMake(fnccoordinate.x * self.map.tileSize.width, levelheightinpixels - ((fnccoordinate.y+1)* self.map.tileSize.height));
  
  return CGRectMake(origin.x, origin.y, self.map.tileSize.width,self.map.tileSize.height);
}



-(void)checkAndResolveCollisionsForPlayer{
  
  NSInteger tileindecies[8]={7,1,3,5,0,2,6,8};
  self.player.onGround=NO;
  
  
  for(NSInteger i=0;i<8;i++){
    NSInteger tileindex=tileindecies[i];
    
    CGRect playerrect=[self.player collisionBoundingBox];
    CGPoint playercoordinate=[self.walls coordForPoint:self.player.desiredPosition];
    
  
    if(playercoordinate.y >= self.map.mapSize.height-1 ){ //sets gameover if you go below the bottom of the maps y max-1
      [self gameOver:0];
      return;
    }
    if(self.player.position.x>=(self.map.mapSize.width*self.map.tileSize.width)-220 && !_repeating){
      [self.map addChild:_travelportal];
      _repeating=YES;
    }
    if(_travelportal!=NULL && CGRectIntersectsRect(CGRectInset(playerrect,4,6),[_travelportal collisionBoundingBox])){      
      [self.player runAction:[SKAction moveTo:_travelportal.position duration:1.5] completion:^{[self gameOver:1];}];
      return;
    }
    
    
    
    NSInteger tilecolumn=tileindex%3; //this is how array of coordinates around player is navigated
    NSInteger tilerows=tileindex/3;   //using a 3X3 grid
    
    CGPoint tilecoordinate=CGPointMake(playercoordinate.x+(tilecolumn-1), playercoordinate.y+(tilerows-1));
    
    NSInteger thetileGID=[self tileGIDAtTileCoord:tilecoordinate forLayer:self.walls];
    NSInteger hazardtilegid=[self tileGIDAtTileCoord:tilecoordinate forLayer:self.hazards];
    NSInteger mysteryboxgid=[self tileGIDAtTileCoord:tilecoordinate forLayer:self.mysteryboxes];
    
  
    if(thetileGID !=0 || mysteryboxgid!=0){
      CGRect tilerect=[self tileRectFromTileCoords:tilecoordinate];
      //NSLog(@"TILE GID: %ld Tile coordinate: %@ Tile rect: %@ Player Rect: %@",(long)thetileGID,NSStringFromCGPoint(tilecoordinate),NSStringFromCGRect(tilerect),NSStringFromCGRect(playerrect));
      //collision detection here
      
      if(CGRectIntersectsRect(playerrect, tilerect)){
        CGRect pl_tl_intersection=CGRectIntersection(playerrect, tilerect); //distance of intersection where player and tile overlap
        
        if(tileindex==7){
          //tile below the sprite
          self.player.desiredPosition=CGPointMake(self.player.desiredPosition.x, self.player.desiredPosition.y+pl_tl_intersection.size.height);
          
          self.player.playervelocity=CGPointMake(self.player.playervelocity.x, 0.0);
          self.player.onGround=YES;
        }
        else if(tileindex==1){
          //tile above the sprite
          if(mysteryboxgid!=0){
            //NSLog(@"hit a mysterybox!!");
            [self.mysteryboxes removeTileAtCoord:tilecoordinate];
            [self hitHealthBox]; //adjusts player healthlabel/healthbar
          }
          else{
          self.player.desiredPosition=CGPointMake(self.player.desiredPosition.x, self.player.desiredPosition.y-pl_tl_intersection.size.height);
          self.player.playervelocity=CGPointMake(self.player.playervelocity.x, 0.0);
          }
        }
        else if(tileindex==3){
          //tile back left of sprite
          self.player.desiredPosition=CGPointMake(self.player.desiredPosition.x+pl_tl_intersection.size.width, self.player.desiredPosition.y);
        }
        else if(tileindex==5){
          //tile front right of sprite
          self.player.desiredPosition=CGPointMake(self.player.desiredPosition.x-pl_tl_intersection.size.width, self.player.desiredPosition.y);
        }
        else{
          if(pl_tl_intersection.size.width>pl_tl_intersection.size.height){
            //this is for resolving collision up or down due to ^
            float intersectionheight;
            if(thetileGID!=0){
            self.player.playervelocity=CGPointMake(self.player.playervelocity.x, 0.0);
            }
            
            if(tileindex>4){
              intersectionheight=pl_tl_intersection.size.height;
              self.player.onGround=YES;
            }
            else
              intersectionheight=-pl_tl_intersection.size.height;
            
            self.player.desiredPosition=CGPointMake(self.player.desiredPosition.x, self.player.desiredPosition.y+intersectionheight);
          }
          else{
            //this is for resolving collisions left or right due to ^
            float intersectionheight;
            
            if(tileindex==0 || tileindex==6)
              intersectionheight=pl_tl_intersection.size.width;
            else
              intersectionheight=-pl_tl_intersection.size.width;
            
            self.player.desiredPosition=CGPointMake(self.player.desiredPosition.x+intersectionheight, self.player.desiredPosition.y);
          }
          
        }
      }
    }//if thetilegid bracket
    
    if(hazardtilegid!=0){//for hazard layer
      CGRect hazardtilerect=[self tileRectFromTileCoords:tilecoordinate];
      if(CGRectIntersectsRect(CGRectInset(playerrect, 1, 0), hazardtilerect)){
        [self damageRecievedMsg];
        if(self.player.health<=0){
          [self gameOver:0];
        }
      }//if rects intersect
    }//if hazard tile
    
    
    
  }//for loop bracket
  self.player.position=self.player.desiredPosition;
}//fnc bracket



-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
  
  if(self.gameOver || self.player.meleeinaction)
    return;
  
  
  for(UITouch *touch in touches){
    //NSLog(@"touchbegan");
    CGPoint touchlocation=[touch locationInNode:self.camera];  //location of the touch
    [myjoystick moveFingertrackerto:touchlocation];
    //start delegating parts of the screen to specific movements
    
    if(self.paused && CGRectContainsPoint(_unpauselabel.frame, touchlocation)) //check for unpause/related pause items
      [self unpausegame];
    else if(self.paused && CGRectContainsPoint(_controlslabel.frame, touchlocation))
      [self displaycontrolstext];
    else if(self.paused && _controlstext.superview!=nil)
        [_controlstext removeFromSuperview];
    else if(self.paused)//loop if paused above here
      return;
    else if(CGRectContainsPoint(_startbutton.frame, touchlocation)){
      //[self.startbutton runAction:[SKAction colorizeWithColor:[UIColor darkGrayColor] colorBlendFactor:0.8 duration:0.05] completion:^{NSLog(@"coloringstart");
      [self pausegame];
    }
    else if([myjoystick shouldGoForeward:touchlocation]){
      //NSLog(@"touching right control");
      self.player.goForeward=YES;
      
      self.player.forwardtrack=YES;
      self.player.backwardtrack=NO;
      
      [self.player runAction:self.player.runAnimation withKey:@"runf"];
    }
    else if([myjoystick shouldGoBackward:touchlocation]){
      //NSLog(@"touching left control");
      self.player.goBackward=YES;
      
      self.player.backwardtrack=YES;
      self.player.forwardtrack=NO;
      
      [self.player runAction:self.player.runBackwardsAnimation withKey:@"runb"];
    }
    else if([myjoystick shouldJump:touchlocation]){
      self.player.shouldJump=YES;
      if(self.player.forwardtrack)
        [self.player runAction:self.player.jumpForewardsAnimation withKey:@"jmpf"];
      else
        [self.player runAction:self.player.jumpBackwardsAnimation withKey:@"jmpb"];
    }
    else if([myjoystick shouldJumpForeward:touchlocation]){
      self.player.shouldJump=YES;
      self.player.goForeward=YES;
      self.player.forwardtrack=YES;
      self.player.backwardtrack=NO;
      [self.player runAction:self.player.jumpForewardsAnimation withKey:@"jmpf"];
    }
    else if([myjoystick shouldJumpBackward:touchlocation]){
      self.player.shouldJump=YES;
      self.player.goBackward=YES;
      self.player.backwardtrack=YES;
      self.player.forwardtrack=NO;
      [self.player runAction:self.player.jumpBackwardsAnimation withKey:@"jmpb"];
    }
    else if(touchlocation.x>self.camera.frame.size.width/2 && touchlocation.y<self.camera.frame.size.height/2){
      //call build projectile/set it going right ->
       //NSLog(@"start charge timer");
      if(![self.player actionForKey:@"chargeT"])
        [self.player runAction:self.player.chargebeamtimer withKey:@"chargeT"];
      /*if(self.player.forwardtrack)
        [self firePlayerProjectilewithdirection:TRUE];
      else
        [self firePlayerProjectilewithdirection:FALSE];*/
    }
    
  
  }//uitouch iteration end
}//function end



-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{ //need to modify to fit ^v asap
  
  if(self.gameOver || self.paused || self.player.meleeinaction)
    return;
  
  //NSLog(@"Touch is moving");
  for(UITouch *touch in touches){
    CGPoint currtouchlocation=[touch locationInNode:self.camera];
    CGPoint previoustouchlocation=[touch previousLocationInNode:self.camera];
    [myjoystick moveFingertrackerto:currtouchlocation];
    if((currtouchlocation.x<self.camera.frame.size.width/2 || currtouchlocation.y>self.camera.frame.size.height/2) && [self.player actionForKey:@"chargeT"]){//remove charge beam & related timer
      //NSLog(@"removign  chargeT");
      [self.player removeActionForKey:@"chargeT"];
    }
    if(currtouchlocation.x>self.camera.frame.size.width/2 && (previoustouchlocation.x<=self.camera.frame.size.width/2)){//this code to disable
      //NSLog(@"moving to firing weapon");                                                                                  //movement and animations
      self.player.shouldJump=NO;                                                                                           //when fire/melee area is
      self.player.goForeward=NO;                                                                                           //accessed
      self.player.goBackward=NO;
      [self.player removeMovementAnims];
      if(self.player.forwardtrack)
        [self.player runAction:[SKAction setTexture:self.player.forewards resize:YES]];
      else if(self.player.backwardtrack)
        [self.player runAction:[SKAction setTexture:self.player.backwards resize:YES]];
    }
    else if([myjoystick shouldJump:currtouchlocation] && [myjoystick shouldGoForeward:previoustouchlocation]){
      //NSLog(@"moving from move right to jumping");
      self.player.shouldJump=YES;
      self.player.goForeward=NO;
      
      [self.player runAction:self.player.jumpForewardsAnimation withKey:@"jmpf"];
      [self.player runAction:[SKAction repeatActionForever:self.player.jmptomfmbcheck] withKey:@"jmpblk"];
      [self.player removeActionForKey:@"runf"];
    }
    else if([myjoystick shouldJumpForeward:currtouchlocation] && [myjoystick shouldGoForeward:previoustouchlocation]){
      //NSLog(@"moving from move right to jmpfwd");
      self.player.shouldJump=YES;
      
      [self.player runAction:self.player.jumpForewardsAnimation withKey:@"jmpf"];
      [self.player runAction:[SKAction repeatActionForever:self.player.jmptomfmbcheck] withKey:@"jmpblk"];
      [self.player removeActionForKey:@"runf"];
    }
    else if([myjoystick shouldJump:currtouchlocation] && [myjoystick shouldGoBackward:previoustouchlocation]){
      //NSLog(@"moving from move backward to jumping");
      self.player.shouldJump=YES;
      self.player.goBackward=NO;
      
      [self.player runAction:self.player.jumpBackwardsAnimation withKey:@"jmpb"];
      [self.player runAction:[SKAction repeatActionForever:self.player.jmptomfmbcheck] withKey:@"jmpblk"];
      [self.player removeActionForKey:@"runb"];
    }
    else if([myjoystick shouldJumpBackward:currtouchlocation] && [myjoystick shouldGoBackward:previoustouchlocation]){
      //NSLog(@"moving from move backward to jmpbkwd");
      self.player.shouldJump=YES;
      
      [self.player runAction:self.player.jumpBackwardsAnimation withKey:@"jmpb"];
      [self.player runAction:[SKAction repeatActionForever:self.player.jmptomfmbcheck] withKey:@"jmpblk"];
      [self.player removeActionForKey:@"runb"];
    }
    else if([myjoystick shouldGoForeward:currtouchlocation] && [myjoystick shouldGoBackward:previoustouchlocation]){
      //NSLog(@"moving from move backward to move right");
      self.player.goForeward=YES;
      self.player.goBackward=NO;
      
      self.player.forwardtrack=YES;
      self.player.backwardtrack=NO;
      
      [self.player runAction:self.player.runAnimation withKey:@"runf"];
      [self.player removeActionForKey:@"runb"];
    }
    else if([myjoystick shouldGoForeward:currtouchlocation] && [myjoystick shouldJump:previoustouchlocation]){
      //NSLog(@"move up to move right");
      self.player.goForeward=YES;
      self.player.goBackward=NO;
      self.player.shouldJump=NO;
      
      self.player.forwardtrack=YES;
      self.player.backwardtrack=NO;
      
      if([self.player actionForKey:@"jmpb"]){
        [self.player runAction:self.player.jumpForewardsAnimation withKey:@"jmpf"];
        [self.player removeActionForKey:@"jmpb"];
        [self.player runAction:[SKAction repeatActionForever:self.player.jmptomfmbcheck] withKey:@"jmpblk"];
      }

    }
    else if([myjoystick shouldGoForeward:currtouchlocation] && [myjoystick shouldJumpForeward:previoustouchlocation]){
      //NSLog(@"moving from jmpfwd to move right");
      self.player.shouldJump=NO;
      
      self.player.forwardtrack=YES;
      self.player.backwardtrack=NO;
      
      [self.player runAction:[SKAction repeatActionForever:self.player.jmptomfmbcheck] withKey:@"jmpblk"];
    }
    else if([myjoystick shouldGoForeward:currtouchlocation] && [myjoystick shouldJumpBackward:previoustouchlocation]){
      //NSLog(@"moving from jmpbkwd to move right");
      self.player.shouldJump=NO;
      self.player.goForeward=YES;
      self.player.goBackward=NO;
      
      self.player.forwardtrack=YES;
      self.player.backwardtrack=NO;
      
      [self.player runAction:self.player.runAnimation withKey:@"runf"];
      [self.player removeActionForKey:@"jmpb"];
    }
    else if([myjoystick shouldGoBackward:currtouchlocation] && [myjoystick shouldGoForeward:previoustouchlocation]){
      //NSLog(@"move right to movebackwards");
      self.player.goBackward=YES;
      self.player.goForeward=NO;
      
      self.player.backwardtrack=YES;
      self.player.forwardtrack=NO;
      
      [self.player runAction:self.player.runBackwardsAnimation withKey:@"runb"];
      [self.player removeActionForKey:@"runf"];
    }
    else if([myjoystick shouldGoBackward:currtouchlocation] && [myjoystick shouldJump:previoustouchlocation]){
      //NSLog(@"move up to movebackwards");
      self.player.goBackward=YES;
      self.player.goForeward=NO;
      self.player.shouldJump=NO;
      
      self.player.backwardtrack=YES;
      self.player.forwardtrack=NO;
      
      if([self.player actionForKey:@"jmpf"]){
        [self.player runAction:self.player.jumpBackwardsAnimation withKey:@"jmpb"];
        [self.player removeActionForKey:@"jmpf"];
        [self.player runAction:[SKAction repeatActionForever:self.player.jmptomfmbcheck] withKey:@"jmpblk"];
      }
      
    }
    else if([myjoystick shouldGoBackward:currtouchlocation] && [myjoystick shouldJumpBackward:previoustouchlocation]){
      //NSLog(@"moving from jmpbkwd to move backwards");
      self.player.goBackward=YES;
      self.player.shouldJump=NO;
      
      self.player.backwardtrack=YES;
      self.player.forwardtrack=NO;
      
      [self.player runAction:[SKAction repeatActionForever:self.player.jmptomfmbcheck] withKey:@"jmpblk"];
    }
    else if([myjoystick shouldGoBackward:currtouchlocation] && [myjoystick shouldJumpForeward:previoustouchlocation]){
      //NSLog(@"moving from jmpfwd to move backwards");
      self.player.shouldJump=NO;
      self.player.goBackward=YES;
      self.player.goForeward=NO;
      
      self.player.backwardtrack=YES;
      self.player.forwardtrack=NO;
      
      [self.player runAction:self.player.runBackwardsAnimation withKey:@"runb"];
      [self.player removeActionForKey:@"jmpf"];
    }
    else if([myjoystick shouldJumpForeward:currtouchlocation] && [myjoystick shouldJump:previoustouchlocation]){
      //NSLog(@"moving from jump to jmpfwd");
      self.player.goForeward=YES;
      self.player.goBackward=NO;
      
      self.player.forwardtrack=YES;
      self.player.backwardtrack=NO;
      
      if([self.player actionForKey:@"jmpb"]){
      //NSLog(@"change jump");
      [self.player runAction:self.player.jumpForewardsAnimation withKey:@"jmpf"];
      [self.player removeActionForKey:@"jmpb"];
      [self.player runAction:[SKAction repeatActionForever:self.player.jmptomfmbcheck] withKey:@"jmpblk"];
      }
    }
    else if([myjoystick shouldJumpBackward:currtouchlocation] && [myjoystick shouldJump:previoustouchlocation]){
      //NSLog(@"moving from jump to jumpbkwd");
      self.player.goBackward=YES;
      self.player.goForeward=NO;
      
      self.player.backwardtrack=YES;
      self.player.forwardtrack=NO;
      
      if([self.player actionForKey:@"jmpf"]){
      //NSLog(@"change jump");
      [self.player runAction:self.player.jumpBackwardsAnimation withKey:@"jmpb"];
      [self.player removeActionForKey:@"jmpf"];
      [self.player runAction:[SKAction repeatActionForever:self.player.jmptomfmbcheck] withKey:@"jmpblk"];
      }
    }
  
  }//for uitouch bracket
}//fnc bracket


-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

  if(self.gameOver || self.paused)
    return;
  if(self.player.meleeinaction){
    self.player.shouldJump=NO;//disable player movement
    self.player.goForeward=NO;
    self.player.goBackward=NO;
    [self.player removeMovementAnims];//remove player animations/other side effects ex jmpblk/charge beam timer
    return;
  }
  
  for(UITouch *touch in touches){
  CGPoint fnctouchlocation=[touch locationInNode:self.camera];
    [myjoystick resetFingertracker];   //these movements must be NO after every touch finishes
    self.player.goForeward=NO;         //initial solution for fixing sticky buttons
    self.player.goBackward=NO;
    self.player.shouldJump=NO;
    [self.player removeMovementAnims];
    
    if([myjoystick shouldJump:fnctouchlocation] || [myjoystick shouldJumpBackward:fnctouchlocation] || [myjoystick shouldJumpForeward:fnctouchlocation]){
      //NSLog(@"done touching up");
      if(self.player.backwardtrack)
        [self.player runAction:[SKAction setTexture:self.player.backwards resize:YES]];
      else
        [self.player runAction:[SKAction setTexture:self.player.forewards resize:YES]];
    }
    else if([myjoystick shouldGoForeward:fnctouchlocation]){
      //NSLog(@"done touching right");
      self.player.forwardtrack=YES;
      self.player.backwardtrack=NO;
      [self.player runAction:[SKAction setTexture:self.player.forewards resize:YES]];
    }
    else if([myjoystick shouldGoBackward:fnctouchlocation]){
      //NSLog(@"done touching left");
      self.player.backwardtrack=YES;
      self.player.forwardtrack=NO;
      [self.player runAction:[SKAction setTexture:self.player.backwards resize:YES]];
    }
    else if(CGRectContainsPoint(_startbutton.frame, fnctouchlocation)){
      //NSLog(@"do nothing hit the pause");//put here so the melee is not hit
    }
    else if(fnctouchlocation.x>self.camera.frame.size.width/2 && fnctouchlocation.y<self.camera.frame.size.height/2){
      //call build projectile/set it going right ->
      if(self.player.forwardtrack)
        [self firePlayerProjectilewithdirection:TRUE];
      else
        [self firePlayerProjectilewithdirection:FALSE];
     // NSLog(@"start firing weapon");
    }
    else if(fnctouchlocation.x>self.camera.frame.size.width/2 && fnctouchlocation.y>self.camera.frame.size.height/2){
      [self.player runAction:self.player.meleeactionright withKey:@"melee"];
    }
  
    
  }
}
-(void)firePlayerProjectilewithdirection:(BOOL)direction{
  PlayerProjectile *newProjectile=[[PlayerProjectile alloc] initWithPos:self.player.position andMag_Range:self.player.currentBulletRange andType:self.player.currentBulletType andDirection:direction];
  newProjectile.zPosition=16;
  [self.map addChild:newProjectile];
  [self.bullets addObject:newProjectile];
  //NSLog(@"adding projectile,count:%d",(int)self.bullets.count);
}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{//maybe need to add for touch in touches
  NSLog(@"recieved CANCELED touch");
  [self.player removeMovementAnims];
  self.player.goForeward=NO;
  self.player.goBackward=NO;
  self.player.shouldJump=NO;
}

-(void)handleBulletEnemyCollisions{ //switch this to ise id in fast enumeration so as to keep 1 enemy arr with multiple enemy types
  
  for(id enemycon in [self.enemies reverseObjectEnumerator]){
    
    if([enemycon isKindOfClass:[sciserenemy class]]){
      sciserenemy*enemyconcop=(sciserenemy*)enemycon;
      if(fabs(self.player.position.x-enemyconcop.position.x)<70){  //minimize comparisons
        //NSLog(@"in here");
        if(CGRectContainsPoint(self.player.collisionBoundingBox, CGPointAdd(enemyconcop.enemybullet1.position, enemyconcop.position))){
          //NSLog(@"enemy hit player bullet#1");
          [enemyconcop.enemybullet1 setHidden:YES];
          [self enemyhitplayerdmgmsg:25];
        }
        else if(CGRectContainsPoint(self.player.collisionBoundingBox,CGPointAdd(enemyconcop.enemybullet2.position, enemyconcop.position))){
          //NSLog(@"enemy hit player buller#2");
          [enemyconcop.enemybullet2 setHidden:YES];
          [self enemyhitplayerdmgmsg:25];
        }
        if(self.player.meleeinaction && !self.player.meleedelay && CGRectIntersectsRect([self.player meleeBoundingBoxNormalized],enemyconcop.frame)){
          //NSLog(@"meleehit");
          [self.player runAction:self.player.meleedelayac];
          [enemyconcop hitByMeleeWithArrayToRemoveFrom:self.enemies];
        }
      }
    }
    else if([enemycon isKindOfClass:[waver class]]){
      waver*enemyconcop=(waver*)enemycon;
      [enemyconcop updateWithDeltaTime:self.delta andPlayerpos:self.player.position];
      if(fabs(self.player.position.x-enemyconcop.position.x)<40 && fabs(self.player.position.y-enemyconcop.position.y)<60 && !enemyconcop.attacking){
        [enemyconcop attack];
      }
      if(CGRectIntersectsRect(self.player.frame,CGRectInset(enemyconcop.frame,2,0))){
        [self enemyhitplayerdmgmsg:15];
      }
      if(self.player.meleeinaction && !self.player.meleedelay && CGRectIntersectsRect([self.player meleeBoundingBoxNormalized],enemyconcop.frame)){
        //NSLog(@"meleehit");
        [self.player runAction:self.player.meleedelayac];
        [enemyconcop hitByMeleeWithArrayToRemoveFrom:self.enemies];
      }
    }
  }
  
  
  for(PlayerProjectile *currbullet in [self.bullets reverseObjectEnumerator]){
    if(currbullet.cleanup || [self tileGIDAtTileCoord:[self.walls coordForPoint:currbullet.position] forLayer:self.walls]){//here to avoid another run through of arr
      //NSLog(@"removing from array");
      [currbullet removeAllActions];
      [currbullet removeFromParent];
      [self.bullets removeObject:currbullet];
      continue;//avoid comparing with removed bullet
    }
    
    for(id enemyl in self.enemies){
      //NSLog(@"bullet frame:%@",NSStringFromCGRect(currbullet.frame));
        enemyBase*enemylcop=(enemyBase*)enemyl;
        if(CGRectIntersectsRect(CGRectInset(enemylcop.frame,5,0), currbullet.frame) && !enemylcop.dead){
          //NSLog(@"hit an enemy");
          [enemylcop hitByBulletWithArrayToRemoveFrom:self.enemies];
          [currbullet removeAllActions];
          [currbullet removeFromParent];
          [self.bullets removeObject:currbullet];
          break; //if bullet hits enemy stop checking for same bullet
        
      }
    }
  }//for currbullet
  
 
}

-(void)damageRecievedMsg{
  
  --self.player.health;
  self.healthlabel.text=[NSString stringWithFormat:@"Health:%d",self.player.health];
  self.healthbar.size=CGSizeMake((((float)self.player.health/100)*_healthbarsize), self.healthbar.size.height);
  
}
-(void)enemyhitplayerdmgmsg:(int)hit{
  if(!self.player.plyrrecievingdmg){
  self.player.plyrrecievingdmg=YES;
  self.player.health=self.player.health-hit;
  if(self.player.health<=0 && !self.gameOver){
    self.player.health=0;
    [self gameOver:0];
  }
  self.healthlabel.text=[NSString stringWithFormat:@"Health:%d",self.player.health];
  self.healthbar.size=CGSizeMake((((float)self.player.health/100)*_healthbarsize), self.healthbar.size.height);
  
  [self.player runAction:[SKAction group:@[self.player.plyrdmgwaitlock,[SKAction repeatAction:self.player.damageaction count:15]]]];
  }
}

-(void)pausegame{
  //NSLog(@"game paused");
  //[self.startbutton runAction:[SKAction colorizeWithColor:[UIColor darkGrayColor] colorBlendFactor:0.8 duration:0.05] completion:^{NSLog(@"coloringstart");}];
  //[self.view addSubview:_controlstext];
  //[self.view bringSubviewToFront:_controlstext];
  [self.camera addChild:_pauselabel];
  [self.camera addChild:_unpauselabel];
  [self.camera addChild:_controlslabel];
  self.volumeslider.hidden=NO;
  self.paused=YES;
  self.player.playervelocity=CGPointMake(0,18);
}
-(void)unpausegame{
  //[self.startbutton runAction:[SKAction colorizeWithColorBlendFactor:0.0 duration:0.05] completion:^{NSLog(@"uncoloringstart");}];
  [_pauselabel removeFromParent];
  [_unpauselabel removeFromParent];
  [_controlslabel removeFromParent];
  self.volumeslider.hidden=YES;
  
  self.paused=NO;
}
-(void)displaycontrolstext{
  [self.view addSubview:_controlstext];
  [self.view bringSubviewToFront:_controlstext];
}

-(void)setStayPaused{//for use to keep the scene paused while returning from background
  //NSLog(@"staying paused");
  self.stayPaused=YES;
  [self unpausegame];
  GameLevelScene*weakself=self;
  [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.05],[SKAction runBlock:^{[weakself pausegame];}]]] completion:^{weakself.stayPaused=NO;}];
}

-(void)slideraction:(id)sender{
  UISlider*tmpslider=(UISlider*)sender;
  self.audiomanager.bkgrndmusic.volume=tmpslider.value/100;
  self.audiomanager.currentVolume=tmpslider.value;
}

-(void) gameOver:(BOOL)didwin{
  
  self.gameOver=YES;
  [self.player removeAllActions];
  if(self.player.forwardtrack)
    [self.player runAction:[SKAction setTexture:self.player.forewards resize:YES]];
  else
    [self.player runAction:[SKAction setTexture:self.player.backwards resize:YES]];
  
  if(didwin){
    fintext=@"You Won!";
    endgamelabel.text=fintext;
    __weak SKLabelNode *weakendgamelabel=endgamelabel;
    __weak UIButton *weakcontinuebutton=_continuebutton;
    [self.player runAction:self.player.travelthruportalAnimation completion:^{[self.camera addChild:weakendgamelabel];[self.view addSubview:weakcontinuebutton];}];
  }
  else{
    fintext=@"You Died :(";
  //label setup for end of game message
  endgamelabel.text=fintext;
  [self.camera addChild:endgamelabel];
  [self.view addSubview:_replaybutton];
  }
}
-(void)replaybuttonpush:(id)sender{
  [[self.view viewWithTag:666] removeFromSuperview];
  [self.view presentScene:[[GameLevelScene alloc] initWithSize:self.size]];
  [gameaudio pauseSound:self.audiomanager.bkgrndmusic];
}
-(void)continuebuttonpush:(id)sender{
  [[self.view viewWithTag:888] removeFromSuperview];
  __weak GameLevelScene*weakself=self;
  [SKTextureAtlas preloadTextureAtlasesNamed:@[@"honeypot",@"Arachnus"] withCompletionHandler:^(NSError*error,NSArray*foundatlases){
      GameLevelScene2*preload=[[GameLevelScene2 alloc]initWithSize:weakself.size];
      preload.scaleMode = SKSceneScaleModeAspectFill;
        NSLog(@"preloaded lvl2");
        [weakself.view presentScene:preload];
    }];
  [gameaudio pauseSound:self.audiomanager.bkgrndmusic];
}


-(void)hitHealthBox{
  
  self.player.health+=10; //reward for hitting mystery box
  if(self.player.health>100){
    self.player.health=100;
  }
  
  self.healthlabel.text=[NSString stringWithFormat:@"Health:%d",self.player.health];
  self.healthbar.size=CGSizeMake((((float)self.player.health/100)*_healthbarsize), self.healthbar.size.height);
}

/*-(void)dealloc {
  NSLog(@"LVL1 SCENE DEALLOCATED");
}*/

@end
