## Handles horizontal movement in a "platform" world.
## NOTE: Gravity is handled by [GravityComponent]. Jumping is handled by [JumpControlComponent].
## Requirements: Entity with [CharacterBody2D]

class_name PlatformerControlComponent
extends BodyComponent

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ

#region Parameters

@export var isEnabled: 									bool = true

@export_subgroup("Movement on Floor")

@export_range(50,  1000, 5) var speedOnFloor:			float = 100

## If `false`, then [member speed] is applied directly.
@export var shouldApplyAccelerationOnFloor:				bool  = true
@export_range(50,  1000, 5) var accelerationOnFloor:	float = 800

@export var shouldApplyFrictionOnFloor:					bool  = true
@export_range(100, 2000, 5) var frictionOnFloor:		float = 1000


@export_subgroup("Movement in Air")

@export var shouldAllowMovementInputInAir:				bool  = true

@export_range(0,   1000, 5) var speedInAir:				float = 100.0

## If `false`, then [member speed] is applied directly.
@export var shouldApplyAccelerationInAir:				bool  = true
@export_range(50,  1000, 5) var accelerationInAir:		float = 400.0

@export var shouldApplyFrictionInAir:					bool  = true ## Applies horizontal friction when not on a floor (not gravity).
@export_range(0,   2000, 5) var frictionInAir:			float = 200.0 ## Applies horizontal friction when not on a floor (not gravity).

#endregion


#region State

enum State { idle, moveOnFloor, moveInAir }

var states = {
	State.idle:			null,
	State.moveOnFloor:	null,
	State.moveInAir:	null,
	}

var currentState: State:
	set(newValue):
		currentState = newValue
		# Debug.printDebug(str(currentState))

var inputDirection:	float
var lastInputDirection:	float
var isInputZero:	bool = true

var isOnFloor:		bool ## The cached state of [method CharacterBody2D.is_on_floor] for the current frame.
var wasOnFloor:		bool = false ## Was the body on the floor before the last [method CharacterBody2D.move_and_slide]?
var wasOnWall:		bool = false ## Was the body on a wall before the last [method CharacterBody2D.move_and_slide]?

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

	checkIdleState()

	# Cache frequently used properties
	self.isOnFloor = body.is_on_floor() # This should be cached after processing gravity.

	processInput()
	#processAccelerationOnFloor(delta)
	#processAccelerationInAir(delta)
	processAllMovement(delta)
	#processFrictionOnFloor(delta)
	#processFrictionInAir(delta)
	processAllFriction(delta)

	self.wasOnFloor = isOnFloor
	self.wasOnWall = body.is_on_wall() # NOTE: NOT `is_on_wall_only()`

	parentEntity.callOnceThisFrame(body.move_and_slide)

	#debugInfo()


func checkIdleState():
	if currentState != State.idle and is_zero_approx(body.velocity.x) and is_zero_approx(body.velocity.y):
		currentState = State.idle


## Handled player input.
## Affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
func processInput():
	if not isEnabled: return

	# Get the input direction and handle the movement/deceleration.
	self.inputDirection = Input.get_axis(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight)

	# Cache properties that are accessed often to avoid repeated function calls on other objects.
	self.isInputZero = is_zero_approx(inputDirection)

	if not isInputZero:

		if currentState == State.idle:
			currentState = State.moveOnFloor if isOnFloor else State.moveInAir

		lastInputDirection = inputDirection

	# NOTE: DESIGN: Accept input in air even if [member shouldAllowMovementInputInAir] is `false`,
	# so that some games can let the player turn around to shoot in any direction while in air, for example.


## Applies movement with or without gradual acceleration depending on the [member shouldApplyAccelerationOnFloor] or [member shouldApplyAccelerationInAir] flags.
## NOTE: NOT affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
func processAllMovement(delta: float):
	# Nothing to do if there is no player input.
	if isInputZero: return

	if isOnFloor: # Are we on the floor?
		if shouldApplyAccelerationOnFloor: # Apply the speed gradually or instantly?
			body.velocity.x = move_toward(body.velocity.x, speedOnFloor * inputDirection, accelerationOnFloor * delta)
		else:
			body.velocity.x = inputDirection * speedOnFloor
	elif shouldAllowMovementInputInAir: # Are we in the air and are movement changes allowed in air?
		if shouldApplyAccelerationInAir: # Apply the speed gradually or instantly?
			body.velocity.x = move_toward(body.velocity.x, speedInAir * inputDirection, accelerationInAir * delta)
		else:
			body.velocity.x = inputDirection * speedInAir


## Applies friction if there is no player input and either [member shouldApplyFrictionOnFloor] or [member shouldApplyFrictionInAir] is `true`.
## NOTE: NOT affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
func processAllFriction(delta: float):
	# Don't apply friction if the player is trying to move;
	# only apply friction to slow down when there is no player input, OR
	# NOTE: If movement is not allowed in air, then apply air friction regardless of player input.

	if isOnFloor and shouldApplyFrictionOnFloor and isInputZero:
		body.velocity.x = move_toward(body.velocity.x, 0.0, frictionOnFloor * delta)
	elif (not isOnFloor) and shouldApplyFrictionInAir and (isInputZero or not shouldAllowMovementInputInAir):
		body.velocity.x = move_toward(body.velocity.x, 0.0, frictionInAir * delta)


#region Standalone Functions

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ

## Applies [member accelerationOnFloor] regardless of [member shouldApplyAccelerationOnFloor]; this flag should be checked by caller.
func applyAccelerationOnFloor(delta: float):
	if (not isInputZero) and isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, speedOnFloor * inputDirection, accelerationOnFloor * delta)


## Applies [member accelerationInAir] regardless of [member shouldApplyAccelerationInAir]; this flag should be checked by caller.
func applyAccelerationInAir(delta: float):
	if (not isInputZero) and (not isOnFloor):
		body.velocity.x = move_toward(body.velocity.x, speedInAir * inputDirection, accelerationInAir * delta)


## Applies [member frictionOnFloor] regardless of [member shouldApplyFrictionOnFloor]; this flag should be checked by caller.
func applyFrictionOnFloor(delta: float):
	# Friction on floor should only be applied if there is no input;
	# otherwise the player would not be able to start moving in the first place!
	if isInputZero and isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, 0.0, frictionOnFloor * delta)


## Applies [member frictionInAir] regardless of [member shouldApplyFrictionInAir]; this flag should be checked by caller.
func applyFrictionInAir(delta: float):
	# If movement is not allowed in air, then apply air friction regardless of player input.
	if (isInputZero or not shouldAllowMovementInputInAir) and (not isOnFloor):
		body.velocity.x = move_toward(body.velocity.x, 0.0, frictionInAir * delta)

#endregion


func debugInfo():
	Debug.watchList.input		= inputDirection
	Debug.watchList.velocity	= body.velocity
	Debug.watchList.isOnFloor	= isOnFloor
	Debug.watchList.wasOnFloor	= wasOnFloor
	Debug.watchList.wasOnWall	= wasOnWall
	# Friction?
	if isOnFloor and shouldApplyFrictionOnFloor and isInputZero:
		Debug.watchList.friction = "floor"
	elif (not isOnFloor) and shouldApplyFrictionInAir and (isInputZero or not shouldAllowMovementInputInAir):
		Debug.watchList.friction = "air"
	else:
		Debug.watchList.friction = "none"
