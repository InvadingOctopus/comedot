## Handles horizontal movement and gravity/falling in a "platform" world.
## NOTE: Jumping is handled by [JumpControlComponent].

class_name PlatformControlComponent
extends BodyComponent

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ

#region Parameters

@export_subgroup("Movement")
@export_range(50.0,	1000.0, 5.0) var speedOnFloor: float 		= 100.0
@export_range(0.0,	1000.0, 5.0) var speedInAir: float			= 100.0

 ## If `false`, then [member speed] is applied directly.
@export var shouldApplyAccelerationOnFloor: bool = true
@export_range(50.0,	1000.0, 5.0) var accelerationOnFloor: float	= 800.0

 ## If `false`, then [member speed] is applied directly.
@export var shouldApplyAccelerationInAir: bool = true
@export_range(50.0,	1000.0, 5.0) var accelerationInAir: float	= 400.0

## 1.0 is normal gravity as defined in Project Settings/Physics/2D
@export_range(0.0,	10.0, 0.1) var gravityScale: float			= 1.0

@export_subgroup("Friction")
@export var shouldApplyFrictionOnFloor: bool = true
@export_range(100.0, 2000.0, 5.0) var frictionOnFloor: float	= 1000.0

@export var shouldApplyFrictionInAir: bool = true
@export_range(100.0, 2000.0, 5.0) var frictionInAir: float		= 200.0

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

var gravity:		float = ProjectSettings.get_setting(Global.SettingsPaths.gravity)

var inputDirection:	float
var lastDirection:	float
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
	processGravity(delta)

	# Cache frequently used properties
	self.isOnFloor = body.is_on_floor() # This should be cached after processing gravity.

	processInput()
	#processAccelerationOnFloor(delta)
	#processAccelerationInAir(delta)
	processAllAcceleration(delta)
	#processFrictionOnFloor(delta)
	#processFrictionInAir(delta)
	processAllFriction(delta)

	self.wasOnFloor = isOnFloor
	self.wasOnWall = body.is_on_wall() # NOTE: NOT `is_on_wall_only()`

	parentEntity.callOnceThisFrame(body.move_and_slide)

	#debugInfo()


func processGravity(delta: float):
	# Vertical Slowdown
	if not body.is_on_floor(): # NOTE: Cache [isOnFloor] after processing gravity.
		body.velocity.y += (gravity * gravityScale) * delta

	if currentState != State.idle and is_zero_approx(body.velocity.x) and is_zero_approx(body.velocity.y):
		currentState = State.idle


func processInput():
	# Get the input direction and handle the movement/deceleration.
	self.inputDirection = Input.get_axis(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight)

	# Cache properties that are accessed often to avoid repeated function calls on other objects.
	self.isInputZero = is_zero_approx(inputDirection)

	if not isInputZero:

		if currentState == State.idle:
			currentState = State.moveOnFloor if isOnFloor else State.moveInAir

		lastDirection = inputDirection


func processAllAcceleration(delta: float):
	# Nothing to do if there is no player input.
	if isInputZero: return

	if isOnFloor: # Are we on the floor?
		if shouldApplyAccelerationOnFloor: # Apply the speed gradually or instantly?
			body.velocity.x = move_toward(body.velocity.x, speedOnFloor * inputDirection, accelerationOnFloor * delta)
		else:
			body.velocity.x = inputDirection * speedOnFloor
	else: # Are we in the air?
		if shouldApplyAccelerationInAir: # Apply the speed gradually or instantly?
			body.velocity.x = move_toward(body.velocity.x, speedInAir * inputDirection, accelerationInAir * delta)
		else:
			body.velocity.x = inputDirection * speedInAir


func processAllFriction(delta: float):
	# Don't apply friction if the player is trying to move;
	# only apply friction to slow down when there is no player input.
	if not isInputZero: return

	if shouldApplyFrictionOnFloor and isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, 0.0, frictionOnFloor * delta)
	elif shouldApplyFrictionInAir and not isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, 0.0, frictionInAir * delta)


#region Standalone Functions

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ

func processAccelerationOnFloor(delta: float):
	if shouldApplyAccelerationOnFloor and (not isInputZero) and isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, speedOnFloor * inputDirection, accelerationOnFloor * delta)


func processAccelerationInAir(delta: float):
	if shouldApplyAccelerationInAir and (not isInputZero) and (not isOnFloor):
		body.velocity.x = move_toward(body.velocity.x, speedInAir * inputDirection, accelerationInAir * delta)


func processFrictionOnFloor(delta: float):
	# Friction on floor should only be applied if there is no input;
	# otherwise the player would not be able to start moving in the first place!
	if shouldApplyFrictionOnFloor and isInputZero and isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, 0.0, frictionOnFloor * delta)


func processFrictionInAir(delta: float):
	if shouldApplyFrictionInAir and isInputZero and (not isOnFloor):
		body.velocity.x = move_toward(body.velocity.x, 0.0, frictionInAir * delta)

#endregion


func debugInfo():
	Debug.watchList.input		= inputDirection
	Debug.watchList.velocity	= body.velocity
	Debug.watchList.isOnFloor	= isOnFloor
	Debug.watchList.wasOnFloor	= wasOnFloor
	Debug.watchList.wasOnWall	= wasOnWall

	if shouldApplyFrictionOnFloor and isInputZero and isOnFloor:
		Debug.watchList.friction = "floor"
	elif shouldApplyFrictionInAir and isInputZero and (not isOnFloor):
		Debug.watchList.friction = "air"
	else:
		Debug.watchList.friction = "none"
