## Handles the physics for gravity and friction for the entity's [CharacterBody2D] in a "platform" world.
## This allows player characters as well as monsters to share the same movement logic.
## NOTE: Does NOT handle player input. Control is provided by [PlatformerControlComponent], [PlatformerJumpComponent] and AI components etc.
## WARNING: Do NOT use in conjunction with [GravityComponent] because this component also processes gravity.
## Requirements: BEFORE [CharacterBodyComponent], AFTER [PlatformerControlComponent] and other physics modifying components.

class_name PlatformerPhysicsComponent
extends CharacterBodyDependentComponentBase

# CREDIT: THANKS: https://github.com/uheartbeast — https://github.com/uheartbeast/Heart-Platformer-Godot-4 — https://youtu.be/M8-JVjtJlIQ


#region Parameters

## Applied to the [member PlatformerMovementParameters.gravityScale].
## May be used for incidental situations such as flipping the gravity direction without modifying the base parameters.
@export_range(-10, 10, 0.05) var gravityScaleOverride: float = 1.0

@export var isGravityEnabled: bool = true ## Allows gravity to be temporarily disabled e.g. when climbing or flying etc.

@export var isEnabled: bool = true: ## NOTE: Does not affect manual function calls such as [method applyFrictionOnFloor] etc.
	set(newValue):
		isEnabled = newValue
		if not isEnabled:
			# Reset other flags only once
			self.inputDirection = 0
			self.isInputZero = true
			self.set_physics_process(isEnabled) # PERFORMANCE: Set once instead of every frame

@export var parameters: PlatformerMovementParameters = PlatformerMovementParameters.new()

#endregion


#region State

enum State { idle, moveOnFloor, moveInAir }

var currentState: State #:
	# DEBUG: set(newValue):
	# 	Debug.printChange("currentState", currentState, newValue)
	# 	currentState = newValue

@export_storage var inputDirection:		float
@export_storage var lastInputDirection:	float
var isInputZero: bool = true

var gravity: float = Settings.gravity

#endregion


func _ready() -> void:
	self.currentState = State.idle
	if characterBodyComponent and characterBodyComponent.body:
		printLog("characterBodyComponent.body.motion_mode → Grounded")
		characterBodyComponent.body.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
		characterBodyComponent.didMove.connect(self.characterBodyComponent_didMove)
	else:
		printWarning("Missing CharacterBody2D in Entity: " + parentEntity.logName)

	if coComponents.get("GravityComponent"):
		printWarning("PlatformerPhysicsComponent & GravityComponent both process gravity; Remove one!")
	
	self.set_physics_process(isEnabled) # Apply setter because Godot doesn't on initialization


#region Control

## If the [CharacterBodyComponent] [member CharacterBody2D.is_on_floor] and the rectangular bounds of the [CharacterBody2D]'s [CollisionShape2D] are not fully inside the specified [Rect2],
## then [member inputDirection] is set to make the character walk towards the rectangle's interior until the character is fully enclosed.
## IMPORTANT: The [param targetRect] must be in the global coordinate space.
## Returns: The displacement/offset outside the [param targetRect] (BEFORE the movement).
## @experimental
func walkIntoRect(targetRect: Rect2) -> Vector2:
	# CHECK: Fix seemingly unnecessary inertia?

	var displacement: Vector2 = Tools.getRectOffsetOutsideContainer(Tools.getShapeGlobalBounds(characterBodyComponent.body), targetRect)
	# Walk into the interior
	if not displacement.is_zero_approx():
		# NOTE: Use the INVERSE of the displacement, because -1.0 means we're sticking out to the LEFT, so we need to move to the RIGHT
		self.inputDirection = signf(-displacement.x) # Clamp input range to 0.0…1.0
	# Return the updated displacement
	return displacement

#endregion


#region Update Cycle

func _physics_process(delta: float) -> void:
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube
	# NOTE: The order of processing is as per Heartbeast's tutorial.

	if not isEnabled: return

	# Sanitize the control input and prepare flags etc. for use by other functions.
	processInput()
	updateStateBeforeMove()

	# Fall the Fall
	processGravity(delta)

	# Walk the Walk
	processHorizontalMovement(delta) # = applyAccelerationOnFloor(delta) & applyAccelerationInAir(delta)
	processAllFriction(delta) # = applyFrictionOnFloor(delta) & applyFrictionInAir(delta)

	# Move Your Body ♪
	characterBodyComponent.shouldMoveThisFrame = true


func updateStateBeforeMove() -> void:
	# NOTE: `currentState` MUST be updated BEFORE `CharacterBody2D.move_and_slide(])` and AFTER `processInput()`
	# DESIGN: Using `match` here may seem too cluttered and ambiguous

	if currentState == State.idle and not isInputZero:
		# CHECK: Should this be done in `processInput()` so that there is only one check for [isInputZero]?
		currentState = State.moveOnFloor if characterBodyComponent.isOnFloor else State.moveInAir

	if currentState != State.idle and body.velocity.is_zero_approx():
		currentState = State.idle


## Prepares player input processing, after the input is provided by other components like [PlatformerPhysicsControlComponent] and AI agents.
## Affected by [member isEnabled].
func processInput() -> void:
	# TBD: Should be guarded by [isEnabled] or should the flags etc. always be updated?
	if not isEnabled: return

	# NOTE: The input direction is provided by other components like [PlatformerPhysicsControlComponent] and AI agents.
	# self.inputDirection = Input.get_axis(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight)

	# Cache properties that are accessed often to avoid repeated function calls on other objects.

	self.isInputZero = is_zero_approx(inputDirection)

	if not isInputZero: lastInputDirection = inputDirection

	# NOTE: DESIGN: Accept input in air even if [member shouldAllowMovementInputInAir] is `false`,
	# so that some games can let the player turn around to shoot in any direction while in air, for example.


func characterBodyComponent_didMove(_delta: float) -> void:
	if debugMode: showDebugInfo()
	# NOTE: PERFORMANCE: There may be a performance impact from using signals every frame,
	# but the input is cleared after the [CharacterBodyComponent] moves so that other components may inspect and act upon the input of this component for this frame.

	# Clear the input so it doesn't carry on over to the next frame.
	clearInput()


func clearInput() -> void:
	inputDirection = 0 # TBD: Should the "no input" state just be a `0` or some other flag?

#endregion


#region Platformer Physics


func processGravity(delta: float) -> void:
	if not isGravityEnabled: return
	# Vertical Slowdown
	if not body.is_on_floor(): # ATTENTION: Cache [isOnFloor] AFTER processing gravity.
		body.velocity.y += (gravity * parameters.gravityScale * self.gravityScaleOverride) * delta

	if debugMode and not body.velocity.is_equal_approx(characterBodyComponent.previousVelocity): printDebug(str("body.velocity after processGravity(): ", body.velocity))


## Applies movement with or without gradual acceleration depending on the [member shouldApplyAccelerationOnFloor] or [member shouldApplyAccelerationInAir] flags.
## NOTE: NOT affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
func processHorizontalMovement(delta: float) -> void:
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

	if debugMode and not body.velocity.is_equal_approx(characterBodyComponent.previousVelocity): printDebug(str("body.velocity after processHorizontalMovement(): ", body.velocity))


## Applies friction if there is no player input and either [member shouldApplyFrictionOnFloor] or [member shouldApplyFrictionInAir] is `true`.
## NOTE: NOT affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
## WARNING: May prevent components like [KnockbackOnHitComponent] from working.
func processAllFriction(delta: float) -> void:
	# Don't apply friction if the player is trying to move;
	# only apply friction to slow down when there is no player input, OR
	# NOTE: If movement is not allowed in air, then apply air friction regardless of player input.

	if characterBodyComponent.isOnFloor and isInputZero:
		if parameters.shouldStopInstantlyOnFloor:
			body.velocity.x = 0 # TBD: Ensure that the body can be moved by other forces?
		elif parameters.shouldApplyFrictionOnFloor:
			body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionOnFloor * delta)
	elif (not characterBodyComponent.isOnFloor) and (isInputZero or not parameters.shouldAllowMovementInputInAir):
		if parameters.shouldStopInstantlyInAir:
			body.velocity.x = 0 # TBD: Ensure that the body can be moved by other forces?
		elif parameters.shouldApplyFrictionInAir:
			body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionInAir * delta)

	if debugMode and not body.velocity.is_equal_approx(characterBodyComponent.previousVelocity): printDebug(str("body.velocity after processAllFriction(): ", body.velocity))

#endregion


#region Standalone Functions

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ
# DESIGN: Do not check for `isEnabled` or other flags here as they should be checked by the callers.

## Applies [member accelerationOnFloor] regardless of [member shouldApplyAccelerationOnFloor]; flags should be checked by caller.
func applyAccelerationOnFloor(delta: float) -> void:
	if (not isInputZero) and characterBodyComponent.isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, parameters.speedOnFloor * inputDirection, parameters.accelerationOnFloor * delta)


## Applies [member accelerationInAir] regardless of [member shouldApplyAccelerationInAir]; flags should be checked by caller.
func applyAccelerationInAir(delta: float) -> void:
	if (not isInputZero) and (not characterBodyComponent.isOnFloor):
		body.velocity.x = move_toward(body.velocity.x, parameters.speedInAir * inputDirection, parameters.accelerationInAir * delta)


## Applies [member frictionOnFloor] regardless of [member shouldApplyFrictionOnFloor]; flags should be checked by caller.
func applyFrictionOnFloor(delta: float) -> void:
	# Friction on floor should only be applied if there is no input;
	# otherwise the player would not be able to start moving in the first place!
	if isInputZero and characterBodyComponent.isOnFloor:
		if parameters.shouldStopInstantlyOnFloor:
			# TBD: Ensure that the body can be moved by other forces?
			body.velocity.x = 0
		elif parameters.shouldApplyFrictionOnFloor:
			body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionOnFloor * delta)


## Applies [member frictionInAir] regardless of [member shouldApplyFrictionInAir]; flags should be checked by caller.
func applyFrictionInAir(delta: float) -> void:
	# If movement is not allowed in air, then apply air friction regardless of player input.
	if (isInputZero or not parameters.shouldAllowMovementInputInAir) and (not characterBodyComponent.isOnFloor):
		if parameters.shouldStopInstantlyInAir:
			body.velocity.x = 0 # TBD: Ensure that the body can be moved by other forces?
		elif parameters.shouldApplyFrictionInAir:
			body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionInAir * delta)

#endregion


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.addComponentWatchList(self, {
		state = currentState,
		input = inputDirection,
		})

	# Friction?
	if characterBodyComponent.isOnFloor and parameters.shouldApplyFrictionOnFloor and isInputZero:
		Debug.watchList.friction = "floor"
	elif (not characterBodyComponent.isOnFloor) and parameters.shouldApplyFrictionInAir and (isInputZero or not parameters.shouldAllowMovementInputInAir):
		Debug.watchList.friction = "air"
	else:
		Debug.watchList.friction = "none"

	# TODO: Combine into addComponentWatchList()
