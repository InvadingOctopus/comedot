## Handles the physics for horizontal walking, jumping and gravity for the entity's [CharacterBody2D] in a "platform" world.
## NOTE: Does NOT handle player input. Control is provided by [PlatformerPhysicsControlComponent] and AI components etc.
## Unifies [PlatformerControlComponent], [JumpControlComponent], [GravityComponent]
## Requirements: Entity with [CharacterBody2D], BELOW [PlatformerPhysicsControlComponent]
## @experimental

class_name PlatformerPhysicsComponent_Monolith
extends BodyComponent

# CREDIT: THANKS: https://github.com/uheartbeast — https://github.com/uheartbeast/Heart-Platformer-Godot-4 — https://youtu.be/M8-JVjtJlIQ
# TODO: Implement variable jump height based on how long the input is pressed.
# TODO: Option for dis/allowing multi-jumping after wall-jumping.
# TODO: Update timers when paremeters change
# TODO: Maximum limit for wall jumps


#region Parameters

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue
		if not isEnabled:
			# Reset other flags only once
			self.inputDirection = 0
			self.isInputZero = true
		
@export var parameters: PlatformerMovementParameters = PlatformerMovementParameters.new()
@export var jumpParameters: PlatformerJumpParameters = PlatformerJumpParameters.new()

#endregion


#region State

enum State { idle, moveOnFloor, moveInAir }

var states = {
	State.idle:			null,
	State.moveOnFloor:	null,
	State.moveInAir:	null,
	# State.jumping:	null, # TBD
	# State.falling:	null, # TBD
	}

var currentState: State:
	set(newValue):
		currentState = newValue
		# DEBUG: printDebug(str(currentState))

## The "grace period" while the player can still jump after just having walking off a platform floor.
## May improve the feel of control in some games.
@onready var coyoteJumpTimer:	Timer = $CoyoteJumpTimer

## The peroid while the player can "wall jump" after just having moved away from a wall.
@onready var wallJumpTimer:		Timer = $WallJumpTimer

var inputDirection:			float
var lastInputDirection:		float
var isInputZero:			bool = true

var jumpInput:				bool:
	set(newValue):
		if jumpInput == newValue: return # NOTE: Don't trigger other flags' setters if there is no actual change!
		var oldValue: bool = jumpInput
		jumpInput = newValue
		# The "just pressed" & "just released" toggles are needed for "short" jumping etc.
		jumpInputJustPressed  = (newValue and not oldValue)
		jumpInputJustReleased = (not newValue and oldValue)
		
var jumpInputJustPressed:	bool
	# DEBUG: 
	#set(newValue):
		#if jumpInputJustPressed == newValue: return
		#jumpInputJustPressed = newValue
		#printDebug("jumpInputJustPressed → " + str(jumpInputJustPressed))
		
var jumpInputJustReleased:	bool
	# DEBUG: 
	#set(newValue):
		#if jumpInputJustReleased == newValue: return
		#jumpInputJustReleased = newValue
		#printDebug("jumpInputJustReleased → " + str(jumpInputJustReleased))

## The cached state of [method CharacterBody2D.is_on_floor] for the current frame.
## WARNING: Must be cached AFTER [method processGravity]. May no longer be true after calling [method CharacterBody2D.move_and_slide]
var isOnFloor:		bool 

var wasOnFloor:		bool ## Was the body on the floor before the last [method CharacterBody2D.move_and_slide]?

var wasOnWall:		bool ## Was the body on a wall before the last [method CharacterBody2D.move_and_slide]?
var didWallJump:	bool ## Did we just perform a "wall jump"? 
var previousWallNormal: Vector2 ## The direction of the wall we were in contact with.

var gravity:		float = ProjectSettings.get_setting(Global.SettingsPaths.gravity)

var currentNumberOfJumps: int
	# DEBUG:
	#set(newValue):
		#if currentNumberOfJumps != newValue:
			#currentNumberOfJumps = newValue	
			#printDebug("currentNumberOfJumps → " + str(currentNumberOfJumps))
		
#endregion


func _ready() -> void:
	self.currentState = State.idle
	if parentEntity.body:
		printLog("parentEntity.body.motion_mode → Grounded")
		parentEntity.body.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	else:
		printWarning("Missing parentEntity.body: " + parentEntity.logName)
		
	# Set the initial timers
	
	coyoteJumpTimer.wait_time = jumpParameters.coyoteJumpTimer
	wallJumpTimer.wait_time   = jumpParameters.wallJumpTimer


#region Update Cycle

func _physics_process(delta: float):
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube
	# NOTE: The order of processing is as per Heartbeast's tutorial.
	
	if not isEnabled: return
	
	# Sanitize the control input and prepare flags etc. for use by other functions.
	processInput()
	
	# Update flags and other state
	updateStateBeforeMovement()
	
	# Let's fall from wherever we were in the previous frame, before we do anything else.
	processGravity(delta)
	
	# Jump the Jump 
	# TBD: Jump before Walk?
	processWallJump()
	processJump()
	
	# Walk the Walk
	
	#applyAccelerationOnFloor(delta)
	#applyAccelerationInAir(delta)
	processHorizontalMovement(delta)
	#applyFrictionOnFloor(delta)
	#applyFrictionInAir(delta)
	processAllFriction(delta)

	# Update the flags which reflect the state BEFORE the position is updated by [CharacterBody2D.move_and_slide].
	
	self.wasOnFloor = isOnFloor
	self.wasOnWall  = body.is_on_wall() # NOTE: NOT `is_on_wall_only()` CHECK: Why?
	if wasOnWall: 
		previousWallNormal = body.get_wall_normal()
		wallJumpTimer.stop() # TBD: Is this needed?
		wallJumpTimer.wait_time = jumpParameters.wallJumpTimer
	
	# Move Your Body ♪	
	parentEntity.callOnceThisFrame(body.move_and_slide)
	
	# Perform updates that depend on the state AFTER the position is updated by [CharacterBody2D.move_and_slide].
	wallJumpTimer.wait_time = jumpParameters.wallJumpTimer
	updateCoyoteJumpState()
	updateWallJumpState()
	
	# DEBUG:  showDebugInfo()
	
	# Clear the input so it doesn't carry on over to the next frame.
	clearInput()


## NOTE: MUST be called BEFORE [method CharacterBody2D.move_and_slide] and AFTER [processInput]
func updateStateBeforeMovement() -> void:
	# DESIGN: Using `match` here may seem too cluttered and ambiguous

	if currentState == State.idle and not isInputZero:
		# CHECK: Should this be done in `processInput()` so that there is only one check for [isInputZero]?
		currentState = State.moveOnFloor if isOnFloor else State.moveInAir

	if currentState != State.idle and body.velocity.is_zero_approx():
		currentState = State.idle

	# Cache frequently used properties
	self.isOnFloor = body.is_on_floor() # This should be cached after processing gravity.
	
	# Jump
	
	if isOnFloor and currentNumberOfJumps != 0: # NOTE: It may be more efficient to check `currentNumberOfJumps` instead of writing these values every frame?
			# DEBUG: printDebug("currentNumberOfJumps = 0")
			currentNumberOfJumps = 0
			coyoteJumpTimer.stop()
			coyoteJumpTimer.wait_time = jumpParameters.coyoteJumpTimer


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


func clearInput() -> void:
	inputDirection = 0 # TBD: Should the "no input" state just be a `0` or some other flag?
	#jumpInput = false # NOTE: Let the control components reset the `jumpInput`
	# The justPressed/justReleased flags should be reset here because they represent a state for only 1 frame
	jumpInputJustPressed  = false
	jumpInputJustReleased = false


func processGravity(delta: float):
	# Vertical Slowdown
	if not body.is_on_floor(): # ATTENTION: Cache [isOnFloor] AFTER processing gravity.
		body.velocity.y += (gravity * parameters.gravityScale) * delta

#endregion


#region Horizontal Movement & Friction

## Applies movement with or without gradual acceleration depending on the [member shouldApplyAccelerationOnFloor] or [member shouldApplyAccelerationInAir] flags.
## NOTE: NOT affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
func processHorizontalMovement(delta: float):
	# Nothing to do if there is no player input.
	if isInputZero: return

	if isOnFloor: # Are we on the floor?
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

	if isOnFloor and parameters.shouldApplyFrictionOnFloor and isInputZero:
		body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionOnFloor * delta)
	elif (not isOnFloor) and parameters.shouldApplyFrictionInAir and (isInputZero or not parameters.shouldAllowMovementInputInAir):
		body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionInAir * delta)

#endregion


#region Jumping


func processWallJump() -> void:
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube
	
	if  not isEnabled \
		or not jumpParameters.allowWallJump \
		or (not body.is_on_wall_only() \
			and is_zero_approx(wallJumpTimer.time_left)): # TBD: Should we check for timer < 0?
				return 
	
	# NOTE: The current flow of conditions ensures that `wallNormal` will always = `previousWallNormal`,
	# but let's keep the code as was presented in Heartbeast's tutorial.
	
	var wallNormal: Vector2 = self.previousWallNormal
		
	if self.jumpInputJustPressed:
		body.velocity.x = wallNormal.x * jumpParameters.wallJumpVelocityX
		body.velocity.y = jumpParameters.wallJumpVelocity
		didWallJump = true


func processJump() -> void:
	# TBD: NOTE: These guard conditions may prevent a "short" jump if this function gets disabled DURING a jump.
	if not isEnabled or jumpParameters.maxNumberOfJumps <= 0: return
	
	var shouldJump: bool = false

	# Initial or mid-air jump

	if self.jumpInputJustPressed:
		if currentNumberOfJumps <= 0: shouldJump = isOnFloor or not is_zero_approx(coyoteJumpTimer.time_left)
		else: shouldJump = (currentNumberOfJumps < jumpParameters.maxNumberOfJumps) #and not didWallJump # TODO: TBD: Option for dis/allowing multi-jumping after wall-jumping
		# DEBUG: printLog(str("jumpInputJustPressed: ", jumpInputJustPressed, ", isOnFloor: ", isOnFloor, ", currentNumberOfJumps: ", currentNumberOfJumps, ", shouldJump: ", shouldJump))

	if shouldJump:
		if currentNumberOfJumps <= 0:
			body.velocity.y = jumpParameters.jumpVelocity1stJump
		else:
			body.velocity.y = jumpParameters.jumpVelocity2ndJump
		coyoteJumpTimer.stop() # The "coyote" jump grace period is no longer needed after we jump

		currentNumberOfJumps += 1
		currentState = State.moveInAir # TBD: Should this be a `jump` state?

	# Shorten the initial jump if we are jumping

	if self.jumpInputJustReleased \
		and not isOnFloor \
		and body.velocity.y < jumpParameters.jumpVelocity1stJumpShort:
			body.velocity.y = jumpParameters.jumpVelocity1stJumpShort


## Adds a "grace period" to allow jumping for a short time just after the player walks off a platform floor.
## May improve the feel of control in some games.
func updateCoyoteJumpState() -> void:
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube
	
	if not isEnabled: return
	
	var didWalkOffFloor: bool = wasOnFloor \
		and not body.is_on_floor() \
		and body.velocity.y >= 0 # Are we falling?
	
	if didWalkOffFloor: coyoteJumpTimer.start() # beep beep!


func updateWallJumpState() -> void:
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube
	
	if not isEnabled: return	
	
	# TODO: just_wall_jumped = false
	
	var didLeaveWall: bool = wasOnWall \
		and not body.is_on_wall()
	
	if didLeaveWall: wallJumpTimer.start()


#endregion


#region Standalone Functions

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ

## Applies [member accelerationOnFloor] regardless of [member shouldApplyAccelerationOnFloor]; this flag should be checked by caller.
func applyAccelerationOnFloor(delta: float):
	if (not isInputZero) and isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, parameters.speedOnFloor * inputDirection, parameters.accelerationOnFloor * delta)


## Applies [member accelerationInAir] regardless of [member shouldApplyAccelerationInAir]; this flag should be checked by caller.
func applyAccelerationInAir(delta: float):
	if (not isInputZero) and (not isOnFloor):
		body.velocity.x = move_toward(body.velocity.x, parameters.speedInAir * inputDirection, parameters.accelerationInAir * delta)


## Applies [member frictionOnFloor] regardless of [member shouldApplyFrictionOnFloor]; this flag should be checked by caller.
func applyFrictionOnFloor(delta: float):
	# Friction on floor should only be applied if there is no input;
	# otherwise the player would not be able to start moving in the first place!
	if isInputZero and isOnFloor:
		body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionOnFloor * delta)


## Applies [member frictionInAir] regardless of [member shouldApplyFrictionInAir]; this flag should be checked by caller.
func applyFrictionInAir(delta: float):
	# If movement is not allowed in air, then apply air friction regardless of player input.
	if (isInputZero or not parameters.shouldAllowMovementInputInAir) and (not isOnFloor):
		body.velocity.x = move_toward(body.velocity.x, 0.0, parameters.frictionInAir * delta)

#endregion


func showDebugInfo() -> void:	
	Debug.watchList.state		= currentState
	Debug.watchList.input		= inputDirection
	Debug.watchList.velocity	= body.velocity
	Debug.watchList.isOnFloor	= isOnFloor
	Debug.watchList.wasOnFloor	= wasOnFloor
	Debug.watchList.wasOnWall	= wasOnWall
	Debug.watchList.wallNormal	= previousWallNormal
	Debug.watchList.wallTimer	= wallJumpTimer.time_left
	Debug.watchList.coyoteTimer	= coyoteJumpTimer.time_left
	Debug.watchList.jumpInput	= jumpInput
	Debug.watchList.jumps		= currentNumberOfJumps
	
	# Friction?
	if isOnFloor and parameters.shouldApplyFrictionOnFloor and isInputZero:
		Debug.watchList.friction = "floor"
	elif (not isOnFloor) and parameters.shouldApplyFrictionInAir and (isInputZero or not parameters.shouldAllowMovementInputInAir):
		Debug.watchList.friction = "air"
	else:
		Debug.watchList.friction = "none"
