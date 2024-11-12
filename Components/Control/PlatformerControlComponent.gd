## Provides player control input to a [PlatformerPhysicsComponent].
## NOTE: Jumping is provided by [JumpControlComponent].
## Requirements: BEFORE [PlatformerPhysicsComponent] & [CharacterBodyComponent]

class_name PlatformerControlComponent
extends Component

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ
# TBD: CHECK: Performance impact of having multiple components for basic player movement.


#region Parameters

## Flips the controls. For situations like mirrored gameplay or "confusion" effects etc.
@export var shouldInvertXAxis: bool = false # For when you pick a purple flower :)

@export var isEnabled: bool = true
#endregion


#region State

var inputDirectionOverride:	float = 0 ## Overrides [member inputDirection] for example to allow control by AI agents. NOTE: Reset to 0 every frame.
var inputDirection:			float
var lastInputDirection:		float
var isInputZero:			bool = true

@onready var platformerPhysicsComponent: PlatformerPhysicsComponent = coComponents.PlatformerPhysicsComponent # TBD: Static or dynamic?

#endregion


func getRequiredComponents() -> Array[Script]:
	return [PlatformerPhysicsComponent]


func _input(_event: InputEvent) -> void:
	if not isEnabled: return
	# if event.is_action(GlobalInput.Actions.jump): processJumpInput() # NOTE: Jumping is solely handled by [JumpControlComponent]


func _physics_process(_delta: float) -> void:
	if not isEnabled: return
	processInput()
	copyInputToPhysicsComponent()


## Handles player input.
## Affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
func processInput() -> void:
	if not isEnabled: return

	# Get the input direction and handle the movement/deceleration.
	if inputDirectionOverride:
		self.inputDirection = inputDirectionOverride
	else:
		self.inputDirection = Input.get_axis(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight)

	if shouldInvertXAxis: self.inputDirection = -self.inputDirection

	# Reset the override.
	self.inputDirectionOverride = 0

	# Cache properties that are accessed often to avoid repeated function calls on other objects.
	self.isInputZero = is_zero_approx(inputDirection)

	if not isInputZero: lastInputDirection = inputDirection

	# NOTE: DESIGN: Accept input in air even if [member PlatformerMovementParameters.shouldAllowMovementInputInAir] is `false`,
	# so that some games can let the player turn around to shoot in any direction while in air, for example.


func processJumpInput() -> void:
	pass # NOTE: Jumping is solely handled by [JumpControlComponent]
	# Jump
	# platformerPhysicsComponent.jumpInput = Input.is_action_pressed(GlobalInput.Actions.jump)
	#platformerPhysicsComponent.jumpInputJustReleased = Input.is_action_just_released(GlobalInput.Actions.jump)


func copyInputToPhysicsComponent() -> void:
	# TBD: Check performance impact vs setting directly
	# TBD: Should this only be called after input events?
	platformerPhysicsComponent.inputDirection		= self.inputDirection
	platformerPhysicsComponent.isInputZero			= self.isInputZero
	platformerPhysicsComponent.lastInputDirection	= self.lastInputDirection
