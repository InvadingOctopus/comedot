## Provides overhead-view (i.e. "top-down") movement control for the parent [Entity]'s [CharacterBody2D].

class_name OverheadControlComponent
extends BodyComponent


#region Parameters

@export_subgroup("Movement")
@export_range(50.0, 1000.0, 50.0)  var speed:         float = 300.0

@export var shouldApplyAcceleration: bool = true
@export_range(50.0, 2000.0, 50.0)  var acceleration:  float = 800.0

## Completely disables slowdown from friction by reapplying the velocity from the previous frame.
## Use for scenarios like slippery surfaces such as ice.
@export var shouldMaintainPreviousVelocity: bool = false

@export var shouldMaintainMinimumVelocity:  bool = false
@export_range(10.0, 1000.0, 50.0)  var minimumSpeed:  float = 100.0

@export_subgroup("Friction")
## Slow the velocity down each frame.
@export var shouldApplyFriction: bool = true
@export_range(10.0, 2000.0, 100.0) var friction:      float = 1000.0

@export var shouldResetVelocityOnCollision: bool = true

#endregion


#region State
var inputDirection		:= Vector2.ZERO
var lastInputDirection	:= Vector2.ZERO
var lastDirection		:= Vector2.ZERO ## Normalized
var lastVelocity		:= Vector2.ZERO
#endregion


func _ready():
	if parentEntity.body:
		printLog("parentEntity.body.motion_mode → Floating")
		parentEntity.body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	else:
		printWarning("Missing parentEntity.body: " + parentEntity.logName)


func _physics_process(delta: float):
	processWalkInput(delta)
	parentEntity.callOnceThisFrame(body.move_and_slide)
	lastVelocity = body.velocity # TBD: Should this come last?

	# Avoid the "glue effect" where the character sticks to a wall until the velocity changes to the opposite direction.
	parentEntity.callOnceThisFrame(Global.resetBodyVelocityIfZeroMotion, [body])

	# DEBUG debugPrintInfo()

func processWalkInput(delta: float):
	# Get the input direction and handle the movement/deceleration.

	self.inputDirection = Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)

	if inputDirection: lastInputDirection = inputDirection

	if shouldApplyAcceleration:
		body.velocity = body.velocity.move_toward(inputDirection * speed, acceleration * delta)
	else:
		body.velocity = inputDirection * speed

	# TODO: Compare setting vector components separately vs together

	# Friction?

	if shouldApplyFriction:

		if is_zero_approx(inputDirection.x):
			body.velocity.x = move_toward(body.velocity.x, 0.0, friction * delta)

		if is_zero_approx(inputDirection.y):
			body.velocity.y = move_toward(body.velocity.y, 0.0, friction * delta)

	# Disable friction by maintaining velcoty fron the previous frame?

	if shouldMaintainPreviousVelocity and not inputDirection:
		body.velocity = lastVelocity

	# Minimum velocity?

	if shouldMaintainMinimumVelocity:
		if body.velocity.length() < minimumSpeed:
			if body.velocity.is_zero_approx():
				body.velocity = self.lastVelocity.normalized() * minimumSpeed
			else:
				body.velocity = body.velocity.normalized() * minimumSpeed

	# Last direction

	if not body.velocity.is_zero_approx():
		#if currentState == State.idle: currentState = State.walk
		lastDirection = body.velocity.normalized()

	#Debug.watchList.lastInputDirection = lastInputDirection
	#Debug.watchList.lastDirection = lastDirection


func processFriction(delta: float):
	pass


func debugPrintInfo():
	Debug.watchList.velocity = body.velocity
	Debug.watchList.wallNormal = body.get_wall_normal()
	Debug.watchList.lastMotion = body.get_last_motion()
