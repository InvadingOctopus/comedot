## Handles jumping. Applies velocity when an [InputComponent] receives the jump event.
## The direction of the jump is determined by the [member CharacterBody2D.up_direction] (only the Y axis).
## NOTE: Gravity and friction in air is handled by [PlatformerPhysicsComponent].
## TIP:  To modify the various time durations, enable "Editable Children" and edit the [Timers] nodes.
## TIP:  For "inverted gravity" jumps, modify [member CharacterBody2D.up_direction] on the [CharacterBodyComponent].
## For climbing ladders/ropes/etc. use [ClimbComponent].
## Requirements: BEFORE [PlatformerPhysicsComponent] & [CharacterBodyComponent] & [InputComponent]

class_name JumpComponent
extends CharacterBodyDependentComponentBase

# CREDIT: THANKS: https://github.com/uheartbeast — https://github.com/uheartbeast/Heart-Platformer-Godot-4 — https://youtu.be/M8-JVjtJlIQ
# TBD:  Respect the `CharacterBody2D.up_direction.x` axis too?
# TBD:  A more fail-proof way of handling short jumps. Timers?

# INFO: Velocity & Inverted Gravity
# Falling down onscreen:					velocity.y = +positive
# Jumping up onscreen:						velocity.y = -negative
# Inverted gravity: Falling up onscreen:	velocity.y = -positive
# Inverted gravity: Jumping down onscreen:	velocity.y = +positive


#region Parameters
@export var parameters: PlatformerJumpParameters = PlatformerJumpParameters.new()
@export var isEnabled:  bool = true
#endregion


#region State

## The "input buffer period" to allow the player to press the jump input a few milliseconds BEFORE landing on the floor, compensating for any visual/reaction delays.
## May improve the feel of control in some games.
@onready var inputBufferTimer:	Timer = $InputBufferTimer

## The "grace period" while the player can still jump after just having walking off a platform floor.
## May improve the feel of control in some games.
@onready var coyoteJumpTimer:	Timer = $CoyoteJumpTimer

## The period while the player can "wall jump" after just having moved away from a wall.
@onready var wallJumpTimer:		Timer = $WallJumpTimer

enum State { idle, jump }

var currentState: State

## Cache the input state so we only have to query [Input] once when there is an input event.
var jumpInput:				bool:
	set(newValue):
		if newValue != jumpInput:
			if debugMode: Debug.printChange("jumpInput", jumpInput, newValue)
			# NOTE: Derive the related flags from `jumpInput`, to allow AI/scripted input,
			# because Input.is_action_just_pressed()/released() is not fooled by InputComponent.generateEvent()
			# TBD: CHECK: Does this cause any jank behavior?
			jumpInputJustPressed  = not jumpInput and newValue # false → true?
			jumpInputJustReleased = jumpInput and not newValue # true → false?
			jumpInput = newValue

var jumpInputJustPressed:	bool:
	set(newValue):
		if newValue != jumpInputJustPressed:
			if debugMode: Debug.printChange("jumpInputJustPressed", jumpInputJustPressed, newValue)
			jumpInputJustPressed = newValue

var jumpInputJustReleased:	bool:
	set(newValue):
		if newValue != jumpInputJustReleased:
			if debugMode: Debug.printChange("jumpInputJustReleased", jumpInputJustReleased, newValue)
			jumpInputJustReleased = newValue

var currentNumberOfJumps:	int:
	set(newValue):
		if newValue != currentNumberOfJumps:
			if debugMode: Debug.printChange("currentNumberOfJumps", currentNumberOfJumps, newValue)
			currentNumberOfJumps = newValue

# CHECK: PERFORMANCE: Will all these computed properties and function calls slow things down compared to just keeping the checks inside the actual process/update methods?

## `true` if the player can initiate the first jump by pressing the input a few milliseconds BEFORE landing on the floor/ground.
## This may allow a more lenient feel of control in some games to compensate for visual/reaction delays.
var shouldBufferInput: bool:
	get: return parameters.allowInputBuffer \
		and currentNumberOfJumps < 1 \
		and not characterBodyComponent.isOnFloor \
		and is_zero_approx(inputBufferTimer.time_left) \
		and not is_zero_approx(inputBufferTimer.wait_time)

## `true` if the character can perform an initial jump from the floor/ground or via "coyote time" i.e. [member canCoyoteJump]
## The jump "height" will be the [PlatformerJumpParameters.jumpVelocity1stJump] or [PlatformerJumpParameters.jumpVelocity1stJumpShort]
## NOTE: PERFORMANCE: Does NOT check [member isEnabled] or [PlatformerJumpParameters.maxNumberOfJumps] > 0
var canFloorJump:	bool:
	get: return currentNumberOfJumps < 1 \
			and (characterBodyComponent.isOnFloor or canCoyoteJump)

## `true` if the character can perform the INITIAL jump from the floor/ground AFTER pressing the jump input IN AIR BEFORE landing.
## See [member shouldBufferInput] and [member inputBufferTimer]
## The jump "height" will be the [PlatformerJumpParameters.jumpVelocity1stJump] or [PlatformerJumpParameters.jumpVelocity1stJumpShort]
## NOTE: PERFORMANCE: Does NOT check [member isEnabled] or [PlatformerJumpParameters.maxNumberOfJumps] > 0
var canBufferedJump: bool:
	get: return parameters.allowInputBuffer \
		and currentNumberOfJumps < 1 \
		and characterBodyComponent.isOnFloor \
		and not is_zero_approx(inputBufferTimer.time_left)


## `true` if the "coyote jump" grace period is active while just walking off a floor i.e. [member coyoteJumpTimer]
## IMPORTANT: Do NOT use without also checking [member canFloorJump] first!
## NOTE: PERFORMANCE: Does NOT check [member isEnabled] or [member canFloorJump]
var canCoyoteJump:	bool:
	get: return parameters.allowCoyoteJump \
			and not is_zero_approx(coyoteJumpTimer.time_left)

## `true` if the character can perform a mid-air jump as the 1st jump while falling WITHOUT jumping from the floor/ground first.
## The jump "height" will be the [PlatformerJumpParameters.jumpVelocity1stJump] or [PlatformerJumpParameters.jumpVelocity1stJumpShort]
## NOTE: PERFORMANCE: Does NOT check [member isEnabled] or [PlatformerJumpParameters.maxNumberOfJumps] > 0
var canFallJump:		bool:
	get: return parameters.allowFallJump \
			and currentNumberOfJumps < 1 \
			and not characterBodyComponent.isOnFloor \
			and not canCoyoteJump \
			and characterBodyComponent.isFallingTowardsGravity # CHECK: PERFORMANCE: Should we check directly instead of calling another computed property? *sweatdrop*

## `true` if the character can perform a "double jump" in mid-air AFTER performing a jump from the floor/ground (2nd jump, 3rd, etc.)
## The jump "height" will be the [PlatformerJumpParameters.jumpVelocity2ndJump]
## NOTE: PERFORMANCE: Does NOT check [member isEnabled]
var canMultiJump:	bool:
	get: return parameters.maxNumberOfJumps > 1 \
			and currentNumberOfJumps > 0 \
			and currentNumberOfJumps < parameters.maxNumberOfJumps

## `true` if the character is in a valid position/state for a jumping off/away from a wall.
## IMPORTANT: Remember to also check [method getWallJumpNormal] to ensure a usable direction exists.
## NOTE: PERFORMANCE: Does NOT check [member isEnabled] or [method getWallJumpNormal] or [PlatformerJumpParameters.maxNumberOfJumps] > 0
var canWallJump:	bool:
	# 1: Can we wall-jump?
	# 2: Do we have any jumps left?
	# 3: Are we on a wall and not a floor?
	# 4: Are we Off The Wall™ but still have a grace timer left?
	# TBD: Use is_on_floor_only() and/or is_on_wall_only()?
	get: return parameters.allowWallJump \
			and currentNumberOfJumps < parameters.maxNumberOfJumps \
			and not body.is_on_floor() \
			and (body.is_on_wall() or not is_zero_approx(wallJumpTimer.time_left))

var didWallJump:	bool ## Did we just perform a "wall jump"?

#endregion


#region Dependencies
@onready var inputComponent: InputComponent = getCoComponent(InputComponent, true) # findSubclasses
@onready var platformerPhysicsComponent: PlatformerPhysicsComponent = coComponents.get(&"PlatformerPhysicsComponent") # Optional
func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent, InputComponent]
#endregion


func _ready() -> void:
	# NOTE: The initial durations should be set in the scene file for each Timer

	self.currentState = State.idle
	if characterBodyComponent: characterBodyComponent.didMove.connect(self.characterBodyComponent_didMove)
	else: printWarning("Missing CharacterBodyComponent")

	# NOTE: Just handle the input event early on instead of waiting for the `didUpdateInputActionsList` signal
	# because this component only depends on 1 event anyway: Jump.
	Tools.connectSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput)

	self.set_physics_process(debugMode)


#region Update Cycle

func onInputComponent_didProcessInput(event: InputEvent) -> void:
	if not isEnabled \
	or not event.is_action(GlobalInput.Actions.jump) \
	or parameters.maxNumberOfJumps < 1: return

	# DESIGN: Cache input state as local properties, in case InputComponent's state changes while we're still processing an event/frame.
	# TIP: AI components & demo scripts may generate synthetic [InputEvent]s for jump etc.

	self.jumpInput = inputComponent.inputActionsPressed.has(GlobalInput.Actions.jump)
	# MAGIC: jumpInputJustPressed & jumpInputJustReleased are set by jumpInput setter
	# This allows AI/scripted input via InputComponent.generateEvent()
	# TBD: CHECK: Does this cause any jank behavior compared to Input.is_action_just_pressed()/released()?

	# UNUSED: Not compatible with AI-generated InputComponent events
	# self.jumpInput = Input.is_action_pressed(GlobalInput.Actions.jump)
	# self.jumpInputJustPressed  = Input.is_action_just_pressed(GlobalInput.Actions.jump)
	# self.jumpInputJustReleased = Input.is_action_just_released(GlobalInput.Actions.jump)

	if debugMode: printDebug(str("jumpInput: ", jumpInput, ", jumpInputJustPressed: ", jumpInputJustPressed, ", jumpInputJustReleased: ", jumpInputJustReleased, ", shouldBufferInput: ", shouldBufferInput, ", body.velocity: ", body.velocity.y))

	processWallJump()
	if not didWallJump:
		processJump()
		# If no jumps were made/possible, buffer the input if allowed
		if jumpInputJustPressed and shouldBufferInput: inputBufferTimer.start() # To be handled in characterBodyComponent_didMove()


## Performs updates that depend on the state AFTER the position is updated by [CharacterBody2D.move_and_slide].
func characterBodyComponent_didMove(_delta: float) -> void:
	# DEBUG: printLog("characterBodyComponent_didMove()")

	if characterBodyComponent.wasOnWall: # NOTE: NOT `is_on_wall_only()` CHECK: FORGOT: Why?
		wallJumpTimer.stop() # TBD: Is this needed?

	resetState()
	updateCoyoteJumpState()
	updateWallJumpState()

	if canBufferedJump: jump()
	if debugMode: showDebugInfo()
	clearInput()


## Resets the [currentNumberOfJumps] counter & [member coyoteJumpTimer] if the body is on a floor.
## NOTE: MUST be called AFTER processing the input and AFTER [method CharacterBody2D.move_and_slide].
func resetState() -> void:
	# NOTE: It may be more efficient to check `currentNumberOfJumps` instead of writing these values every frame?
	if currentNumberOfJumps != 0 and characterBodyComponent.isOnFloor:
		# DEBUG: printDebug("currentNumberOfJumps = 0")
		currentNumberOfJumps = 0
		coyoteJumpTimer.stop()
		currentState = State.idle


func clearInput() -> void:
	jumpInputJustPressed  = false
	jumpInputJustReleased = false

#endregion


#region Normal & Mid-Air Jump

## NOTE: Does NOT check [member isEnabled] or [PlatformerJumpParameters.maxNumberOfJumps] > 0
func processJump() -> void:
	# TBD: NOTE: These guard conditions may prevent a "short" jump if this function gets disabled DURING a jump.
	# UNUSED: PERFORMANCE: Let the caller check this: if not isEnabled or parameters.maxNumberOfJumps <= 0: return

	var shouldJump: bool = false

	# The initial or mid-air jump
	# TBD: Allow double-jumping after a wall jump?
	if self.jumpInputJustPressed:
		shouldJump = canFloorJump or canFallJump or canMultiJump

	# Shorten the initial jump if we release the input early while jumping
	# TBD: Should mid-air jumps also be short-able?
	elif self.jumpInputJustReleased \
	and not characterBodyComponent.isOnFloor \
	and currentNumberOfJumps == 1:

		# If the current velocity is FASTER than the short jump velocity, clamp it to the shorter velocity.
		# IMPORTANT: Also avoid triggering an extraneous short jump if the input is released when FALLING ON THE WAY DOWN! (or whatever the opposing `up_direction` is)
		# EXAMPLE: If a normal jump is -100 and a short jump is -50, then when falling the `body.velocity.y` would be POSITIVE (down),
		# so the comparison should be made after taking the `body.up_direction` into account.

		if debugMode: Debug.printVariables([parentEntity.name, body.velocity.y, parameters.jumpVelocity1stJumpShort * body.up_direction.y, body.up_direction.y])

		# CHECK: Verify that we got this understanding correct!

		if (body.up_direction.y < 0 and body.velocity.y < parameters.jumpVelocity1stJumpShort * body.up_direction.y) \
		or (body.up_direction.y > 0 and body.velocity.y > parameters.jumpVelocity1stJumpShort * body.up_direction.y): # Inverted gravity?

			if debugMode: printDebug(str("Short Jump! body.velocity.y: ", body.velocity.y, " → ", parameters.jumpVelocity1stJumpShort * body.up_direction.y))
			body.velocity.y = parameters.jumpVelocity1stJumpShort * body.up_direction.y
			characterBodyComponent.shouldMoveThisFrame = true

	# DEBUG: printLog(str("jumpInputJustPressed: ", jumpInputJustPressed, ", isOnFloor: ", isOnFloor, ", currentNumberOfJumps: ", currentNumberOfJumps, ", shouldJump: ", shouldJump))

	if shouldJump: jump() # Kris Kross will make ya


## The actual action you've all been waiting for. Called after all the input processing, timer checks & state validation has passed.
func jump() -> void:
	# NOTE: Respect the `up_direction` to allow for flipped-gravity situations!
	if currentNumberOfJumps <= 0: body.velocity.y = parameters.jumpVelocity1stJump * body.up_direction.y
	else: body.velocity.y = parameters.jumpVelocity2ndJump * body.up_direction.y

	inputBufferTimer.stop() # No need to "buffer" if we just jumped
	coyoteJumpTimer.stop() # The "coyote" grace period is no longer needed after we actually jump
	currentNumberOfJumps += 1
	currentState = State.jump # TBD: Should this be a `jump` state?

	characterBodyComponent.shouldMoveThisFrame = true
	if debugMode: printDebug(str("body.velocity.y → ",  body.velocity.y))


## Adds a "grace period" to allow jumping for a short time just after the player walks off a platform floor.
## May improve the feel of control in some games.
## NOTE: Does NOT check [member isEnabled] or [PlatformerJumpParameters.maxNumberOfJumps] > 0
func updateCoyoteJumpState() -> void:
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube

	if not parameters.allowCoyoteJump: return

	# Are we falling?
	# Inverted gravity:			body.up_direction.y = +1
	# Falling up onscreen:		velocity.y = -negative * +1 = -negative: < 0 = Falling
	# Jumping down onscreen:	velocity.y = +positive * +1 = +positive: > 0 = Jumping
	var fallVelocity: float = body.velocity.y * body.up_direction.y # Check for inverted gravity!

	if  characterBodyComponent.wasOnFloor \
		and not body.is_on_floor() \
		and (fallVelocity < 0.0 or is_zero_approx(fallVelocity)):
			coyoteJumpTimer.start() # beep beep!

#endregion


#region Wall Jumping

## Implements jumping when hanging on to a wall.
## Does NOT check [member isEnabled]
func processWallJump() -> void:
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube

	# PERFORMANCE: `isEnabled` would be rarely `false` at this point because it should have been checked by the caller of this function,
	# so just check the more commonly-changing conditions first:
	didWallJump = false # Always reset so we can do the normal processJump() if we don't wall-jump
	if not canWallJump: return

	# Get direction away from the current OR most recent wall collision (in case we're in the grace timer)
	var wallNormal: Vector2 = getWallJumpNormal()
	if  wallNormal.is_zero_approx(): return

	# le boing
	if self.jumpInputJustPressed:
		# NOTE: Respect the `up_direction` to allow for flipped-gravity situations!
		body.velocity.x = wallNormal.x * parameters.wallJumpVelocityX
		body.velocity.y = parameters.wallJumpVelocity * body.up_direction.y

		# Allow unlimited jumps between walls?
		if parameters.decreaseJumpCountOnWallJump and currentNumberOfJumps > 0:
			currentNumberOfJumps -= 1

		# Skip normal acceleration/friction for one frame to preserve the feeling of pushing off from a wall
		if platformerPhysicsComponent:
			platformerPhysicsComponent.shouldSkipVelocity = true
			platformerPhysicsComponent.shouldSkipFriction = true

		inputBufferTimer.stop() # Don't jump again after landing
		characterBodyComponent.shouldMoveThisFrame = true
		didWallJump = true


## Returns the current wall collision normal vector; the direction pointing away from a wall currently in contact,
## or the vector from the last wall in contact if the wall-jump grace period is still active i.e. [member wallJumpTimer]
func getWallJumpNormal() -> Vector2:
	if body.is_on_wall(): return body.get_wall_normal()

	elif not is_zero_approx(wallJumpTimer.time_left): # NOTE: Do NOT check `characterBodyComponent.wasOnWall` because that flag persists for 1 frame only
		return characterBodyComponent.previousWallNormal

	else: return Vector2.ZERO


func updateWallJumpState() -> void:
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube

	if not isEnabled or not parameters.allowWallJump: return

	# TODO: just_wall_jumped = false

	var didLeaveWall: bool = characterBodyComponent.wasOnWall \
		and not body.is_on_wall() \
		and not body.is_on_floor()

	if didLeaveWall: wallJumpTimer.start()

#endregion


#region Debugging

func _physics_process(_delta: float) -> void:
	showDebugInfo()


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.addComponentWatchList(self, {
		state		= currentState,
		jumps		= currentNumberOfJumps,
		jumpInput	= jumpInput,
		canFloor	= canFloorJump,
		canFallJump	= canFallJump,
		canMulti	= canMultiJump,
		shouldBuffer= shouldBufferInput,
		inputBufferTimer = inputBufferTimer.time_left,
		bufferedJump= canBufferedJump,
		canCoyote	= canCoyoteJump,
		coyoteTimer	= coyoteJumpTimer.time_left,
		canWall		= canWallJump,
		wallTimer	= wallJumpTimer.time_left,
		})

#endregion
