## Handles horizontal movement in a "platform" world.
## NOTE: Gravity is handled by [GravityComponent]. Jumping is handled by [JumpControlComponent].
## Requirements: Entity with [CharacterBody2D]

class_name PlatformerControlComponent
extends CharacterBodyManipulatingComponentBase

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ

#region Parameters
@export var isEnabled: bool = true
@export var parameters: PlatformerMovementParameters = PlatformerMovementParameters.new()
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

var inputDirectionOverride:	float = 0 ## Overrides [member inputDirection] for example to allow control by AI agents. NOTE: Reset to 0 every frame.
var inputDirection:			float
var lastInputDirection:		float
var isInputZero:			bool = true

#endregion


func _ready() -> void:
	self.currentState = State.idle
	if parentEntity.body:
		printLog("parentEntity.body.motion_mode → Grounded")
		parentEntity.body.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	else:
		printWarning("Missing parentEntity.body: " + parentEntity.logName)


func _physics_process(delta: float) -> void:
	# DEBUG: printLog("_physics_process()")
	if not isEnabled: return

	processInput()
	updateState()

	#applyAccelerationOnFloor(delta)
	#applyAccelerationInAir(delta)
	processAllMovement(delta)
	#applyFrictionOnFloor(delta)
	#applyFrictionInAir(delta)
	processAllFriction(delta)
	
	characterBodyComponent.queueMoveAndSlide()
	
	#showDebugInfo()


## NOTE: MUST be called AFTER [processInput]
func updateState():
	# DESIGN: Using `match` here may seem too cluttered and ambiguous

	if currentState == State.idle and not isInputZero:
		# CHECK: Should this be done in [processInput()] so that there is only one check for [isInputZero]?
		currentState = State.moveOnFloor if characterBodyComponent.isOnFloor else State.moveInAir

	if currentState != State.idle and is_zero_approx(body.velocity.x) and is_zero_approx(body.velocity.y):
		currentState = State.idle


## Handles player input.
## Affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
func processInput():
	if not isEnabled: return

	# Get the input direction and handle the movement/deceleration.
	if inputDirectionOverride:
		self.inputDirection = inputDirectionOverride
	else:
		self.inputDirection = Input.get_axis(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight)

	# Reset the override.
	inputDirectionOverride = 0

	# Cache properties that are accessed often to avoid repeated function calls on other objects.
	self.isInputZero = is_zero_approx(inputDirection)

	if not isInputZero: lastInputDirection = inputDirection

	# NOTE: DESIGN: Accept input in air even if [member PlatformerMovementParameters.shouldAllowMovementInputInAir] is `false`,
	# so that some games can let the player turn around to shoot in any direction while in air, for example.


## Applies movement with or without gradual acceleration depending on the [member shouldApplyAccelerationOnFloor] or [member shouldApplyAccelerationInAir] flags.
## NOTE: NOT affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
func processAllMovement(delta: float):
	# Nothing to do if there is no player input.
	if isInputZero: return

	if characterBodyComponent.isOnFloor: # Are we on the floor?
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

	if characterBodyComponent.isOnFloor and parameters.shouldApplyFrictionOnFloor and isInputZero:
		body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionOnFloor * delta)
	elif (not characterBodyComponent.isOnFloor) and parameters.shouldApplyFrictionInAir and (isInputZero or not parameters.shouldAllowMovementInputInAir):
		body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionInAir * delta)


#region Standalone Functions

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ

## Applies [member accelerationOnFloor] regardless of [member shouldApplyAccelerationOnFloor]; this flag should be checked by caller.
func applyAccelerationOnFloor(delta: float):
	if (not isInputZero) and characterBodyComponent.isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, parameters.speedOnFloor * inputDirection, parameters.accelerationOnFloor * delta)


## Applies [member accelerationInAir] regardless of [member shouldApplyAccelerationInAir]; this flag should be checked by caller.
func applyAccelerationInAir(delta: float):
	if (not isInputZero) and (not characterBodyComponent.isOnFloor):
		body.velocity.x = move_toward(body.velocity.x, parameters.speedInAir * inputDirection, parameters.accelerationInAir * delta)


## Applies [member frictionOnFloor] regardless of [member shouldApplyFrictionOnFloor]; this flag should be checked by caller.
func applyFrictionOnFloor(delta: float):
	# Friction on floor should only be applied if there is no input;
	# otherwise the player would not be able to start moving in the first place!
	if isInputZero and characterBodyComponent.isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionOnFloor * delta)


## Applies [member frictionInAir] regardless of [member shouldApplyFrictionInAir]; this flag should be checked by caller.
func applyFrictionInAir(delta: float):
	# If movement is not allowed in air, then apply air friction regardless of player input.
	if (isInputZero or not parameters.shouldAllowMovementInputInAir) and (not characterBodyComponent.isOnFloor):
		body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionInAir * delta)

#endregion


func showDebugInfo():
	Debug.watchList.input = inputDirection

	# Friction?
	if characterBodyComponent.isOnFloor and parameters.shouldApplyFrictionOnFloor and isInputZero:
		Debug.watchList.friction = "floor"
	elif (not characterBodyComponent.isOnFloor) and parameters.shouldApplyFrictionInAir and (isInputZero or not parameters.shouldAllowMovementInputInAir):
		Debug.watchList.friction = "air"
	else:
		Debug.watchList.friction = "none"
