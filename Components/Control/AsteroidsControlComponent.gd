## Lets the player move by rotating left or right, and thrust forward, and brake.
## Similar to Asteroids; a common control scheme for spaceships or "tank"-like movement.
## NOTE: This component is an independent and more advanced alternative to combining [TurningControlComponent] + [ThrustControlComponent], and it does not depend on [PlayerInputComponent].
## Requirements: BEFORE [CharacterBodyComponent]
## @experimental

class_name AsteroidsControlComponent
extends CharacterBodyDependentComponentBase


#region Parameters
@export var isEnabled:  bool = true
@export var parameters: AsteroidsMovementParameters = AsteroidsMovementParameters.new()
#endregion


#region State
var horizontalInput:	float ## Turning
var verticalInput:		float ## Thrust

var inputDirection:		Vector2
var lastInputDirection:	Vector2
var lastDirection:		Vector2 ## Normalized
var lastVelocity:		Vector2
#endregion


func _ready() -> void:
	if parentEntity.body:
		printLog("parentEntity.body.motion_mode → Floating")
		parentEntity.body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	else:
		printWarning("Missing parentEntity.body: " + parentEntity.logName)


func _physics_process(delta: float) -> void:
	if not isEnabled: return
	processInput(delta)
	characterBodyComponent.queueMoveAndSlide()
	lastVelocity = body.velocity # TBD: Should this come last?

	# Avoid the "glue effect" where the character sticks to a wall until the velocity changes to the opposite direction.
	parentEntity.callOnceThisFrame(Tools.resetBodyVelocityIfZeroMotion, [body]) # TBD: Should this be optional?

	#showDebugInfo()


## Get the input direction and handle the movement/deceleration.
func processInput(delta: float) -> void:
	if not isEnabled: return

	self.inputDirection = Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
	self.horizontalInput = Input.get_axis(GlobalInput.Actions.turnLeft, GlobalInput.Actions.turnRight)
	self.verticalInput = Input.get_axis(GlobalInput.Actions.moveBackward, GlobalInput.Actions.moveForward)

	if inputDirection: lastInputDirection = inputDirection

	var bodyDirection: Vector2 = Vector2.from_angle(body.rotation) # No need for [.normalized()]

	# Turn

	if horizontalInput:
		body.rotation += (parameters.turningSpeed * horizontalInput) * delta

	# Thrust

	if parameters.shouldApplyAcceleration:
		body.velocity = body.velocity.move_toward(bodyDirection * verticalInput * parameters.thrust, parameters.acceleration * delta)
	else:
		body.velocity = bodyDirection * verticalInput * parameters.thrust

	# TODO: ? Compare setting vector components separately vs together

	# Friction?

	if parameters.shouldApplyFriction:

		if is_zero_approx(verticalInput):
			body.velocity = body.velocity.move_toward(Vector2.ZERO, parameters.friction * delta)

	# Disable friction by maintaining velcoty fron the previous frame?

	if parameters.shouldMaintainPreviousVelocity and not inputDirection:
		body.velocity = lastVelocity
	
	return
	
	# TODO: TBD: Minimum velocity?

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


## TODO: Not implemented
func processFriction(_delta: float) -> void:
	pass


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList[str("\n —", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.velocity = body.velocity
	Debug.watchList.wallNormal = body.get_wall_normal()
	Debug.watchList.lastMotion = body.get_last_motion()

	Debug.watchList.bodyDirection = Vector2.from_angle(body.rotation)
	Debug.watchList.horizontalInput = horizontalInput
	Debug.watchList.verticalInput = verticalInput
