## Handles horizontal movement and gravity/falling.
## NOTE: Jumping is handled by [JumpControlComponent].

class_name PlatformControlComponent
extends BodyComponent

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ

#region Parameters

@export_subgroup("Movement")
@export_range(50.0,   1000.0, 50.0) var speedOnFloor: float 		= 100.0
@export_range(0.0,    1000.0, 50.0) var speedInAir: float 			= 100.0

 ## If `false`, then [member speed] is applied directly.
@export var shouldApplyAccelerationOnFloor: bool = true
@export_range(50.0,   1000.0, 50.0) var accelerationOnFloor: float	= 800.0

 ## If `false`, then [member speed] is applied directly.
@export var shouldApplyAccelerationInAir: bool = true
@export_range(50.0,   1000.0, 50.0) var accelerationInAir: float	= 400.0

## 1.0 is normal gravity as defined in Project Settings/Physics/2D
@export_range(0, 10.0, 0.1) var gravityScale: float					= 1.0

@export_subgroup("Friction")
@export var shouldApplyFrictionOnFloor: bool = true
@export_range(1000.0, 2000.0, 100.0) var frictionOnFloor: float		= 1000.0

@export var shouldApplyFrictionInAir: bool = true
@export_range(1000.0, 2000.0, 100.0) var frictionInAir: float		= 200.0

#endregion


#region State

enum State { idle, walk }

var states = {
	State.idle: null,
	State.walk: null
	}

var currentState: State:
	set(newValue):
		currentState = newValue
		# Debug.printDebug(str(currentState))

var inputDirection: float
var lastDirection:  float
var wasOnFloor	 := false ## Was the body on the floor before the last [method CharacterBody2D.move_and_slide]?
var gravity:		float = ProjectSettings.get_setting(Global.SettingsPaths.gravity)

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
	processWalkInput(delta)

	wasOnFloor = body.is_on_floor()
	parentEntity.callOnceThisFrame(body.move_and_slide)


func processWalkInput(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions defined in the Project Settings.
	self.inputDirection = Input.get_axis(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight)

	if inputDirection:
		if currentState == State.idle: currentState = State.walk

		processAllAcceleration(delta)

		lastDirection = inputDirection #= 0 if inputDirection == 1 else -PI / 2

	else:
		processAllFriction(delta) # Slow down if there is no input.


func processGravity(delta: float):
	# Vertical Slowdown
	if not body.is_on_floor():
		body.velocity.y += (gravity * gravityScale) * delta

	#if body.is_on_floor(): # Handled in JumpControlComponent
		#currentNumberOfJumps = 0

	if currentState != State.idle and is_zero_approx(body.velocity.x) and is_zero_approx(body.velocity.y):
		currentState = State.idle


func processAllAcceleration(delta: float):
	# Nothing to do if there is no player input.
	if is_zero_approx(inputDirection): return

	if body.is_on_floor(): # Are we on the floor?
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
	if not is_zero_approx(inputDirection): return

	if shouldApplyFrictionOnFloor and body.is_on_floor():
		body.velocity.x = move_toward(body.velocity.x, 0.0, frictionOnFloor * delta)
	elif shouldApplyFrictionInAir and not body.is_on_floor():
		body.velocity.x = move_toward(body.velocity.x, 0.0, frictionInAir * delta)


#region Standalone Functions

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ

func processAccelerationOnFloor(delta: float):
	if not is_zero_approx(inputDirection) and body.is_on_floor():
		body.velocity.x = move_toward(body.velocity.x, speedOnFloor * inputDirection, accelerationOnFloor * delta)

func processAccelerationInAir(delta: float):
	if not is_zero_approx(inputDirection) and not body.is_on_floor():
		body.velocity.x = move_toward(body.velocity.x, speedInAir * inputDirection, accelerationInAir * delta)

func processFrictionOnFloor(delta: float):
	if is_zero_approx(inputDirection) and body.is_on_floor():
		body.velocity.x = move_toward(body.velocity.x, 0.0, frictionOnFloor * delta)

func processFrictionInAir(delta: float):
	if is_zero_approx(inputDirection) and not body.is_on_floor():
		body.velocity.x = move_toward(body.velocity.x, 0.0, frictionInAir * delta)

#endregion
