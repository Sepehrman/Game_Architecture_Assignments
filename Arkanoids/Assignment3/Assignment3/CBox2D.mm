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
    
    void BeginContact(b2Contact* contact) {
        // Use contact->GetFixtureA()->GetBody() to get the body that was hit
        b2Body* bodyA = contact->GetFixtureA()->GetBody();
        b2Body* bodyB = contact->GetFixtureB()->GetBody(); // Get the other body involved in the contact

        struct PhysicsObject *objDataA = (struct PhysicsObject *)(bodyA->GetUserData());
        struct PhysicsObject *objDataB = (struct PhysicsObject *)(bodyB->GetUserData());
        
        CBox2D *parentObjA = (__bridge CBox2D *)(objDataA->box2DObj);
        CBox2D *parentObjB = (__bridge CBox2D *)(objDataB->box2DObj);

        if (objDataA->objType == WallBotTypeBox) {
            printf("Collision with WallBotTypeBox detected\n");
            [parentObjA RegisterBoundryHit];    // assumes RegisterHit is a callback function to register collision

        } else if (objDataB->objType == WallBotTypeBox) {
            printf("Collision with WallBotTypeBox detected\n");
            [parentObjB RegisterBoundryHit];    // assumes RegisterHit is a callback function to register collision
        }
        
    };
    
    void EndContact(b2Contact* contact) {
        
        b2Body* bodyA = contact->GetFixtureA()->GetBody();
        b2Body* bodyB = contact->GetFixtureB()->GetBody(); // Get the other body involved in the contact

        struct PhysicsObject *objDataA = (struct PhysicsObject *)(bodyA->GetUserData());
        struct PhysicsObject *objDataB = (struct PhysicsObject *)(bodyB->GetUserData());
        
        CBox2D *parentObjA = (__bridge CBox2D *)(objDataA->box2DObj);
        CBox2D *parentObjB = (__bridge CBox2D *)(objDataB->box2DObj);

        
        if ((objDataB)->objType == PaddleType) {
           [parentObjB LaunchBall];
           printf("launched ball a\n");
       } else if ((objDataA)->objType == PaddleType) {
           [parentObjA LaunchBall];
           printf("launched ball b\n");
       }
        
    };
    
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
            
            //            if (bodyB->GetType() == ObjectType::WallSideTypeBox && bodyB->GetType() == ObjectType::WallTopTypeBox) {
            //                return;
            //            }
            
            // Get the PhysicsObject as the user data, and then the CBox2D object in that struct
            // This is needed because this handler may be running in a different thread and this
            //  class does not know about the CBox2D that's running the physics
            struct PhysicsObject *objData = (struct PhysicsObject *)(bodyA->GetUserData());
            CBox2D *parentObj = (__bridge CBox2D *)(objData->box2DObj);
            
            // Call RegisterHit (assume CBox2D object is in user data)
            const char *originalCString = objData->name;
            char firstFiveChars[6]; // Extra space for the null terminator
            strncpy(firstFiveChars, originalCString, 5);
            firstFiveChars[5] = '\0'; // Null terminator
            
            if (strcmp(firstFiveChars, "Brick") == 0) {
                const char *brickHit = objData->name; // Define your string here
                [parentObj RegisterHit:brickHit]; // Pass the string into RegisterHit
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
    const char* lastBrickHit;
    
    // Logic for ball hitting walls
    bool ballHitLeftWall;
    bool ballHitRightWall;
    bool ballHitTopWall;
    
    // Logic for ball hitting bottom boundry
    bool ballHitBoundry;
    
    // Tracking Game Score
//    int score;
//    int bricksRemaining;
    
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
        
#ifdef USE_HELLO_WORLD
        groundBodyDef = NULL;
        groundBody = NULL;
        groundBox = NULL;
#endif
        
        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        paddlePosition = PADDLE_POS_X;
        
        struct PhysicsObject *newObj;
        char *objName;
        
        for (int row = BRICK_ROW_ITER_START; row < BRICK_ROW_ITER_END; row += BRICK_ROW_ITER_STEP) {
            for (int col = BRICK_COL_ITER_START; col < BRICK_COL_ITER_END; col += BRICK_COL_ITER_STEP) {
                struct PhysicsObject *newObj = new struct PhysicsObject;
                newObj->loc.x = row;
                newObj->loc.y = col;
                newObj->objType = ObjTypeBox;
            
                char objName[20];
                sprintf(objName, "Brick %d %d", row, col);
                printf(objName);
                [self AddObject:strdup(objName) newObject:newObj newType:b2_staticBody];
            }
        }
        
        // Set up the brick and ball objects for Box2D
        
        
        newObj = new struct PhysicsObject;
        newObj = new struct PhysicsObject;
        newObj->loc.x = BALL_POS_X;
        newObj->loc.y = BALL_POS_Y;
        newObj->objType = ObjTypeCircle;
        objName = strdup("Ball");
        [self AddObject:objName newObject:newObj newType:b2_dynamicBody];
        
        
        // Set up Walls for Box2D
        newObj = new struct PhysicsObject;
        newObj->loc.x = WALL_LEFT_POS_X;
        newObj->loc.y = WALL_LEFT_POS_Y;
        newObj->objType = WallSideTypeBox;
        objName = strdup("Wall_Left");
        [self AddObject:objName newObject:newObj newType:b2_staticBody];
        
        newObj = new struct PhysicsObject;
        newObj->loc.x = WALL_RIGHT_POS_X;
        newObj->loc.y = WALL_RIGHT_POS_Y;
        newObj->objType = WallSideTypeBox;
        objName = strdup("Wall_Right");
        [self AddObject:objName newObject:newObj newType:b2_staticBody];
        
        newObj = new struct PhysicsObject;
        newObj->loc.x = WALL_TOP_POS_X;
        newObj->loc.y = WALL_TOP_POS_Y;
        newObj->objType = WallTopTypeBox;
        objName = strdup("Wall_Top");
        [self AddObject:objName newObject:newObj newType:b2_staticBody];  // Causing issue
        
        newObj = new struct PhysicsObject;
        newObj->loc.x = WALL_BOT_POS_X;
        newObj->loc.y = WALL_BOT_POS_Y;
        newObj->objType = WallBotTypeBox;
        objName = strdup("Wall_Bot");
        [self AddObject:objName newObject:newObj newType:b2_staticBody];
        
        newObj = new struct PhysicsObject;
        newObj->loc.x = PADDLE_POS_X;
        newObj->loc.y = PADDLE_POS_Y;
        newObj->objType = PaddleType;
        objName = strdup("Paddle");
        [self AddObject:objName newObject:newObj newType:b2_dynamicBody];
        
        totalElapsedTime = 0;
        ballHitBrick = false;
        ballLaunched = false;
        
        // Initializ score
        self.score = 0;
        self.remainingBricks = 0;
        
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
    struct PhysicsObject *theBall = physicsObjects["Ball"];
    struct PhysicsObject *thePaddle = physicsObjects["Paddle"];
    ((b2Body*)thePaddle->b2ShapePtr)->SetTransform(b2Vec2(paddlePosition, 0), 0);
    
    
    // Check here if we need to launch the ball
    //  and if so, use ApplyLinearImpulse() and SetActive(true)
    if (ballLaunched)
    {
        ((b2Body *)theBall->b2ShapePtr)->SetLinearVelocity(b2Vec2(0.0f, 0.0f));

        ((b2Body *)theBall->b2ShapePtr)->ApplyLinearImpulse(b2Vec2(700, BALL_VELOCITY),
                                                            ((b2Body *)theBall->b2ShapePtr)->GetPosition(),
                                                            true);
        ((b2Body *)theBall->b2ShapePtr)->SetActive(true);
        ballLaunched = false;
    }
      

    // If the last collision test was positive, stop the ball and destroy the brick
        if (ballHitBrick)
        {
            struct PhysicsObject *theBrick = physicsObjects[lastBrickHit];
    
            // Destroy the brick from Box2D and related objects in this class
            world->DestroyBody(((b2Body *)theBrick->b2ShapePtr));
            delete theBrick;
            theBrick = nullptr;
            physicsObjects.erase(lastBrickHit);
            printf("%s\n", lastBrickHit);
            ballHitBrick = false;   // until a reset and re-launch
                
        }

        if (ballHitBoundry) {
            // Ball hit boundry
            [self Reset];   // Resets the ball
            self.score--;
            ballHitBoundry = false;
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

-(void)RegisterHit:(const char*)brickHit
{
    // Set some flag here for processing later...
    lastBrickHit = brickHit;
    ballHitBrick = true;
}

-(void)RegisterBoundryHit
{
    // Set some flag here for processing later...
    ballHitBoundry = true;
}


-(void)LaunchBall
{
    // Set some flag here for processing later...
    ballLaunched = true;
}

-(void)AddObject:(char *)name newObject:(struct PhysicsObject *)newObj newType:(b2BodyType)type
{
    
    // Set up the body definition and create the body from it
    b2BodyDef bodyDef;
    b2Body *theObject;
    bodyDef.type = type;
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
            fixtureDef.friction = 0.0f;
            fixtureDef.restitution = 1.0f;
            
            break;
            
        case PaddleType:
            dynamicBox.SetAsBox(PADDLE_WIDTH/2, PADDLE_HEIGHT/2);
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.0f;
            fixtureDef.restitution = 1.0f;
            
            break;
            
        case ObjTypeCircle:
            
            circle.m_radius = BALL_RADIUS;
            fixtureDef.shape = &circle;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.0f;
            fixtureDef.restitution = 1.0f;
            fixtureDef.filter.categoryBits = BALL;  // BitMask to identify ball when hitting boundry
//            fixtureDef.filter.maskBits = BOUNDRY;  // boundry will only collide with a BALL
            theObject->SetGravityScale(0.0f);
            theObject->SetAngularDamping(0.0f);
            theObject->SetLinearDamping(0.0f);
            
            break;
            
        case WallSideTypeBox:
            
            dynamicBox.SetAsBox(WALL_LEFT_WIDTH/2, WALL_LEFT_HEIGHT/2);
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.0f;
            fixtureDef.restitution = 1.0f;
//            theObject->SetType(b2_staticBody);  // Immovable
            
            break;
            
        case WallTopTypeBox:
            
            dynamicBox.SetAsBox(WALL_TOP_WIDTH/2, WALL_TOP_HEIGHT/2);
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.0f;
            fixtureDef.restitution = 1.0f;      // Bounce factor?
//            theObject->SetType(b2_staticBody);  // Immovable
            
            break;
            
        case WallBotTypeBox:
            
            dynamicBox.SetAsBox(WALL_BOT_WIDTH/2, WALL_BOT_HEIGHT/2);
            fixtureDef.shape = &dynamicBox;
//            fixtureDef.density = 1.0f;
//            fixtureDef.friction = 0.0f;
//            fixtureDef.restitution = 1.0f;      // Bounce factor?
            
            fixtureDef.filter.categoryBits = BOUNDRY;
            fixtureDef.filter.maskBits = BALL;  // boundry will only collide with a BALL
//            theObject->SetType(b2_staticBody);  // Immovable
            fixtureDef.isSensor = true;
//            theObject->SetType(b2_staticBody); // Set the body type to static (immovable)
            
            break;
            
        default:
            
            break;
            
    }
    
    // Add the new fixture to the Box2D object and add our physics object to our map
    theObject->CreateFixture(&fixtureDef);
    newObj->name = name;
    physicsObjects[name] = newObj;
    
}

-(void)movePaddle:(double)offset
{
    float lowerLimit = -24.22;
    float upperLimit = 24.22;

    // Check if movement exceeds limits
    if ((paddlePosition + offset) >= lowerLimit && (paddlePosition + offset) <= upperLimit) {
        // If within limits, apply offset
        paddlePosition += offset;
    } else {
        // If exceeding limits, set paddlePosition to the nearest limit
        if (offset > 0) {
            paddlePosition = upperLimit;
        } else {
            paddlePosition = lowerLimit;
        }
    }

}


-(struct PhysicsObject *) GetObject:(const char *)name
{
    return physicsObjects[name];
}

-(void)Reset
{
    for (int row = BRICK_ROW_ITER_START; row < BRICK_ROW_ITER_END; row += BRICK_ROW_ITER_STEP) {
            for (int col = BRICK_COL_ITER_START; col < BRICK_COL_ITER_END; col += BRICK_COL_ITER_STEP) {

                char objName[20];
                sprintf(objName, "Brick %d %d", row, col);
                // Look up the brick, and if it exists, destroy it and delete it
                struct PhysicsObject *theBrick = physicsObjects[objName];
                if (theBrick) {
                    b2Body* brickBody = static_cast<b2Body*>(theBrick->b2ShapePtr);
                    if (brickBody) {
                        world->DestroyBody(brickBody);
                    }
                    delete theBrick;
                    theBrick = nullptr;
                    physicsObjects.erase(objName);
                }

//                 Create a new brick object
                struct PhysicsObject *newObj = new struct PhysicsObject;
                newObj->loc.x = row;
                newObj->loc.y = col;
                newObj->objType = ObjTypeBox;
                [self AddObject:strdup(objName) newObject:newObj newType:b2_staticBody];

            }
        }
    
    struct PhysicsObject *thePaddle = physicsObjects["Paddle"];
    thePaddle->loc.x = PADDLE_POS_X;
    thePaddle->loc.y = PADDLE_POS_Y;
    paddlePosition = PADDLE_POS_X;
    ((b2Body*)thePaddle->b2ShapePtr)->SetTransform(b2Vec2(PADDLE_POS_X, PADDLE_POS_Y), 0);
    ((b2Body*)thePaddle->b2ShapePtr)->SetLinearVelocity(b2Vec2(0, 0));
    ((b2Body*)thePaddle->b2ShapePtr)->SetAngularVelocity(0);
    ((b2Body*)thePaddle->b2ShapePtr)->SetAwake(false);
    ((b2Body*)thePaddle->b2ShapePtr)->SetActive(true);
    
    //Look up the ball object and re-initialize the position, etc.
    struct PhysicsObject *theBall = physicsObjects["Ball"];
    theBall->loc.x = BALL_POS_X;
    theBall->loc.y = BALL_POS_Y;
    ((b2Body*)theBall->b2ShapePtr)->SetTransform(b2Vec2(BALL_POS_X, BALL_POS_Y), 0);
    ((b2Body*)theBall->b2ShapePtr)->SetLinearVelocity(b2Vec2(0, 0));
    ((b2Body*)theBall->b2ShapePtr)->SetAngularVelocity(0);
    ((b2Body*)theBall->b2ShapePtr)->SetAwake(false);
    ((b2Body*)theBall->b2ShapePtr)->SetActive(true);
        


      totalElapsedTime = 0;
      ballHitBrick = false;
      ballLaunched = false;
      ballHitBoundry = false;

}

@end
