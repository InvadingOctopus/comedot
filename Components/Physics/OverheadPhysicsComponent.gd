## Processes the friction and other physics for overhead-view (i.e. "top-down") movement for the parent [Entity]'s [CharacterBodyComponent].
## NOTE: Does NOT handle player input. Control is provided by [InputComponent] and/or AI agents etc.
## This component will still process friction even if no input source is present.
## Requirements: BEFORE [CharacterBodyComponent] & [InputComponent]

class_name OverheadPhysicsComponent
extends CharacterBodyDependentComponentBase


#region Parameters
@export var parameters: OverheadMovementParameters = OverheadMovementParameters.new()
@export var isEnabled:  bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_physics_process(isEnabled) # PERFORMANCE: Set once instead of every frame
			if not isEnabled: self.movementDirection = Vector2.ZERO # Reset other flags only once
#endregion


#region State
@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent) # Include subclasses to allow AI etc. Optional dependency; this component may still process friction even if no input source is present.
var movementDirection: Vector2
#endregion


#region Initialization

func _ready() -> void:
	# Set the entity's [CharacterBody2D] motion mode to Floating.
	if characterBodyComponent and characterBodyComponent.body:
		printLog("characterBodyComponent.body.motion_mode → Floating")
		characterBodyComponent.body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

		if not characterBodyComponent.shouldResetVelocityIfZeroMotion:
			printDebug("Recommend characterBodyComponent.shouldResetVelocityIfZeroMotion = true")
			# characterBodyComponent.shouldResetVelocityIfZeroMotion = true

		# UNUSED: characterBodyComponent.didMove.connect(self.characterBodyComponent_didMove) # PERFORMANCE: Reset state directly instead of via signal for now
	else:
		printWarning("Missing CharacterBody2D in Entity: " + parentEntity.logName)

	self.set_physics_process(isEnabled) # Apply setter because Godot doesn't on initialization

#endregion


#region Update Cycle

func _physics_process(delta: float) -> void:
	# DEBUG: printLog("_physics_process()")

	self.movementDirection = inputComponent.movementDirection
	processMovement(delta)
	characterBodyComponent.shouldMoveThisFrame = true

	# Clear the input from carrying over to the next frame
	movementDirection = Vector2.ZERO # TBD: Should the "no input" state just be a `0` or some other flag?

	if debugMode: showDebugInfo()


## Get the input direction and handle the movement/deceleration.
func processMovement(delta: float) -> void:
	if not isEnabled: return

	# Input is provided by [InputComponent] or an AI

	if parameters.shouldApplyAcceleration:
		body.velocity = body.velocity.move_toward(movementDirection * parameters.speed, parameters.acceleration * delta)
	else:
		body.velocity = movementDirection * parameters.speed

	# TODO: Compare setting vector components separately vs together

	# Friction?

	if parameters.shouldApplyFriction:

		if is_zero_approx(movementDirection.x):
			body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.friction * delta)

		if is_zero_approx(movementDirection.y):
			body.velocity.y = move_toward(body.velocity.y, 0.0, parameters.friction * delta)

	# Disable friction by maintaining velcoty from the previous frame?

	if parameters.shouldMaintainPreviousVelocity and not movementDirection:
		body.velocity = characterBodyComponent.previousVelocity

	# Minimum velocity?

	if parameters.shouldMaintainMinimumVelocity:
		if body.velocity.length() < parameters.minimumSpeed:
			if body.velocity.is_zero_approx():
				body.velocity = characterBodyComponent.previousVelocity.normalized() * parameters.minimumSpeed
			else:
				body.velocity = body.velocity.normalized() * parameters.minimumSpeed

#endregion


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.addComponentWatchList(self, {
		movementDirection	= movementDirection,
		velocity			= body.velocity})
