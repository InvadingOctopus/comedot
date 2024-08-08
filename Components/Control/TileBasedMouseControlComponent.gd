## Snaps the [TileBasedPositionComponent]'s coordinates to the mouse pointer.
## Used for displaying selection cursors etc.
## Requirements: [TileBasedPositionComponent]

class_name TileBasedMouseControlComponent
extends Component

# TODO: Only update on mouse movement


#region Parameters
@export var isEnabled: bool = true
#endregion


#region State

var tileBasedPositionComponent: TileBasedPositionComponent:
	get:
		if not tileBasedPositionComponent: tileBasedPositionComponent = self.getCoComponent(TileBasedPositionComponent)
		return tileBasedPositionComponent

#endregion


## Returns a list of required component types that this component depends on.
func getRequiredcomponents() -> Array[Script]:
	return [TileBasedPositionComponent]


#func _input(event: InputEvent) -> void:
func _process(_delta: float) -> void:
	if not isEnabled: return

	var tileMap: TileMapLayer = tileBasedPositionComponent.tileMap
	tileBasedPositionComponent.currentCellCoordinates = tileMap.local_to_map(tileMap.get_local_mouse_position())
	tileBasedPositionComponent.snapEntityPositionToTile(tileBasedPositionComponent.currentCellCoordinates)
