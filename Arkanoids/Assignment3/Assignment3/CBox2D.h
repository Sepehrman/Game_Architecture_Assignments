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

#define BRICK_POS_X         -55
#define BRICK_POS_Y         90
#define BRICK_COLS          10
#define BRICK_ROWS          3
#define BRICK_PADDING_X     1.0f
#define BRICK_PADDING_Y     1.0f
#define BRICK_WIDTH         10.0f
#define BRICK_HEIGHT        5.0f
#define BRICK_WAIT            1.0f
#define PADDLE_POS_X          0
#define PADDLE_POS_Y          10
#define PADDLE_WIDTH        20.0f
#define PADDLE_HEIGHT       5.0f
#define BALL_POS_X            0
#define BALL_POS_Y            5
#define BALL_RADIUS            3.0f
#define BALL_VELOCITY        2000.0f
#define WALL_LENGTH          200.0f
#define WALL_THICKNESS       5.0f
#define WALL_X_OFFSET        82.5f
#define CEILING_Y_POS        100
#define BALL_LIVES           3


// You can define other object types here
typedef enum { ObjTypeBox=0, ObjTypeCircle=1, ObjTypePaddle = 2, ObjTypeWall = 3, ObjTypeEndZone = 4} ObjectType;

// Location of each object in our physics world
struct PhysicsLocation {
    float x, y, theta;
};


// Information about each physics object
struct PhysicsObject {

    struct PhysicsLocation loc; // location
    char* name;                 // name
    ObjectType objType;         // type
    void *b2ShapePtr;           // pointer to Box2D shape definition
    void *box2DObj;             // pointer to the CBox2D object for use in callbacks
};


// Wrapper class
@interface CBox2D : NSObject

-(void) HelloWorld; // Basic Hello World! example from Box2D

-(void) LaunchBall;                                                         // launch the ball
-(void) Update:(float)elapsedTime;                                          // update the Box2D engine
-(void) RegisterHit;                                                        // Register when the ball hits the brick
-(void) AddObject:(char *)name newObject:(struct PhysicsObject *)newObj;    // Add a new physics object
-(struct PhysicsObject *) GetObject:(const char *)name;                     // Get a physics object by name
-(void) Reset;                                                              // Reset Box2D

@end

#endif
