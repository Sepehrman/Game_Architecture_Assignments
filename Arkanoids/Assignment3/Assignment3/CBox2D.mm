//====================================================================
//
// (c) Borna Noureddin
// COMP 8051   British Columbia Institute of Technology
// Objective-C++ wrapper for Box2D library
//
//====================================================================

#include <Box2D/Box2D.h>
#include "CBox2D.h"
#include <stdio.h>
#include <map>
#include <string>


// Some Box2D engine paremeters
const float MAX_TIMESTEP = 1.0f/60.0f;
const int NUM_VEL_ITERATIONS = 10;
const int NUM_POS_ITERATIONS = 3;


// Uncomment this lines to use the HelloWorld example
//#define USE_HELLO_WORLD


#pragma mark - Box2D contact listener class

// This C++ class is used to handle collisions
class CContactListener : public b2ContactListener
{
    
public:
    
    void BeginContact(b2Contact* contact) {};
    
    void EndContact(b2Contact* contact) {};
    
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
    {
        
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);
        b2PointState state1[2], state2[2];
        b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());
        
        if (state2[0] == b2_addState)
        {
            
            // Use contact->GetFixtureA()->GetBody() to get the body that was hit
            b2Body* bodyA = contact->GetFixtureA()->GetBody();
            
            // Get the PhysicsObject as the user data, and then the CBox2D object in that struct
            // This is needed because this handler may be running in a different thread and this
            //  class does not know about the CBox2D that's running the physics
            struct PhysicsObject *objData = (struct PhysicsObject *)(bodyA->GetUserData());
            CBox2D *parentObj = (__bridge CBox2D *)(objData->box2DObj);
            
            if (objData->objType == WallTopTypeBox) {
                printf("Hit top wall");
            } else if (objData->objType == ObjTypeBox) {
                printf("Hit the falling rect");
                // Call RegisterHit (assume CBox2D object is in user data)
                [parentObj RegisterHit];    // assumes RegisterHit is a callback function to register collision
            }
            
            
        }
        
    }
    
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {};
    
};


#pragma mark - CBox2D

@interface CBox2D ()
{
    
    // Box2D-specific objects
    b2Vec2 *gravity;
    b2World *world;
    float ballXVelocity;  // encodes
    CContactListener *contactListener;
    float paddlePosition;   // the position of the paddle on the x axis.
    float totalElapsedTime;
    
    // Map to keep track of physics object to communicate with the renderer
    std::map<std::string, struct PhysicsObject *> physicsObjects;

#ifdef USE_HELLO_WORLD
    b2BodyDef *groundBodyDef;
    b2Body *groundBody;
    b2PolygonShape *groundBox;
#endif

    // Logit for this particular "game"
    bool ballHitBrick;  // register that the ball hit the break
    bool ballLaunched;  // register that the user has launched the ball
    
    // Logic for ball hitting walls
    bool ballHitLeftWall;
    bool ballHitRightWall;
    bool ballHitTopWall;
    
}
@end

@implementation CBox2D

- (instancetype)init
{
    
    self = [super init];
    
    if (self) {
        ballXVelocity = 0.0f;
        
        // Initialize Box2D
        gravity = new b2Vec2(0.0f, 0.0f);
        world = new b2World(*gravity);
        
        paddlePosition = BRICK_POS_X;


        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        struct PhysicsObject *newObj;
        char *objName;
        
//        // Set up the brick and ball objects for Box2D
//        newObj = new struct PhysicsObject;
//        newObj->loc.x = BRICK_POS_X;
//        newObj->loc.y = BRICK_POS_Y;
//        newObj->objType = ObjTypeBox;
//        objName = strdup("Brick");
//        [self AddObject:objName newObject:newObj];
        
        newObj = new struct PhysicsObject;
        newObj->loc.x = BALL_POS_X;
        newObj->loc.y = BALL_POS_Y;
        newObj->objType = ObjTypeCircle;
        objName = strdup("Ball");
        [self AddObject:objName newObject:newObj];
        
        // Set up Walls for Box2D
        newObj = new struct PhysicsObject;
        newObj->loc.x = WALL_LEFT_POS_X;
        newObj->loc.y = WALL_LEFT_POS_Y;
        newObj->objType = WallSideTypeBox;
        objName = strdup("Wall_Left");
        [self AddObject:objName newObject:newObj];
        
        newObj = new struct PhysicsObject;
        newObj->loc.x = WALL_RIGHT_POS_X;
        newObj->loc.y = WALL_RIGHT_POS_Y;
        newObj->objType = WallSideTypeBox;
        objName = strdup("Wall_Right");
        [self AddObject:objName newObject:newObj];
        
        newObj = new struct PhysicsObject;
        newObj->loc.x = WALL_TOP_POS_X;
        newObj->loc.y = WALL_TOP_POS_Y;
        newObj->objType = WallTopTypeBox;
        objName = strdup("Wall_Top");
        [self AddObject:objName newObject:newObj];  // Causing issue
        
//        newObj = new struct PhysicsObject;
//        newObj->loc.x = BALL_POS_X;
//        newObj->loc.y = BALL_POS_Y + 10;
//        newObj->objType = ObjTypeBox;
//        objName = strdup("Paddle");
//        [self AddObject:objName newObject:newObj];  // Causing issue
        
        newObj = new struct PhysicsObject;
        newObj->loc.x = BRICK_POS_X;
        newObj->loc.y = BRICK_POS_Y;
        newObj->objType = ObjTypeBox;
        objName = strdup("Brick");
        [self AddObject:objName newObject:newObj];
        
        
        totalElapsedTime = 0;
        ballHitBrick = false;
        ballLaunched = false;
        
//        ballHitLeftWall = false;
//        ballHitLeftWall = false;
//        ballHitLeftWall = false;
        
    }
    
    return self;
    
}

- (void)dealloc
{
    
    if (gravity) delete gravity;
    if (world) delete world;
#ifdef USE_HELLO_WORLD
    if (groundBodyDef) delete groundBodyDef;
    if (groundBox) delete groundBox;
#endif
    if (contactListener) delete contactListener;
    
}

-(void)Update:(float)elapsedTime
{
    
    // Get pointers to the brick and ball physics objects
    struct PhysicsObject *theBrick = physicsObjects[std::string("Brick")];
    struct PhysicsObject *theBall = physicsObjects["Ball"];
    
    // Check here if we need to launch the ball
    //  and if so, use ApplyLinearImpulse() and SetActive(true)
    if (ballLaunched)
    {
        ((b2Body *)theBall->b2ShapePtr)->SetLinearVelocity(b2Vec2(0.0f, 0.0f));
        // Apply a force (since the ball is set up not to be affected by gravity)
        ((b2Body *)theBall->b2ShapePtr)->ApplyLinearImpulse(b2Vec2(ballXVelocity, BALL_VELOCITY),
                                                            ((b2Body *)theBall->b2ShapePtr)->GetPosition(),
                                                            true);

        ((b2Body *)theBall->b2ShapePtr)->SetActive(true);
        ballLaunched = false;
    }
    
    // Check if it is time yet to drop the brick, and if so call SetAwake()
    totalElapsedTime += elapsedTime;
    if ((totalElapsedTime > BRICK_WAIT) && theBrick && theBrick->b2ShapePtr) {
        ((b2Body *)theBrick->b2ShapePtr)->SetAwake(true);
    }
    
    // Use these lines for debugging the brick and ball positions
    //    if (theBrick)
    //        printf("Brick: %4.2f %4.2f\t",
    //               ((b2Body *)theBrick->b2ShapePtr)->GetPosition().x,
    //               ((b2Body *)theBrick->b2ShapePtr)->GetPosition().y);
    //    if (theBall &&  theBall->b2ShapePtr)
    //        printf("Ball: %4.2f %4.2f",
    //               ((b2Body *)theBall->b2ShapePtr)->GetPosition().x,
    //               ((b2Body *)theBall->b2ShapePtr)->GetPosition().y);
    //    printf("\n");
    
    
    
    // If the last collision test was positive, stop the ball and destroy the brick
    if (ballHitBrick)
    {
        
        // Stop the ball and make sure it is not affected by forces
        ((b2Body *)theBall->b2ShapePtr)->SetLinearVelocity(b2Vec2(0, 0));
        ((b2Body *)theBall->b2ShapePtr)->SetAngularVelocity(0);
        ((b2Body *)theBall->b2ShapePtr)->SetAwake(false);
//        ((b2Body *)theBall->b2ShapePtr)->SetActive(false); // TODO: Change this so the bricks would be disabled after hit
        
        // Destroy the brick from Box2D and related objects in this class
//        world->DestroyBody(((b2Body *)theBrick->b2ShapePtr));
//        delete theBrick;
//        theBrick = nullptr;
//        physicsObjects.erase("Brick");
//        ballHitBrick = false;   // until a reset and re-launch
        
    }
    
    if (world)
    {
        
        while (elapsedTime >= MAX_TIMESTEP)
        {
            world->Step(MAX_TIMESTEP, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
            elapsedTime -= MAX_TIMESTEP;
        }
        
        if (elapsedTime > 0.0f)
        {
            world->Step(elapsedTime, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
        }
        
    }
    
    // Update each node based on the new position from Box2D
    for (auto const &b:physicsObjects) {
        if (b.second && b.second->b2ShapePtr) {
            b.second->loc.x = ((b2Body *)b.second->b2ShapePtr)->GetPosition().x;
            b.second->loc.y = ((b2Body *)b.second->b2ShapePtr)->GetPosition().y;
        }
    }
    
}

-(void)RegisterHit
{
    // Set some flag here for processing later...
    printf("RegisterHit");
    ballHitBrick = true;
}

-(void)LaunchBall
{
    // Set some flag here for processing later...
    ballLaunched = true;
}

-(void) AddObject:(char *)name newObject:(struct PhysicsObject *)newObj
{
    
    // Set up the body definition and create the body from it
    b2BodyDef bodyDef;
    b2Body *theObject;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(newObj->loc.x, newObj->loc.y);
    theObject = world->CreateBody(&bodyDef);
    if (!theObject) return;
    
    // Setup our physics object and store this object and the shape
    newObj->b2ShapePtr = (void *)theObject;
    newObj->box2DObj = (__bridge void *)self;
    
    // Set the user data to be this object and keep it asleep initially
    theObject->SetUserData(newObj);
    theObject->SetAwake(false);
    
    // Based on the objType passed in, create a box or circle
    b2PolygonShape dynamicBox;
    b2CircleShape circle;
    b2FixtureDef fixtureDef;
    
    switch (newObj->objType) {
            
        case ObjTypeBox:
            
            dynamicBox.SetAsBox(BRICK_WIDTH/2, BRICK_HEIGHT/2);
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            
            break;
            
        case ObjTypeCircle:
            
            circle.m_radius = BALL_RADIUS;
            fixtureDef.shape = &circle;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            theObject->SetGravityScale(0.0f);
            
            break;
            
        case WallSideTypeBox:
            
            dynamicBox.SetAsBox(WALL_LEFT_WIDTH/2, WALL_LEFT_HEIGHT/2);
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.0f;
            fixtureDef.restitution = 1.0f;
            theObject->SetType(b2_staticBody);  // Immovable
            
            break;
            
        case WallTopTypeBox:
            
            dynamicBox.SetAsBox(WALL_TOP_WIDTH/2, WALL_TOP_HEIGHT/2);
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.0f;
            fixtureDef.restitution = 1.0f;      // Bounce factor?
            theObject->SetType(b2_staticBody);  // Immovable
            
            break;
            
        default:
            
            break;
            
    }
    
    // Add the new fixture to the Box2D object and add our physics object to our map
    theObject->CreateFixture(&fixtureDef);
    physicsObjects[name] = newObj;
    
}

-(void)movePaddle:(double)offset
{
    struct PhysicsObject *theBrick = physicsObjects["Brick"];
    paddlePosition += offset;
    printf("offset: %0.4f", paddlePosition);
}


-(struct PhysicsObject *) GetObject:(const char *)name
{
    return physicsObjects[name];
}

-(void)Reset
{
    
    // Look up the brick, and if it exists, destroy it and delete it
    struct PhysicsObject *theBrick = physicsObjects["Brick"];
    if (theBrick) {
        world->DestroyBody(((b2Body *)theBrick->b2ShapePtr));
        delete theBrick;
        theBrick = nullptr;
        physicsObjects.erase("Brick");
    }
    
    // Create a new brick object

    
    // Look up the ball object and re-initialize the position, etc.
    struct PhysicsObject *theBall = physicsObjects["Ball"];
    theBall->loc.x = BALL_POS_X;
    theBall->loc.y = BALL_POS_Y;
    ((b2Body *)theBall->b2ShapePtr)->SetTransform(b2Vec2(BALL_POS_X, BALL_POS_Y), 0);
    ((b2Body *)theBall->b2ShapePtr)->SetLinearVelocity(b2Vec2(0, 0));
    ((b2Body *)theBall->b2ShapePtr)->SetAngularVelocity(0);
    ((b2Body *)theBall->b2ShapePtr)->SetAwake(false);
    ((b2Body *)theBall->b2ShapePtr)->SetAwake(false);
    ((b2Body *)theBall->b2ShapePtr)->SetActive(true);
    
    totalElapsedTime = 0;
    ballHitBrick = false;
    ballLaunched = false;
    
}




@end
