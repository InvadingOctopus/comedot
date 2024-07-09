## Handles jumping. Applies velocity when the player provides jump control input.
## Requirements: Entity with [CharacterBody2D], NOTE: Gravity is handled by [GravityComponent], and friction in air is handled by [PlatformerControlComponent]

class_name JumpControlComponent
extends PhysicsComponentBase

# CREDIT: THANKS: https://github.com/uheartbeast — https://github.com/uheartbeast/Heart-Platformer-Godot-4 — https://youtu.be/M8-JVjtJlIQ
# TODO: Reduce duplication of flags like `isOnFloor` etc.


#region Parameters
@export var isEnabled:  bool = true
@export var parameters: PlatformerJumpParameters = PlatformerJumpParameters.new()
#endregion


#region State

## The "grace period" while the player can still jump after just having walking off a platform floor.
## May improve the feel of control in some games.
@onready var coyoteJumpTimer:	Timer = $CoyoteJumpTimer

## The peroid while the player can "wall jump" after just having moved away from a wall.
@onready var wallJumpTimer:		Timer = $WallJumpTimer

enum State { idle, jump }

var states = {
	State.idle: null,
	State.jump: null
	}

var currentState: State:
	set(newValue):
		currentState = newValue
		#Debug.printDebug(self, value)


## Cache the input state so we only have to query [Input] once when there is an input event.
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
## WARNING: Must be cached AFTER updating gravity effects. May no longer be true after calling [method CharacterBody2D.move_and_slide]
var isOnFloor:		bool 

var wasOnFloor:		bool ## Was the body on the floor before the last [method CharacterBody2D.move_and_slide]?

var wasOnWall:		bool ## Was the body on a wall before the last [method CharacterBody2D.move_and_slide]?
var didWallJump:	bool ## Did we just perform a "wall jump"? 
var previousWallNormal: Vector2 ## The direction of the wall we were in contact with.

var currentNumberOfJumps: int
	# DEBUG:
	#set(newValue):
		#if currentNumberOfJumps != newValue:
			#currentNumberOfJumps = newValue	
			#printDebug("currentNumberOfJumps → " + str(currentNumberOfJumps))


var platformerControlComponent: PlatformerControlComponent:
	get:
		if not platformerControlComponent: platformerControlComponent = findCoComponent(PlatformerControlComponent)	
		return platformerControlComponent
		
#endregion


func _ready() -> void:
	self.currentState = State.idle
	
	# Set the initial timers
	
	coyoteJumpTimer.wait_time = parameters.coyoteJumpTimer
	wallJumpTimer.wait_time = parameters.wallJumpTimer


func _input(event: InputEvent):
	if not isEnabled: return
	if event.is_action(GlobalInput.Actions.jump): processJumpInput()


func processJumpInput():
	# Jump
	self.jumpInput = Input.is_action_pressed(GlobalInput.Actions.jump)
	#platformerPhysicsComponent.jumpInputJustReleased = Input.is_action_just_released(GlobalInput.Actions.jump)


func clearInput():
	jumpInputJustPressed  = false
	jumpInputJustReleased = false


func processBodyBeforeMove(delta: float):
	if not isEnabled: return
	
	updateStateBeforeMovement()
	
	processWallJump()
	processJump()

	# Update the flags which reflect the state BEFORE the position is updated by [CharacterBody2D.move_and_slide].
	
	self.wasOnFloor = isOnFloor
	self.wasOnWall  = body.is_on_wall() # NOTE: NOT `is_on_wall_only()` CHECK: Why?
	if wasOnWall: 
		previousWallNormal = body.get_wall_normal()
		wallJumpTimer.stop() # TBD: Is this needed?
		wallJumpTimer.wait_time = parameters.wallJumpTimer


func processBodyAfterMove(delta: float):
	#updateState()
	
	# Perform updates that depend on the state AFTER the position is updated by [CharacterBody2D.move_and_slide].
	wallJumpTimer.wait_time = parameters.wallJumpTimer
	updateCoyoteJumpState()
	updateWallJumpState()

	# DEBUG: 
	showDebugInfo()
	
	clearInput()


func processJump():
	# TBD: NOTE: These guard conditions may prevent a "short" jump if this function gets disabled DURING a jump.
	if not isEnabled or parameters.maxNumberOfJumps <= 0: return
	
	var shouldJump: bool = false
	
	# Initial or mid-air jump

	if self.jumpInputJustPressed:
		if currentNumberOfJumps <= 0: shouldJump = isOnFloor or not is_zero_approx(coyoteJumpTimer.time_left)
		else: shouldJump = (currentNumberOfJumps < parameters.maxNumberOfJumps) #and not didWallJump # TODO: TBD: Option for dis/allowing multi-jumping after wall-jumping
		# DEBUG: printLog(str("jumpInputJustPressed: ", jumpInputJustPressed, ", isOnFloor: ", isOnFloor, ", currentNumberOfJumps: ", currentNumberOfJumps, ", shouldJump: ", shouldJump))

	if shouldJump:
		if currentNumberOfJumps <= 0:
			body.velocity.y = parameters.jumpVelocity1stJump
		else:
			body.velocity.y = parameters.jumpVelocity2ndJump
		coyoteJumpTimer.stop() # The "coyote" jump grace period is no longer needed after we jump

		currentNumberOfJumps += 1
		currentState = State.jump # TBD: Should this be a `jump` state?

	# Shorten the initial jump if we release the input while jumping

	if self.jumpInputJustReleased \
		and not isOnFloor \
		and body.velocity.y < parameters.jumpVelocity1stJumpShort:
			body.velocity.y = parameters.jumpVelocity1stJumpShort


## Adds a "grace period" to allow jumping for a short time just after the player walks off a platform floor.
## May improve the feel of control in some games.
func updateCoyoteJumpState():
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube
	
	if not isEnabled: return
	
	var didWalkOffFloor: bool = wasOnFloor \
		and not body.is_on_floor() \
		and body.velocity.y >= 0 # Are we falling?
	
	if didWalkOffFloor: coyoteJumpTimer.start() # beep beep!


## NOTE: MUST be called BEFORE [method CharacterBody2D.move_and_slide] and AFTER [processInput]
func updateStateBeforeMovement():
	# DESIGN: Using `match` here may seem too cluttered and ambiguous

	# Cache frequently used properties
	self.isOnFloor = body.is_on_floor() # This should be cached after processing gravity.
	
	# Jump
	
	if isOnFloor and currentNumberOfJumps != 0: # NOTE: It may be more efficient to check `currentNumberOfJumps` instead of writing these values every frame?
			# DEBUG: printDebug("currentNumberOfJumps = 0")
			currentNumberOfJumps = 0
			coyoteJumpTimer.stop()
			coyoteJumpTimer.wait_time = parameters.coyoteJumpTimer


#region Wall Jumping

func processWallJump():
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube
	
	if  not isEnabled \
		or not parameters.allowWallJump \
		or (not body.is_on_wall_only() \
			and is_zero_approx(wallJumpTimer.time_left)): # TBD: Should we check for timer < 0?
				return 
	
	# NOTE: The current flow of conditions ensures that `wallNormal` will always = `previousWallNormal`,
	# but let's keep the code as was presented in Heartbeast's tutorial.
	
	var wallNormal: Vector2 = self.previousWallNormal
		
	if self.jumpInputJustPressed:
		body.velocity.x = wallNormal.x * parameters.wallJumpVelocityX
		body.velocity.y = parameters.wallJumpVelocity
		didWallJump = true


func updateWallJumpState():
	# CREDIT: THANKS: uHeartbeast@GitHub/YouTube
	
	if not isEnabled: return	
	
	# TODO: just_wall_jumped = false
	
	var didLeaveWall: bool = wasOnWall \
		and not body.is_on_wall()
	
	if didLeaveWall: wallJumpTimer.start()

#endregion


func showDebugInfo():	
	Debug.watchList.state		= currentState
	Debug.watchList.velocity	= body.velocity
	Debug.watchList.isOnFloor	= isOnFloor
	Debug.watchList.wasOnFloor	= wasOnFloor
	Debug.watchList.wasOnWall	= wasOnWall
	Debug.watchList.wallNormal	= previousWallNormal
	Debug.watchList.wallTimer	= wallJumpTimer.time_left
	Debug.watchList.coyoteTimer	= coyoteJumpTimer.time_left
	Debug.watchList.jumpInput	= jumpInput
	Debug.watchList.jumps		= currentNumberOfJumps
	
