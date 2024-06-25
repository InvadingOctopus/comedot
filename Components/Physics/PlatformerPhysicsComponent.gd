## Handles horizontal walking, jumping and gravity for the entity's [CharacterBody2D] in a "platform" world.
## Controlled by input from a [PlatformerPhysicsControlComponent].
## Requirements: Entity with [CharacterBody2D], BELOW [PlatformerPhysicsControlComponent]

class_name PlatformerPhysicsComponent
extends BodyComponent

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ


#region Parameters
@export var isEnabled: bool = true
@export var parameters: PlatformerMovementParameters = PlatformerMovementParameters.new()
#endregion


#region State

## The "grace period" while the player can still jump after just having walking off a platform floor.
## May provide a better sensation of control for some games.
@onready var coyoteTimer: Timer = $CoyoteJumpTimer

enum State { idle, moveOnFloor, moveInAir }

var states = {
	State.idle:			null,
	State.moveOnFloor:	null,
	State.moveInAir:	null,
	# State.jumping:	null, # TBD
	# State.falling:	null, # TBD
	}

var currentState: State:
	set(newValue):
		currentState = newValue
		# Debug.printDebug(str(currentState))

var inputDirection:			float
var lastInputDirection:		float
var isInputZero:			bool = true
var jumpInput:				float
	
## The cached state of [method CharacterBody2D.is_on_floor] for the current frame.
## WARNING: May no longer be true after calling [method CharacterBody2D.move_and_slide]
var isOnFloor:		bool 

var wasOnFloor:		bool = false ## Was the body on the floor before the last [method CharacterBody2D.move_and_slide]?
var wasOnWall:		bool = false ## Was the body on a wall before the last [method CharacterBody2D.move_and_slide]?

var gravity:		float = ProjectSettings.get_setting(Global.SettingsPaths.gravity)

var currentNumberOfJumps: int = 0
		
#endregion


func _ready() -> void:
	self.currentState = State.idle
	if parentEntity.body:
		printLog("parentEntity.body.motion_mode → Grounded")
		parentEntity.body.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	else:
		printWarning("Missing parentEntity.body: " + parentEntity.logName)


func _physics_process(delta: float):
	if not isEnabled: return
	
	processGravity(delta)
	
	processInput()
	processJumpInput()
	
	# TODO: processWallJump()
	processJump(delta)
	
	updateState()

	#applyAccelerationOnFloor(delta)
	#applyAccelerationInAir(delta)
	processHorizontalMovement(delta)
	#applyFrictionOnFloor(delta)
	#applyFrictionInAir(delta)
	processAllFriction(delta)

	self.wasOnFloor = isOnFloor
	self.wasOnWall  = body.is_on_wall() # NOTE: NOT `is_on_wall_only()`
	
	parentEntity.callOnceThisFrame(body.move_and_slide) # Will be called by PhysicsComponentBase
	
	#showDebugInfo()
	
	# Reset the input
	inputDirection = 0


## NOTE: MUST be called AFTER [processInput]
func updateState():
	# DESIGN: Using `match` here may seem too cluttered and ambiguous

	if currentState == State.idle and not isInputZero:
		# CHECK: Should this be done in `processInput()` so that there is only one check for [isInputZero]?
		currentState = State.moveOnFloor if isOnFloor else State.moveInAir

	if currentState != State.idle and is_zero_approx(body.velocity.x) and is_zero_approx(body.velocity.y):
		currentState = State.idle

	# Cache frequently used properties
	self.isOnFloor = body.is_on_floor() # This should be cached after processing gravity.
	
	# Jump
	
	if isOnFloor: 
		coyoteTimer.stop()
		currentNumberOfJumps = 0


## Handles player input.
## Affected by [member isEnabled].
func processInput():
	if not isEnabled: return

	# Get the input direction and handle the movement/deceleration.
	# NOTE: Fed by PlatformerPhysicsControlComponent
	# self.inputDirection = Input.get_axis(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight)

	# Cache properties that are accessed often to avoid repeated function calls on other objects.
	self.isInputZero = is_zero_approx(inputDirection)

	if not isInputZero: lastInputDirection = inputDirection

	# NOTE: DESIGN: Accept input in air even if [member shouldAllowMovementInputInAir] is `false`,
	# so that some games can let the player turn around to shoot in any direction while in air, for example.


func processGravity(delta: float):
	# Vertical Slowdown
	if not isOnFloor: # NOTE: Cache [isOnFloor] after processing gravity.
		body.velocity.y += (gravity * parameters.gravityScale) * delta


## Applies movement with or without gradual acceleration depending on the [member shouldApplyAccelerationOnFloor] or [member shouldApplyAccelerationInAir] flags.
## NOTE: NOT affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
func processHorizontalMovement(delta: float):
	# Nothing to do if there is no player input.
	if isInputZero: return

	if isOnFloor: # Are we on the floor?
		if parameters.shouldApplyAccelerationOnFloor: # Apply the speed gradually or instantly?
			body.velocity.x = move_toward(body.velocity.x, parameters.speedOnFloor * inputDirection, parameters.accelerationOnFloor * delta)
		else:
			body.velocity.x = inputDirection * parameters.speedOnFloor
	elif parameters.shouldAllowMovementInputInAir: # Are we in the air and are movement changes allowed in air?
		if parameters.shouldApplyAccelerationInAir: # Apply the speed gradually or instantly?
			body.velocity.x = move_toward(body.velocity.x, parameters.speedInAir * inputDirection, parameters.accelerationInAir * delta)
		else:
			body.velocity.x = inputDirection * parameters.speedInAir


## Applies friction if there is no player input and either [member shouldApplyFrictionOnFloor] or [member shouldApplyFrictionInAir] is `true`.
## NOTE: NOT affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
func processAllFriction(delta: float):
	# Don't apply friction if the player is trying to move;
	# only apply friction to slow down when there is no player input, OR
	# NOTE: If movement is not allowed in air, then apply air friction regardless of player input.

	if isOnFloor and parameters.shouldApplyFrictionOnFloor and isInputZero:
		body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionOnFloor * delta)
	elif (not isOnFloor) and parameters.shouldApplyFrictionInAir and (isInputZero or not parameters.shouldAllowMovementInputInAir):
		body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionInAir * delta)


#region Jumping

func _input(event: InputEvent):
	if not isEnabled or parameters.maxNumberOfJumps <= 0: return
	processJumpInput()


func processJumpInput():
	# TBD: NOTE: These guard conditions may prevent a "short" jump if this function gets disabled DURING a jump.
	if not isEnabled or parameters.maxNumberOfJumps <= 0: return
	var shouldJump: bool = false

	# Initial or mid-air jump

	if self.jumpInput > 0:
		if currentNumberOfJumps == 0: shouldJump = isOnFloor or not is_zero_approx(coyoteTimer.time_left)
		else: shouldJump = currentNumberOfJumps < parameters.maxNumberOfJumps

	if shouldJump:
		if currentNumberOfJumps == 0:
			body.velocity.y = parameters.jumpVelocity1stJump
		else:
			body.velocity.y = parameters.jumpVelocity2ndJump
		coyoteTimer.stop()

		currentNumberOfJumps += 1
		currentState = State.moveInAir # TBD: Should this be a `jump` state?

	# Shorten the initial jump if we are jumping

	if Input.is_action_just_released(GlobalInput.Actions.jump) and not isOnFloor and body.velocity.y < parameters.jumpVelocity1stJumpShort:
		body.velocity.y = parameters.jumpVelocity1stJumpShort


func processJump(delta: float):
	if not isEnabled: return
	
	# "Coyote" Jumping. beep beep!
	# CREDIT: THANKS: Heartbeast

	Debug.watchList.wasOnFloor = wasOnFloor
	Debug.watchList.floor = body.is_on_floor()
	Debug.watchList.y = body.velocity.y
		
	var didJustLeaveLedge: bool = wasOnFloor \
		and not body.is_on_floor() \
		and body.velocity.y >= 0 # Are we falling?
	
	if didJustLeaveLedge:
		coyoteTimer.start()
	
	Debug.watchList.timer = coyoteTimer.time_left

#endregion


#region Standalone Functions

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ

## Applies [member accelerationOnFloor] regardless of [member shouldApplyAccelerationOnFloor]; this flag should be checked by caller.
func applyAccelerationOnFloor(delta: float):
	if (not isInputZero) and isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, parameters.speedOnFloor * inputDirection, parameters.accelerationOnFloor * delta)


## Applies [member accelerationInAir] regardless of [member shouldApplyAccelerationInAir]; this flag should be checked by caller.
func applyAccelerationInAir(delta: float):
	if (not isInputZero) and (not isOnFloor):
		body.velocity.x = move_toward(body.velocity.x, parameters.speedInAir * inputDirection, parameters.accelerationInAir * delta)


## Applies [member frictionOnFloor] regardless of [member shouldApplyFrictionOnFloor]; this flag should be checked by caller.
func applyFrictionOnFloor(delta: float):
	# Friction on floor should only be applied if there is no input;
	# otherwise the player would not be able to start moving in the first place!
	if isInputZero and isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionOnFloor * delta)


## Applies [member frictionInAir] regardless of [member shouldApplyFrictionInAir]; this flag should be checked by caller.
func applyFrictionInAir(delta: float):
	# If movement is not allowed in air, then apply air friction regardless of player input.
	if (isInputZero or not parameters.shouldAllowMovementInputInAir) and (not isOnFloor):
		body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionInAir * delta)

#endregion


func showDebugInfo():
	Debug.watchList.input		= inputDirection
	Debug.watchList.velocity	= body.velocity
	Debug.watchList.isOnFloor	= isOnFloor
	Debug.watchList.wasOnFloor	= wasOnFloor
	Debug.watchList.wasOnWall	= wasOnWall
	# Friction?
	if isOnFloor and parameters.shouldApplyFrictionOnFloor and isInputZero:
		Debug.watchList.friction = "floor"
	elif (not isOnFloor) and parameters.shouldApplyFrictionInAir and (isInputZero or not parameters.shouldAllowMovementInputInAir):
		Debug.watchList.friction = "air"
	else:
		Debug.watchList.friction = "none"
