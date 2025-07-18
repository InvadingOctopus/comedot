## Handles the physics for gravity and friction for the entity's [CharacterBody2D] in a "platform" world.
## This allows player characters as well as monsters to share the same movement logic.
## NOTE: Does NOT handle player input. Control is provided by [InputComponent], [JumpComponent] and/or AI components etc.
## This component will still process gravity & friction even if no input source is present.
## WARNING: Do NOT use in conjunction with [GravityComponent] because this component ALSO processes gravity. Using both will cause excessive gravity!
## Requirements: BEFORE [CharacterBodyComponent] & [InputComponent], AFTER other physics modifying components.

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
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_physics_process(isEnabled) # PERFORMANCE: Set once instead of every frame
			if not isEnabled: self.horizontalInput = 0 # Reset other flags only once

@export var parameters: PlatformerMovementParameters = PlatformerMovementParameters.new()

#endregion


#region State

enum State { idle, moveOnFloor, moveInAir }

var currentState: State #:
	# DEBUG: set(newValue):
	# 	Debug.printChange("currentState", currentState, newValue)
	# 	currentState = newValue

@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent) # Include subclasses to allow AI etc. Optional dependency; this component may still process gravity & friction even if no input source is present.

# TBD: Remove input state duplication? DESIGN: It's better to cache some state like `isInputZero` anyway…

var isInputZero:		bool = true
var horizontalInput:	float: ## Copied from [InputComponent]. ALERT: Should NOT be directly modified by other components!
	set(newValue):
		if newValue != horizontalInput:
			if debugMode: Debug.printChange("horizontalInput", horizontalInput, newValue, self.debugModeTrace) # logAsTrace
			horizontalInput = newValue
			isInputZero = is_zero_approx(horizontalInput)
			if not isInputZero: lastNonzeroHorizontalInput = horizontalInput

var lastNonzeroHorizontalInput: float

var gravity: float = Settings.gravity

# DESIGN: The "skip" flags are not a "disable" toggle because if multiple components want to disable acceleration or friction,
# then 1 component re-enabling a flag could ruin everything.
# TBD: Separate flags for ground & air?

## When `true` then acceleration is skipped for ONE frame.
## This allows other components to temporarily disable acceleration during special gameplay situations etc.
## Whether it's the current frame or the next depends on whether this flag is set before or after [PlatformerPhysicsComponent]'s [method _physics_process].
var shouldSkipAcceleration: bool:
	set(newValue):
		if newValue != shouldSkipAcceleration:
			if debugMode: Debug.printChange("shouldSkipAcceleration", shouldSkipAcceleration, newValue, self.debugModeTrace) # logAsTrace
			shouldSkipAcceleration = newValue

## When `true` then friction is skipped for ONE frame.
## This allows other components to temporarily disable friction during special gameplay situations etc.
## Whether it's the current frame or the next depends on whether this flag is set before or after [PlatformerPhysicsComponent]'s [method _physics_process].
var shouldSkipFriction: bool:
	set(newValue):
		if newValue != shouldSkipFriction:
			if debugMode: Debug.printChange("shouldSkipFriction", shouldSkipFriction, newValue, self.debugModeTrace) # logAsTrace
			shouldSkipFriction = newValue

#endregion


#region Initialization

func _ready() -> void:
	self.currentState = State.idle
	if characterBodyComponent and characterBodyComponent.body:
		printLog("characterBodyComponent.body.motion_mode → Grounded")
		characterBodyComponent.body.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	else:
		printWarning("Missing CharacterBody2D in Entity: " + parentEntity.logName)

	if coComponents.get("GravityComponent"):
		printWarning("PlatformerPhysicsComponent & GravityComponent both process gravity; Remove one!")

	self.set_physics_process(isEnabled) # Apply setter because Godot doesn't on initialization

#endregion


#region Update Cycle

func _physics_process(delta: float) -> void:
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube
	# NOTE: The order of processing is as per Heartbeast's tutorial.
	# DESIGN: PERFORMANCE: Putting all code in one function may improve performance,
	# but splitting each distinct task into separate functions may help readability & makes shit easy to understand.

	# NOTE: DESIGN: Accept input in air even if [member shouldAllowMovementInputInAir] is `false`,
	# so that some games can let the player turn around to shoot in any direction while in air, for example.
	
	# Prep the Prep
	# Cache properties that are accessed often to avoid repeated function calls on other objects.
	# NOTE: CHECK: Probably a good idea to create local copies in case [InputComponent]'s state changes bedcause of input received while we are still processing the current frame.
	self.horizontalInput = inputComponent.horizontalInput if inputComponent else 0.0

	updateStateBeforeMove()

	# Fall the Fall
	processGravity(delta)

	# Walk the Walk
	processHorizontalMovement(delta) # = applyAccelerationOnFloor(delta) & applyAccelerationInAir(delta) (`shouldSkipAcceleration` checked in function)

	# Fric the Fric
	if not shouldSkipFriction: processAllFriction(delta) # = applyFrictionOnFloor(delta) & applyFrictionInAir(delta)
	else:  shouldSkipFriction = false # Don't skip next frame, unless another component re-enables the skip flag.

	# Move Your Body ♪
	characterBodyComponent.shouldMoveThisFrame = true
	if debugMode: showDebugInfo()


func updateStateBeforeMove() -> void:
	# NOTE: `currentState` MUST be updated BEFORE `CharacterBody2D.move_and_slide(])` and AFTER `processInput()`
	# DESIGN: Using `match` here may seem too cluttered and ambiguous

	if currentState == State.idle and not isInputZero:
		# CHECK: Should this be done in `processInput()` so that there is only one check for [isInputZero]?
		currentState = State.moveOnFloor if characterBodyComponent.isOnFloor else State.moveInAir

	if currentState != State.idle and body.velocity.is_zero_approx():
		currentState = State.idle

#endregion


#region Platformer Physics

func processGravity(delta: float) -> void:
	if not isGravityEnabled: return
	# Vertical Slowdown
	if not body.is_on_floor(): # ATTENTION: Cache [isOnFloor] AFTER processing gravity.
		body.velocity.y += (gravity * parameters.gravityScale * self.gravityScaleOverride) * delta

	if debugMode and not body.velocity.is_equal_approx(characterBodyComponent.previousVelocity): printDebug(str("body.velocity after processGravity(): ", characterBodyComponent.previousVelocity, " → ", body.velocity))


## Applies movement with or without gradual acceleration depending on the [member shouldApplyAccelerationOnFloor] or [member shouldApplyAccelerationInAir] flags.
## Skipped by [member shouldSkipAcceleration] and resets that flag.
## NOTE: NOT affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
func processHorizontalMovement(delta: float) -> void:
	# Nothing to do if there is no player input.
	if isInputZero: return

	if characterBodyComponent.isOnFloor: # Are we on the floor?
		if not shouldSkipAcceleration and parameters.shouldApplyAccelerationOnFloor: # Apply the speed gradually or instantly?
			body.velocity.x = move_toward(body.velocity.x, parameters.speedOnFloor * horizontalInput, parameters.accelerationOnFloor * delta)
		else:
			body.velocity.x = horizontalInput * parameters.speedOnFloor

	elif parameters.shouldAllowMovementInputInAir: # Are we in the air and are movement changes allowed in air?
		if not shouldSkipAcceleration and parameters.shouldApplyAccelerationInAir: # Apply the speed gradually or instantly?
			body.velocity.x = move_toward(body.velocity.x, parameters.speedInAir * horizontalInput, parameters.accelerationInAir * delta)
		else:
			body.velocity.x = horizontalInput * parameters.speedInAir

	if debugMode and not body.velocity.is_equal_approx(characterBodyComponent.previousVelocity): printDebug(str("body.velocity after processHorizontalMovement(): ", body.velocity, " was shouldSkipAcceleration: ", shouldSkipAcceleration))
	if shouldSkipAcceleration: shouldSkipAcceleration = false # TBD: PERFORMANCE: Reset without checking?


## Applies friction if there is no player input and either [member shouldApplyFrictionOnFloor] or [member shouldApplyFrictionInAir] is `true`.
## NOTE: NOT affected by [member shouldSkipFriction]; should be checked by caller.
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

## Applies [member accelerationOnFloor] regardless of [member shouldApplyAccelerationOnFloor] or [member shouldSkipAcceleration]; flags should be checked by caller.
func applyAccelerationOnFloor(delta: float) -> void:
	if (not isInputZero) and characterBodyComponent.isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, parameters.speedOnFloor * horizontalInput, parameters.accelerationOnFloor * delta)


## Applies [member accelerationInAir] regardless of [member shouldApplyAccelerationInAir] or [member shouldSkipAcceleration]; flags should be checked by caller.
func applyAccelerationInAir(delta: float) -> void:
	if (not isInputZero) and (not characterBodyComponent.isOnFloor):
		body.velocity.x = move_toward(body.velocity.x, parameters.speedInAir * horizontalInput, parameters.accelerationInAir * delta)


## Applies [member frictionOnFloor] regardless of [member shouldApplyFrictionOnFloor] or [member shouldSkipFriction]; flags should be checked by caller.
func applyFrictionOnFloor(delta: float) -> void:
	# Friction on floor should only be applied if there is no input;
	# otherwise the player would not be able to start moving in the first place!
	if isInputZero and characterBodyComponent.isOnFloor:
		if parameters.shouldStopInstantlyOnFloor:
			# TBD: Ensure that the body can be moved by other forces?
			body.velocity.x = 0
		elif parameters.shouldApplyFrictionOnFloor:
			body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionOnFloor * delta)


## Applies [member frictionInAir] regardless of [member shouldApplyFrictionInAir] or [member shouldSkipFriction]; flags should be checked by caller.
func applyFrictionInAir(delta: float) -> void:
	# If movement is not allowed in air, then apply air friction regardless of player input.
	if (isInputZero or not parameters.shouldAllowMovementInputInAir) and (not characterBodyComponent.isOnFloor):
		if parameters.shouldStopInstantlyInAir:
			body.velocity.x = 0 # TBD: Ensure that the body can be moved by other forces?
		elif parameters.shouldApplyFrictionInAir:
			body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionInAir * delta)


## If the [CharacterBodyComponent] [member CharacterBody2D.is_on_floor] and the rectangular bounds of the [CharacterBody2D]'s [CollisionShape2D] are not fully inside the specified [Rect2],
## then [member horizontalInput] is set to make the character walk towards the rectangle's interior until the character is fully enclosed.
## IMPORTANT: The [param targetRect] must be in the global coordinate space.
## Returns: The displacement/offset outside the [param targetRect] (BEFORE the movement).
## @experimental
func walkIntoRect(targetRect: Rect2) -> Vector2:
	# CHECK: Fix seemingly unnecessary inertia?

	var displacement: Vector2 = Tools.getRectOffsetOutsideContainer(Tools.getShapeGlobalBounds(characterBodyComponent.body), targetRect)
	# Walk into the interior
	if not displacement.is_zero_approx():
		# NOTE: Use the INVERSE of the displacement, because -1.0 means we're sticking out to the LEFT, so we need to move to the RIGHT
		self.horizontalInput = signf(-displacement.x) # Clamp input range to 0.0…1.0
	# Return the updated displacement
	return displacement

#endregion


#region Debugging

func showDebugInfo() -> void:
	# if not debugMode: return # Checked by caller

	var frictionType: String # TBD: Should this be a component property?
	if shouldSkipFriction:
		frictionType = "skip" # May never be seen because it's reset in _physics_process()
	if characterBodyComponent.isOnFloor and parameters.shouldApplyFrictionOnFloor and isInputZero:
		frictionType = "floor"
	elif (not characterBodyComponent.isOnFloor) and parameters.shouldApplyFrictionInAir and (isInputZero or not parameters.shouldAllowMovementInputInAir):
		frictionType = "air"
	else:
		frictionType = "none"

	Debug.addComponentWatchList(self, {
		state = currentState,
		input = horizontalInput,
		lastInput = lastNonzeroHorizontalInput,
		friction  = frictionType,
		})

#endregion
