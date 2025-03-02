## Handles jumping. Applies velocity when the player inputs the jump control.
## The direction of the jump is determined by the [member CharacterBody2D.up_direction] (only the Y axis).
## NOTE: Gravity and friction in air is handled by [PlatformerPhysicsComponent].
## Requirements: BEFORE [PlatformerPhysicsComponent] & [CharacterBodyComponent]

class_name JumpControlComponent
extends CharacterBodyDependentComponentBase

# CREDIT: THANKS: https://github.com/uheartbeast — https://github.com/uheartbeast/Heart-Platformer-Godot-4 — https://youtu.be/M8-JVjtJlIQ
# TODO: Stop keyboard input repetition?
# TBD:  Respect the `CharacterBody2D.up_direction.x` axis too?
# TBD:  A more fail-proof way of handling short jumps. Timers?


#region Parameters
@export var isEnabled:  bool = true
@export var parameters: PlatformerJumpParameters = PlatformerJumpParameters.new()
#endregion


#region State

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

var didWallJump:			bool ## Did we just perform a "wall jump"?

#endregion


func _ready() -> void:
	self.currentState = State.idle
	if characterBodyComponent:
		characterBodyComponent.didMove.connect(self.characterBodyComponent_didMove)
	else:
		printWarning("Missing CharacterBodyComponent")

	# Set the initial timers

	coyoteJumpTimer.wait_time = parameters.coyoteJumpTimer
	wallJumpTimer.wait_time = parameters.wallJumpTimer


#region Update Cycle

func _input(event: InputEvent) -> void:
	if not isEnabled \
	or not event.is_action(GlobalInput.Actions.jump): return

	self.jumpInput = Input.is_action_pressed(GlobalInput.Actions.jump)
	self.jumpInputJustPressed  = Input.is_action_just_pressed(GlobalInput.Actions.jump)
	self.jumpInputJustReleased = Input.is_action_just_released(GlobalInput.Actions.jump)

	if debugMode:
		printDebug(str("jumpInput: ", jumpInput, ", jumpInputJustPressed: ", jumpInputJustPressed, ", jumpInputJustReleased: ", jumpInputJustReleased, ", body.velocity: ", body.velocity.y))

	processWallJump()
	processJump()

	characterBodyComponent.queueMoveAndSlide()


## Performs updates that depend on the state AFTER the position is updated by [CharacterBody2D.move_and_slide].
func characterBodyComponent_didMove(_delta: float) -> void:
	# DEBUG: printLog("characterBodyComponent_didMove()")

	if characterBodyComponent.wasOnWall: # NOTE: NOT `is_on_wall_only()` CHECK: FORGOT: Why?
		wallJumpTimer.stop() # TBD: Is this needed?

	resetState()
	updateCoyoteJumpState()
	updateWallJumpState()

	if debugMode: showDebugInfo()
	clearInput()


## Resets the [currentNumberOfJumps] counter & [member coyoteJumpTimer] if the body is on a floor.
## NOTE: MUST be called BEFORE [method CharacterBody2D.move_and_slide] and AFTER [processInput].
func resetState() -> void:
	# NOTE: It may be more efficient to check `currentNumberOfJumps` instead of writing these values every frame?
	if currentNumberOfJumps != 0 and characterBodyComponent.isOnFloor:
		# DEBUG: printDebug("currentNumberOfJumps = 0")
		currentNumberOfJumps = 0
		coyoteJumpTimer.stop()


func clearInput() -> void:
	jumpInputJustPressed  = false
	jumpInputJustReleased = false

#endregion


#region Normal & Mid-Air Jump

func processJump() -> void:
	# TBD: NOTE: These guard conditions may prevent a "short" jump if this function gets disabled DURING a jump.
	if not isEnabled or parameters.maxNumberOfJumps <= 0: return

	var shouldJump:    bool = false
	var canCoyoteJump: bool = parameters.allowCoyoteJump and not is_zero_approx(coyoteJumpTimer.time_left)

	# The initial or mid-air jump
	# TBD: Allow double-jumping after a wall jump?

	if self.jumpInputJustPressed:

		if currentNumberOfJumps <= 0: shouldJump = characterBodyComponent.isOnFloor or canCoyoteJump
		else: shouldJump = (currentNumberOfJumps < parameters.maxNumberOfJumps) #and not didWallJump # TODO: TBD: Option for dis/allowing multi-jumping after wall-jumping

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

	# DEBUG: printLog(str("jumpInputJustPressed: ", jumpInputJustPressed, ", isOnFloor: ", isOnFloor, ", currentNumberOfJumps: ", currentNumberOfJumps, ", shouldJump: ", shouldJump))

	if shouldJump: # Jump! Jump!
		# NOTE: Respect the `up_direction` to allow for flipped-gravity situations!
		if currentNumberOfJumps <= 0: body.velocity.y = parameters.jumpVelocity1stJump * body.up_direction.y
		else: body.velocity.y = parameters.jumpVelocity2ndJump * body.up_direction.y

		coyoteJumpTimer.stop() # The "coyote" grace period is no longer needed after we actually jump
		currentNumberOfJumps += 1
		currentState = State.jump # TBD: Should this be a `jump` state?

		if debugMode: printDebug(str("body.velocity.y → ",  body.velocity.y))



## Adds a "grace period" to allow jumping for a short time just after the player walks off a platform floor.
## May improve the feel of control in some games.
func updateCoyoteJumpState() -> void:
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube

	if not isEnabled or not parameters.allowCoyoteJump: return

	var didWalkOffFloor: bool = characterBodyComponent.wasOnFloor \
		and not body.is_on_floor() \
		and body.velocity.y >= 0 # Are we falling?

	if didWalkOffFloor:
		coyoteJumpTimer.wait_time = parameters.coyoteJumpTimer
		coyoteJumpTimer.start() # beep beep!

#endregion


#region Wall Jumping

func processWallJump() -> void:
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube

	if  not isEnabled \
		or not parameters.allowWallJump \
		or currentNumberOfJumps >= parameters.maxNumberOfJumps \
		or (not body.is_on_wall_only() \
			and is_zero_approx(wallJumpTimer.time_left)): # TBD: Should we check for timer < 0?
				return

	# NOTE: The current flow of conditions ensures that `wallNormal` will always = `previousWallNormal`,
	# but let's keep the code as was presented in Heartbeast's tutorial.

	var wallNormal: Vector2 = characterBodyComponent.previousWallNormal

	if self.jumpInputJustPressed:
		# NOTE: Respect the `up_direction` to allow for flipped-gravity situations!
		body.velocity.x = wallNormal.x * parameters.wallJumpVelocityX
		body.velocity.y = parameters.wallJumpVelocity * body.up_direction.y

		# Allow unlimited jumps between walls?
		if parameters.decreaseJumpCountOnWallJump and currentNumberOfJumps > 0:
			currentNumberOfJumps -= 1

		didWallJump = true


func updateWallJumpState() -> void:
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube

	if not isEnabled or not parameters.allowWallJump: return

	# TODO: just_wall_jumped = false

	var didLeaveWall: bool = characterBodyComponent.wasOnWall \
		and not body.is_on_wall() \
		and not body.is_on_floor()

	if didLeaveWall:
		wallJumpTimer.wait_time = parameters.wallJumpTimer
		wallJumpTimer.start()

#endregion


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList[str("\n —", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.state		= currentState
	Debug.watchList.wallTimer	= wallJumpTimer.time_left
	Debug.watchList.coyoteTimer	= coyoteJumpTimer.time_left
	Debug.watchList.jumpInput	= jumpInput
	Debug.watchList.jumps		= currentNumberOfJumps
