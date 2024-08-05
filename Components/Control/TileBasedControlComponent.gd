## Provides player input to a [TileBasedPositionComponent].
## Requirements: [TileBasedPositionComponent]

class_name TileBasedControlComponent
extends Component

# TODO: Allow movement on input `is_just_released`


#region Parameters
@export var isEnabled:				bool = true
@export var shouldAllowDiagonals:	bool = false
@export var shouldMoveContinuously:	bool = true
#endregion


#region State

var tileBasedPositionComponent: TileBasedPositionComponent:
	get:
		if not tileBasedPositionComponent: tileBasedPositionComponent = self.getCoComponent(TileBasedPositionComponent)
		return tileBasedPositionComponent

var recentInputVector: Vector2i

@onready var timer: Timer = $Timer

#endregion


## Returns a list of required component types that this component depends on.
func getRequiredcomponents() -> Array[Script]:
	return [TileBasedPositionComponent]


func _input(event: InputEvent) -> void:
	if not isEnabled or not event.is_action_type(): return
		
	if GlobalInput.hasActionTransitioned(GlobalInput.Actions.moveLeft) \
	or GlobalInput.hasActionTransitioned(GlobalInput.Actions.moveRight) \
	or GlobalInput.hasActionTransitioned(GlobalInput.Actions.moveUp) \
	or GlobalInput.hasActionTransitioned(GlobalInput.Actions.moveDown):
		
		var inputVectorFloat: Vector2 = Input.get_vector(
			GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, \
			GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
		
		if shouldAllowDiagonals:
			self.recentInputVector = Vector2i(signf(inputVectorFloat.x), signf(inputVectorFloat.y)) # IGNORE Godot Warning; float to int conversion is obvious.
		else: # Fractional axis values will get zeroed in the conversion to integers
			self.recentInputVector = Vector2i(inputVectorFloat)	
			
		if shouldShowDebugInfo: printDebug(str(recentInputVector))
		
		move()
		


func _physics_process(_delta: float) -> void:
	if not isEnabled or not shouldMoveContinuously: return	
	
	move()


## Tells the [TileBasedPositionComponent] to move to the [member recentInputVector].
## Uses a [Timer] to add a delay between each step.
## NOTE: Does not depend on [member isEnabled]
func move() -> void:
	if is_zero_approx(recentInputVector.length()) or not is_zero_approx(timer.time_left):
		return
	
	tileBasedPositionComponent.inputVector = self.recentInputVector
	tileBasedPositionComponent.processMovementInput()
	timer.start()
