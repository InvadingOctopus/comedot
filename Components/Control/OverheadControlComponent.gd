## Provides overhead-view (i.e. "top-down") movement control for the parent [Entity]'s [CharacterBody2D].

class_name OverheadControlComponent
extends BodyComponent


#region Parameters
@export var isEnabled: bool = true
@export var parameters: OverheadMovementParameters = OverheadMovementParameters.new()
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
	if not isEnabled: return
	processWalkInput(delta)
	parentEntity.callOnceThisFrame(body.move_and_slide)
	lastVelocity = body.velocity # TBD: Should this come last?

	# Avoid the "glue effect" where the character sticks to a wall until the velocity changes to the opposite direction.
	parentEntity.callOnceThisFrame(Global.resetBodyVelocityIfZeroMotion, [body])

	# DEBUG debugPrintInfo()


## Get the input direction and handle the movement/deceleration.
func processWalkInput(delta: float):
	if not isEnabled: return

	self.inputDirection = Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)

	if inputDirection: lastInputDirection = inputDirection

	if parameters.shouldApplyAcceleration:
		body.velocity = body.velocity.move_toward(inputDirection * parameters.speed, parameters.acceleration * delta)
	else:
		body.velocity = inputDirection * parameters.speed

	# TODO: Compare setting vector components separately vs together

	# Friction?

	if parameters.shouldApplyFriction:

		if is_zero_approx(inputDirection.x):
			body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.friction * delta)

		if is_zero_approx(inputDirection.y):
			body.velocity.y = move_toward(body.velocity.y, 0.0, parameters.friction * delta)

	# Disable friction by maintaining velcoty fron the previous frame?

	if parameters.shouldMaintainPreviousVelocity and not inputDirection:
		body.velocity = lastVelocity

	# Minimum velocity?

	if parameters.shouldMaintainMinimumVelocity:
		if body.velocity.length() < parameters.minimumSpeed:
			if body.velocity.is_zero_approx():
				body.velocity = self.lastVelocity.normalized() * parameters.minimumSpeed
			else:
				body.velocity = body.velocity.normalized() * parameters.minimumSpeed

	# Last direction

	if not body.velocity.is_zero_approx():
		#if currentState == State.idle: currentState = State.walk
		lastDirection = body.velocity.normalized()

	#Debug.watchList.lastInputDirection = lastInputDirection
	#Debug.watchList.lastDirection = lastDirection


## NOTE: Not implemented
func processFriction(delta: float):
	pass


func debugPrintInfo():
	Debug.watchList.velocity = body.velocity
	Debug.watchList.wallNormal = body.get_wall_normal()
	Debug.watchList.lastMotion = body.get_last_motion()
