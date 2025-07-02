## Lets the player move by rotating left or right, and thrust forward, and brake.
## Similar to Asteroids; a common control scheme for spaceships or "tank"-like movement.
## NOTE: This component is a unified and more advanced alternative to combining [TurningControlComponent] + [ThrustControlComponent].
## TIP: Use [member TurningControlComponent.useLookDirectionInsteadOfTurnInput] to independently rotate a separate gun node in dual-stick shoot-em-up guns etc.
## Requirements: BEFORE [CharacterBodyComponent] & [InputComponent], NO [OverheadPhysicsComponent]
## @experimental

class_name AsteroidsControlComponent
extends CharacterBodyDependentComponentBase


#region Parameters

@export var isEnabled:  bool = true:
	set(newValue):
		isEnabled = newValue # Don't bother checking for a change
		self.set_physics_process(isEnabled) # PERFORMANCE: Set once instead of every frame

@export var parameters: AsteroidsMovementParameters = AsteroidsMovementParameters.new()

## Removes any leftover "ghost" velocity when the net motion is zero.
## Enable to avoid the "glue effect" where the character sticks to a wall until the velocity changes to the opposite direction.
## Applied after [method CharacterBody2D.move_and_slide]
@export var shouldResetVelocityIfZeroMotion: bool = false

#endregion


#region State
var turnInput:			float ## Turning
var thrustInput:		float ## Thrust

var lastDirection:		Vector2 ## Normalized
var lastVelocity:		Vector2
var lastMotionCached:	Vector2 ## NOTE: Used for and updated ONLY IF [member shouldResetVelocityIfZeroMotion] is `true`.
#endregion


#region Dependencies
@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent) # Include subclasses

func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent, InputComponent]
#endregion


func _ready() -> void:
	if parentEntity.body:
		printLog("parentEntity.body.motion_mode → Floating")
		parentEntity.body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	else:
		printWarning("Missing parentEntity.body: " + parentEntity.logName)

	Tools.connectSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput)
	self.set_physics_process(isEnabled) # Apply setter because Godot doesn't on initialization


#region Update

func onInputComponent_didProcessInput(_event: InputEvent) -> void:
	# Cache InputComponent state for convenient local access
	self.turnInput   = inputComponent.turnInput
	self.thrustInput = inputComponent.thrustInput


## Get the input direction and handle the movement/deceleration.
func processInput(delta: float) -> void:
	if not isEnabled: return

	# Turn

	if not is_zero_approx(turnInput):
		body.rotation += (parameters.turningSpeed * turnInput) * delta

	# Thrust

	if not is_zero_approx(thrustInput):
		var bodyDirection: Vector2 = Vector2.from_angle(body.rotation) # No need for .normalized()

		# Apply acceleration or move directly?
		if parameters.shouldApplyAcceleration:
			body.velocity = body.velocity.move_toward(bodyDirection * thrustInput * parameters.thrust, parameters.acceleration * delta)
		else:
			body.velocity = bodyDirection * thrustInput * parameters.thrust

	# TODO: CHECK: Compare setting vector components separately vs together


func _physics_process(delta: float) -> void:
	processInput(delta)

	# Friction?

	if parameters.shouldApplyFriction:

		if is_zero_approx(thrustInput):
			body.velocity = body.velocity.move_toward(Vector2.ZERO, parameters.friction * delta)

	# Disable friction by maintaining velcoty from the previous frame?

	if parameters.shouldMaintainPreviousVelocity and is_zero_approx(thrustInput):
		body.velocity = lastVelocity

	# TODO: TBD: Minimum velocity?

	# if parameters.shouldMaintainMinimumVelocity:
	# 	if body.velocity.length() < parameters.minimumSpeed:
	# 		if body.velocity.is_zero_approx():
	# 			body.velocity = self.lastVelocity.normalized() * parameters.minimumSpeed
	# 		else:
	# 			body.velocity = body.velocity.normalized() * parameters.minimumSpeed

	# Apply movement

	characterBodyComponent.shouldMoveThisFrame = true
	lastVelocity = body.velocity # TBD: Should this come last?

	# Last direction

	if not body.velocity.is_zero_approx():
		#if currentState == State.idle: currentState = State.walk
		lastDirection = body.velocity.normalized()

	# Avoid the "glue effect" where the character sticks to a wall until the velocity changes to the opposite direction.
	if self.shouldResetVelocityIfZeroMotion:
		# TBD: PERFORMANCE: Should `entity.callOnceThisFrame()` be used, or call `Tools.resetBodyVelocityIfZeroMotion()` directly?
		# PERFORMANCE: Perform the calculations here instead of calling `Tools.resetBodyVelocityIfZeroMotion()` every frame.
		self.lastMotionCached = body.get_last_motion() # Use a permanent property instead of a new variable each frame :')
		if is_zero_approx(lastMotionCached.x): body.velocity.x = 0
		if is_zero_approx(lastMotionCached.y): body.velocity.y = 0

	if debugMode: showDebugInfo()


#endregion


func showDebugInfo() -> void:
	# if not debugMode: return # Checked by caller
	Debug.addComponentWatchList(self, {
		velocity		= body.velocity,
		wallNormal		= body.get_wall_normal(),
		lastMotion		= body.get_last_motion(),
		bodyDirection	= Vector2.from_angle(body.rotation),
		turnInput		= turnInput,
		thrustInput		= thrustInput,
		})
