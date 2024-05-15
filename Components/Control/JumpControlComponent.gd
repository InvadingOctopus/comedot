## Handles jumps.
## NOTE: Gravity and falling is handled by [PlatformerControlComponent]

class_name JumpControlComponent
extends BodyComponent


#region Parameters

#@export_subgroup("Jump")
@export_range(0, 5, 1) var maxNumberOfJumps: int = 2
@export_range(-1000.0, -100.0, 50.0) var jumpVelocity1stJump       := -350.0
@export_range(-1000.0, -100.0, 50.0) var jumpVelocity1stJumpShort  := -175.0
@export_range(-1000.0, -100.0, 50.0) var jumpVelocity2ndJump       := -300.0
#endregion


#region State

enum State { idle, jump }

var states = {
	State.idle: null,
	State.jump: null
	}

var currentState: State:
	set(newValue):
		currentState = newValue
		#Debug.printDebug(self, value)

var currentNumberOfJumps: int = 0

#endregion


func _ready() -> void:
	self.currentState = State.idle


func _input(event: InputEvent):
	checkJumpInput()


func checkJumpInput():
	var shouldJump = false

	# Initial or mid-air jump

	if Input.is_action_just_pressed(GlobalInput.Actions.jump):
		if currentNumberOfJumps == 0: shouldJump = body.is_on_floor()
		else: shouldJump = currentNumberOfJumps < maxNumberOfJumps

	if shouldJump:
		if currentNumberOfJumps == 0:
			body.velocity.y = jumpVelocity1stJump
		else:
			body.velocity.y = jumpVelocity2ndJump

		currentNumberOfJumps += 1
		currentState = State.jump

	# Short initial jump

	if Input.is_action_just_released(GlobalInput.Actions.jump) and body.velocity.y < jumpVelocity1stJumpShort:
		body.velocity.y = jumpVelocity1stJumpShort


func _physics_process(delta: float):
	processGravity(delta)
	#checkJumpInput(delta)
	parentEntity.callOnceThisFrame(body.move_and_slide)


func processGravity(delta):
	# NOTE: Falling down is handled by [PlatformMovementComponent]
	# so the player can still fall without a jumping ability :)

	if body.is_on_floor():
		currentNumberOfJumps = 0

	if currentState != State.idle and is_zero_approx(body.velocity.x) and is_zero_approx(body.velocity.y):
		currentState = State.idle
