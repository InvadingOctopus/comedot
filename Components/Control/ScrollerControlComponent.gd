## Applies a constant horizontal and/or vertical thrust and maintains a minimum velocity separetly for the X and Y axes.
## For games like scrolling shoot-em-ups or running.
## Requirements: [Characterbody2D], [Camera2D] optional

class_name ScrollerControlComponent
extends BodyComponent

# TODO: Camera "spring"
# TODO: Verify, specially diagonal movement.


#region Parameters
@export var isEnabled: bool = true
@export var parameters: ScrollerMovementParameters = ScrollerMovementParameters.new()
#endregion


#region State

var camera: Camera2D:
	get:
		if not camera: camera = parentEntity.findFirstChildOfType(Camera2D)
		return camera
		
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
	applyThrust(delta)
	maintainMinimumSpeed(delta)
	
	parentEntity.callOnceThisFrame(body.move_and_slide)
	lastVelocity = body.velocity # TBD: Should this come last?

	# Avoid the "glue effect" where the character sticks to a wall until the velocity changes to the opposite direction.
	parentEntity.callOnceThisFrame(Global.resetBodyVelocityIfZeroMotion, [body]) # TBD: Should this be optional?

	#showDebugInfo()


func processWalkInput(delta: float):
	if not isEnabled: return
	# Get the input direction and handle the movement/deceleration.

	self.inputDirection = Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
		
	if not inputDirection.is_zero_approx(): lastInputDirection = inputDirection

	# Calculate separate velocities for X and Y
	var inputVelocity := Vector2(inputDirection.x * parameters.maximumHorizontalSpeed, inputDirection.y * parameters.maximumVerticalSpeed)

	# TBD: Is setting the vector once as a whole the exact same effect as setting the 2 axes separately?
	if parameters.shouldApplyAcceleration:
		body.velocity = body.velocity.move_toward(inputVelocity, parameters.acceleration * delta)
		#body.velocity.x = move_toward(body.velocity.x, inputDirection.x * parameters.maximumHorizontalSpeed, parameters.acceleration * delta)
		#body.velocity.y = move_toward(body.velocity.y, inputDirection.y * parameters.maximumVerticalSpeed, parameters.acceleration * delta)
	else:
		body.velocity = inputVelocity
		#body.velocity.x = inputDirection * parameters.maximumHorizontalSpeed
		#body.velocity.y = inputDirection * parameters.maximumVerticalSpeed

	# Friction?
	
	if parameters.shouldApplyFriction:

		if is_zero_approx(inputDirection.x):
			body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.friction * delta)

		if is_zero_approx(inputDirection.y):
			body.velocity.y = move_toward(body.velocity.y, 0.0, parameters.friction * delta)

	# Disable friction by maintaining velcoty fron the previous frame?

	if parameters.shouldMaintainPreviousVelocity and not inputDirection:
		body.velocity = lastVelocity

	# Last direction

	if not body.velocity.is_zero_approx():
		#if currentState == State.idle: currentState = State.walk
		lastDirection = body.velocity.normalized()


func applyThrust(delta: float):
	if not isEnabled: return
	
	# Apply the constant thrust for an axis if there is no player input on that axis.
	# NOTE: Respect the direction (positive or negative) of the parameters. i.e. Do NOT use `* sign(velocity)`
	
	# NOTE: Do NOT apply acceleration here. [move_toward()] applies very slowly because of `delta`.
	
	if is_zero_approx(inputDirection.x) \
	and not is_zero_approx(parameters.horizontalThrust) \
	and abs(body.velocity.x) < abs(parameters.horizontalThrust):
		body.velocity.x = parameters.horizontalThrust
	
	if is_zero_approx(inputDirection.y) \
	and not is_zero_approx(parameters.verticalThrust) \
	and abs(body.velocity.y) < abs(parameters.verticalThrust):
		body.velocity.y = parameters.verticalThrust
		
	
func maintainMinimumSpeed(delta: float):
	# NOTE: Do NOT apply acceleration here. [move_toward()] applies very slowly because of `delta`.
	
	if abs(body.velocity.x) < abs(parameters.minimumHorizontalSpeed):	
		body.velocity.x = parameters.minimumHorizontalSpeed * signf(body.velocity.x)
		
	if abs(body.velocity.y) < abs(parameters.minimumVerticalSpeed):	
		body.velocity.y = parameters.minimumVerticalSpeed * signf(body.velocity.y)
		

func showDebugInfo():
	Debug.watchList.velocity		= body.velocity
	Debug.watchList.lastVelocity	= lastVelocity
	Debug.watchList.lastMotion		= body.get_last_motion()
	Debug.watchList.lastInput		= lastInputDirection
	Debug.watchList.lastDirection	= lastDirection
	#Debug.watchList.wallNormal		= body.get_wall_normal()
