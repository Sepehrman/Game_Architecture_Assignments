//====================================================================
//
// (c) Borna Noureddin
// COMP 8051   British Columbia Institute of Technology
// Objective-C++ wrapper for Box2D library
//
//====================================================================

#ifndef MyGLGame_CBox2D_h
#define MyGLGame_CBox2D_h

#import <Foundation/NSObject.h>


// Set up brick and ball physics parameters here:
//   position, width+height (or radius), velocity,
//   and how long to wait before dropping brick

#define PADDLE_POS_X         0
#define PADDLE_POS_Y         0
#define BRICK_WIDTH         8.0f
#define PADDLE_WIDTH         10.0f
// #define BRICK_POS_Y         0
// #define BRICK_WIDTH         20.0f
#define BRICK_HEIGHT        5.0f
#define PADDLE_HEIGHT        3.0f
#define BRICK_WAIT            1.0f
#define BALL_POS_X            0
#define BALL_POS_Y            10
#define BALL_RADIUS            3.0f
#define BALL_VELOCITY        1000.0f

//These parameters dictate the generation for the for loop
#define BRICK_ROW_ITER_START -10 //-10
#define BRICK_ROW_ITER_END 20 //20
#define BRICK_ROW_ITER_STEP 10
#define BRICK_COL_ITER_START 40
#define BRICK_COL_ITER_END 80
#define BRICK_COL_ITER_STEP 10
// Wall Initialization
#define WALL_LEFT_POS_X         -30
#define WALL_LEFT_POS_Y         0
#define WALL_LEFT_WIDTH     1.0f
#define WALL_LEFT_HEIGHT    180.0f

#define WALL_RIGHT_POS_X         30
#define WALL_RIGHT_POS_Y         0
#define WALL_RIGHT_WIDTH     1.0f
#define WALL_RIGHT_HEIGHT    180.0f

#define WALL_TOP_POS_X         0
#define WALL_TOP_POS_Y         90
#define WALL_TOP_WIDTH     61.0f
#define WALL_TOP_HEIGHT    1.0f

#define WALL_BOT_POS_X         0
#define WALL_BOT_POS_Y         -7
#define WALL_BOT_WIDTH     61.0f
#define WALL_BOT_HEIGHT    1.0f


// You can define other object types here
typedef enum { ObjTypeBox=0, ObjTypeCircle=1, WallSideTypeBox=2, WallTopTypeBox=4, WallBotTypeBox=5, PaddleType=6} ObjectType;
enum _entityCategory {
   BALL =          0x0001,
   BOUNDRY =     0x0002,
//   ENEMY_SHIP =        0x0004,
//   FRIENDLY_AIRCRAFT = 0x0008,
//   ENEMY_AIRCRAFT =    0x0010,
//   FRIENDLY_TOWER =    0x0020,
//   RADAR_SENSOR =      0x0040,
 };


// Location of each object in our physics world
struct PhysicsLocation {
    float x, y, theta;
};


// Information about each physics object
struct PhysicsObject {

    struct PhysicsLocation loc; // location
    ObjectType objType;         // type
    void *b2ShapePtr;           // pointer to Box2D shape definition
    void *box2DObj;             // pointer to the CBox2D object for use in callbacks
    char* name;                 // Identifier for each brick to reference from box2d to scenekit
};


// Wrapper class
@interface CBox2D : NSObject

@property (nonatomic) int score;
@property (nonatomic) int remainingBricks;


-(void) HelloWorld; // Basic Hello World! example from Box2D

-(void) LaunchBall;                                                         // launch the ball
-(void) Update:(float)elapsedTime;                                          // update the Box2D engine
-(void) RegisterHit:(const char*)brickHit;                                                        // Register when the ball hits the brick
// -(void) RegisterHit;                                                        // Register when the ball hits the brick
-(void) RegisterBoundryHit;                                                        // Register when the ball hits reset boundry
-(void) AddObject:(char *)name newObject:(struct PhysicsObject *)newObj;    // Add a new physics object
-(struct PhysicsObject *) GetObject:(const char *)name;                     // Get a physics object by name
-(void) Reset;                                                              // Reset Box2D
-(void) movePaddle:(double)offset;

@end

#endif
