## Provides player input to a [TileBasedPositionComponent].
## Requirements: [TileBasedPositionComponent]

class_name TileBasedControlComponent
extends Component

# TODO: Allow movement on input `is_just_released`


#region Parameters

@export var shouldAllowDiagonals:	bool = false
@export var shouldMoveContinuously:	bool = true: ## If `true` then the entity keeps moving as long as the input direction is pressed. If `false` then the input must be released before moving again.
	set(newValue):
		if newValue != shouldMoveContinuously:
			shouldMoveContinuously = newValue
			self.set_physics_process(isEnabled and shouldMoveContinuously)

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_physics_process(isEnabled and shouldMoveContinuously)
			Tools.toggleSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput, self.isEnabled)

#endregion


#region State
var recentInputVector: Vector2i:
	set(newValue):
		if newValue != recentInputVector:
			if debugMode: Debug.printChange("recentInputVector", recentInputVector, newValue, self.debugModeTrace) # logAsTrace
			recentInputVector = newValue

@onready var stepTimer: Timer = self.get_node(^".") as Timer
#endregion


#region Dependencies
@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent
@onready var inputComponent:			 InputComponent = parentEntity.findFirstComponentSubclass(InputComponent)

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent, InputComponent]
#endregion


func _ready() -> void:
	# Apply setters because Godot doesn't on initialization
	self.set_physics_process(isEnabled and shouldMoveContinuously)
	Tools.toggleSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput, self.isEnabled)

	# NOTE: Was an input already pressed before this component was ready?
	if not inputComponent.movementDirection.is_zero_approx():
		self.onInputComponent_didProcessInput(null)


func onInputComponent_didProcessInput(_event: InputEvent) -> void:
	if not isEnabled: return
	# Don't return if `inputComponent.movementDirection.is_zero_approx()` because we need to check for 0 to be able to stop moving!

	# TBD: PERFORMANCE: Check for presses & releases only, or accept analog input too?
	# if GlobalInput.hasActionTransitioned(GlobalInput.Actions.moveLeft) \
	# or GlobalInput.hasActionTransitioned(GlobalInput.Actions.moveRight) \
	# or GlobalInput.hasActionTransitioned(GlobalInput.Actions.moveUp) \
	# or GlobalInput.hasActionTransitioned(GlobalInput.Actions.moveDown):

	if shouldAllowDiagonals:
		self.recentInputVector = Vector2i(int(signf(inputComponent.movementDirection.x)), int(signf(inputComponent.movementDirection.y)))
	else: # Fractional axis values will get zeroed in the conversion to integers.
		self.recentInputVector = Vector2i(inputComponent.movementDirection)

	move()


func _physics_process(_delta: float) -> void:
	move()


## Tells the [TileBasedPositionComponent] to move to the [member recentInputVector].
## Uses a [Timer] to add a delay between each step.
## NOTE: Does not depend on [member isEnabled]
func move() -> void:
	if is_zero_approx(recentInputVector.length()) or not is_zero_approx(stepTimer.time_left) or not tileBasedPositionComponent.tileMap:
		return

	tileBasedPositionComponent.inputVector = self.recentInputVector
	tileBasedPositionComponent.processMovementInput()
	stepTimer.start()
