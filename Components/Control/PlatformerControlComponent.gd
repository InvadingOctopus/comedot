## Provides player control input to a [PlatformerPhysicsComponent].
## NOTE: Jumping is provided by [JumpControlComponent], climbing is provided by [ClimbComponent].
## Requirements: BEFORE [PlatformerPhysicsComponent] & [CharacterBodyComponent]

class_name PlatformerControlComponent
extends Component

# THANKS: CREDIT: uHeartbeast@YouTube https://youtu.be/M8-JVjtJlIQ
# TBD: CHECK: Performance impact of having multiple components for basic player movement.


#region Parameters

## Flips the controls. For situations like mirrored gameplay or "confusion" effects etc.
@export var shouldInvertXAxis: bool = false # For when you pick a purple flower :)

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue # Don't bother checking for a change
		self.set_physics_process(isEnabled) # PERFORMANCE: Set once instead of every frame

#endregion


#region State
var inputDirectionOverride:	float = 0 ## Overrides [member inputDirection] for example to allow control by AI agents. NOTE: Reset to 0 every frame.
var inputDirection:			float ## The horizontal direction of walking movement.
var lastInputDirection:		float ## The last input direction received. NOTE: NOT "previous" direction: this may be the SAME as [member inputDirection]
var isInputZero:			bool = true
#endregion


#region Signals
## Emitted when [member inputDirection] and [member lastInputDirection] have a different SIGN (positive/negative), signifying a change/flip in direction from right ↔ left.
## Used for sprite flipping and other animations etc.
signal didChangeHorizontalDirection
#endregion


#region Dependencies
@onready var platformerPhysicsComponent: PlatformerPhysicsComponent = coComponents.PlatformerPhysicsComponent # TBD: Static or dynamic?
func getRequiredComponents() -> Array[Script]:
	return [PlatformerPhysicsComponent]
#endregion


func _ready() -> void:
	self.set_physics_process(isEnabled) # Apply setter because Godot doesn't on initialization


func _physics_process(_delta: float) -> void:
	processInput()
	copyInputToPhysicsComponent()


## Handles player input.
## Affected by [member isEnabled], so other components such as Enemy AI may drive this component without player input.
func processInput() -> void:
	# NOTE: DESIGN: Accept input in air even if [member PlatformerMovementParameters.shouldAllowMovementInputInAir] is `false`,
	# so that some games can let the player turn around to shoot in any direction while in air, for example.
	# if not isEnabled: return # Unnecessary check after `set_physics_process()`

	# Get the input direction

	if inputDirectionOverride: inputDirection = inputDirectionOverride
	else: inputDirection = Input.get_axis(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight)

	if shouldInvertXAxis: inputDirection = -inputDirection

	# Reset the override
	inputDirectionOverride = 0

	# Cache properties that are accessed often to avoid repeated function calls on other objects.
	isInputZero = is_zero_approx(inputDirection)

	if not isInputZero:
		# Emit signals if we're changing directions, to support sprite flipping & animations etc.
		if signf(inputDirection) != signf(lastInputDirection):
			if debugMode:
				printDebug(str("didChangeHorizontalDirection: lastInputDirection: ", lastInputDirection, " -> inputDirection: ", inputDirection))
				emitDebugBubble(str(lastInputDirection, "->", inputDirection))
			didChangeHorizontalDirection.emit()

		lastInputDirection = inputDirection

	# DEBUG: if debugMode: showDebugInfo() # PERFORMANCE: Skip check until logging is actually needed


func copyInputToPhysicsComponent() -> void:
	# TBD: Check performance impact vs setting directly
	# TBD: Should this only be called after input events?
	platformerPhysicsComponent.inputDirection		= self.inputDirection
	platformerPhysicsComponent.isInputZero			= self.isInputZero
	platformerPhysicsComponent.lastInputDirection	= self.lastInputDirection


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.addComponentWatchList(self, {
		inputDirectionOverride	= inputDirectionOverride,
		inputDirection			= inputDirection,
		lastInputDirection		= lastInputDirection,
		})
