## Handles jumping.
## Requirements: Entity with [CharacterBody2D], NOTE: Gravity and falling is handled by [GravityComponent]

class_name JumpControlComponent
extends BodyComponent

# TODO: Allow jumps when falling down from walking over an edge

#region Parameters
@export var isEnabled: bool = true
@export var parameters: PlatformerMovementParameters = PlatformerMovementParameters.new()
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
	if not isEnabled: return
	checkJumpInput()


func checkJumpInput():
	var shouldJump = false
	if not isEnabled: return

	# Initial or mid-air jump

	if Input.is_action_just_pressed(GlobalInput.Actions.jump):
		if currentNumberOfJumps == 0: shouldJump = body.is_on_floor()
		else: shouldJump = currentNumberOfJumps < parameters.maxNumberOfJumps

	if shouldJump:
		if currentNumberOfJumps == 0:
			body.velocity.y = parameters.jumpVelocity1stJump
		else:
			body.velocity.y = parameters.jumpVelocity2ndJump

		currentNumberOfJumps += 1
		currentState = State.jump

	# Short initial jump

	if Input.is_action_just_released(GlobalInput.Actions.jump) and body.velocity.y < parameters.jumpVelocity1stJumpShort:
		body.velocity.y = parameters.jumpVelocity1stJumpShort


func _physics_process(delta: float):
	checkState()
	if not isEnabled: return
	#checkJumpInput(delta)
	parentEntity.callOnceThisFrame(body.move_and_slide)


func checkState():
	# NOTE: Falling down is handled by [GravityComponent]
	# so the player can still fall without a jumping ability :)

	if body.is_on_floor():
		currentNumberOfJumps = 0

	if currentState != State.idle and is_zero_approx(body.velocity.x) and is_zero_approx(body.velocity.y):
		currentState = State.idle
