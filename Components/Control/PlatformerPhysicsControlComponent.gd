## Provides player control input to a [PlatformerPhysicsControlComponent].
## Requirements: ABOVE [PlatformerPhysicsControlComponent]
## @experimental

class_name PlatformerPhysicsControlComponent
extends Component

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ


#region Parameters
@export var isEnabled: bool = true
#endregion


#region State

var inputDirectionOverride:	float = 0 ## Overrides [member inputDirection] for example to allow control by AI agents. NOTE: Reset to 0 every frame.
var inputDirection:			float
var lastInputDirection:		float
var isInputZero:			bool = true

var platformerPhysicsComponent: PlatformerPhysicsComponent:
	get:
		if not platformerPhysicsComponent: platformerPhysicsComponent = findCoComponent(PlatformerPhysicsComponent)
		return platformerPhysicsComponent

#endregion


func _input(event: InputEvent):
	if not isEnabled: return
	if event.is_action(GlobalInput.Actions.jump): processJumpInput()


func _physics_process(delta: float):
	if not isEnabled: return
	processInput()
	copyInputToPhysicsComponent()
	

## Handles player input.
## Affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
func processInput():
	if not isEnabled: return

	# Get the input direction and handle the movement/deceleration.
	if inputDirectionOverride:
		self.inputDirection = inputDirectionOverride
	else:
		self.inputDirection = Input.get_axis(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight)

	# Reset the override.
	self.inputDirectionOverride = 0

	# Cache properties that are accessed often to avoid repeated function calls on other objects.
	self.isInputZero = is_zero_approx(inputDirection)

	if not isInputZero: lastInputDirection = inputDirection

	# NOTE: DESIGN: Accept input in air even if [member PlatformerMovementParameters.shouldAllowMovementInputInAir] is `false`,
	# so that some games can let the player turn around to shoot in any direction while in air, for example.
	

func processJumpInput():
	# Jump
	platformerPhysicsComponent.jumpInput = Input.is_action_pressed(GlobalInput.Actions.jump)
	#platformerPhysicsComponent.jumpInputJustReleased = Input.is_action_just_released(GlobalInput.Actions.jump)


func copyInputToPhysicsComponent():
	# TBD: Check performance impact vs setting directly 
	# TBD: Should this only be called after input events?
	platformerPhysicsComponent.inputDirection		= self.inputDirection
	platformerPhysicsComponent.isInputZero			= self.isInputZero
	platformerPhysicsComponent.lastInputDirection	= self.lastInputDirection
	
