## Provides player input to a [TileBasedPositionComponent].
## Requirements: [TileBasedPositionComponent]

class_name GridControlComponent
extends Component


#region Parameters
@export var isEnabled: bool = true
#endregion


#region State

var tileBasedPositionComponent: TileBasedPositionComponent:
	get:
		if not tileBasedPositionComponent: tileBasedPositionComponent = self.getCoComponent(TileBasedPositionComponent)
		return tileBasedPositionComponent

var recentInputVector: Vector2i

#endregion


#region Signals
#endregion


## Returns a list of required component types that this component depends on.
func getRequiredcomponents() -> Array[Script]:
	return [TileBasedPositionComponent]


func _input(event: InputEvent) -> void:
	if not isEnabled or not event.is_action_type(): return
	
	if event.is_action_pressed(GlobalInput.Actions.moveLeft) \
	or event.is_action_pressed(GlobalInput.Actions.moveRight) \
	or event.is_action_pressed(GlobalInput.Actions.moveUp) \
	or event.is_action_pressed(GlobalInput.Actions.moveDown):
		
		self.recentInputVector = Vector2i(Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown))
		
		if not is_zero_approx(recentInputVector.length()):
			tileBasedPositionComponent.processMovementInput(self.recentInputVector)
