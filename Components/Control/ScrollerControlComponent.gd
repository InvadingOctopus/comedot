## Applies a constant horizontal and/or vertical thrust and maintains a minimum velocity separetly for the X and Y axes.
## For games like scrolling shoot-em-ups or running.
## Requirements: BEFORE [CharacterBodyComponent], [Camera2D] optional

class_name ScrollerControlComponent
extends CharacterBodyDependentComponentBase

# TODO: Deceleration when letting go of input
# TODO: Camera "spring"


#region Parameters
@export var isEnabled:  bool = true
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
#var lastVelocity		:= Vector2.ZERO

#endregion


func _ready() -> void:
	if parentEntity.body:
		printLog("parentEntity.body.motion_mode → Floating & parentEntity.body.wall_min_slide_angle → 0")
		parentEntity.body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
		# NOTE: Allow the ship or vehicle to slide laterally against orthogonal walls.
		# This may be the behavior most convenient and expected for the player.
		parentEntity.body.wall_min_slide_angle = 0
	else:
		printWarning("Missing parentEntity.body: " + parentEntity.logName)
	
	characterBodyComponent.didMove.connect(self.characterBodyComponent_didMove)


func _physics_process(delta: float) -> void:
	if not isEnabled: return
	
	processInput(delta)
	#applyDefaultVelocity(delta) # TBD: Is a separate function useful?
	clampVelocity(delta)
	
	characterBodyComponent.queueMoveAndSlide()


func characterBodyComponent_didMove() -> void:
	# lastVelocity = body.velocity # Handled by CharacterBodyComponent

	# Avoid the "glue effect" where the character sticks to a wall until the velocity changes to the opposite direction.
	parentEntity.callOnceThisFrame(Tools.resetBodyVelocityIfZeroMotion, [body]) # TBD: Should this be optional?

	#showDebugInfo()


func processInput(delta: float) -> void:
	if not isEnabled: return
	
	# Get the input direction and handle the movement/deceleration.
		
	self.inputDirection = Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
		
	if not inputDirection.is_zero_approx(): lastInputDirection = inputDirection
		
	# Calculate separate velocities for X and Y
	var inputVelocity := Vector2(inputDirection.x * parameters.horizontalSpeed, inputDirection.y * parameters.verticalSpeed)
	
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
	
	# Apply a constant velocity for the scrolling game
	# TBD: Should this be applied here or in applyDefaultVelocity()?
	# CHECK: Is this the correct way? Seems to work right in all cases tested so far.
	
	if is_zero_approx(inputDirection.x):
		body.velocity.x = parameters.horizontalVelocityDefault
		
	if is_zero_approx(inputDirection.y):
		body.velocity.y = parameters.verticalVelocityDefault
		
	# Disable friction by maintaining velcoty fron the previous frame?

	if parameters.shouldMaintainPreviousVelocity and not inputDirection:
		body.velocity = characterBodyComponent.previousVelocity

	# Last direction

	if not body.velocity.is_zero_approx():
		#if currentState == State.idle: currentState = State.walk
		lastDirection = body.velocity.normalized()


func applyDefaultVelocity(_delta: float) -> void:
	# TBD: Is this necessary as separate function or should this be done in processInput()?
	if not isEnabled: return
	
	# Apply the constant thrust for an axis if there is no player input on that axis.
	# NOTE: Respect the direction (positive or negative) of the parameters. i.e. Do NOT use `* sign(velocity)`
	
	# NOTE: Do NOT apply acceleration here. [move_toward()] applies very slowly because of `delta`.
	
	if is_zero_approx(inputDirection.x) \
	and not is_zero_approx(parameters.horizontalVelocityDefault) \
	and abs(body.velocity.x) < abs(parameters.horizontalVelocityDefault):
		body.velocity.x = parameters.horizontalVelocityDefault
	
	if is_zero_approx(inputDirection.y) \
	and not is_zero_approx(parameters.verticalVelocityDefault) \
	and abs(body.velocity.y) < abs(parameters.verticalVelocityDefault):
		body.velocity.y = parameters.verticalVelocityDefault
		
	
func clampVelocity(_delta: float) -> void:
	# TODO: Better performance by using cached vectors?
	# NOTE: Do NOT apply acceleration here. [move_toward()] applies very slowly because of `delta`.
	
	body.velocity.x = clampf(body.velocity.x, parameters.horizontalVelocityMin, parameters.horizontalVelocityMax)
	body.velocity.y = clampf(body.velocity.y, parameters.verticalVelocityMin, parameters.verticalVelocityMax)
	

func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList[str("\n —", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.lastInput		= lastInputDirection
	Debug.watchList.lastDirection	= lastDirection
