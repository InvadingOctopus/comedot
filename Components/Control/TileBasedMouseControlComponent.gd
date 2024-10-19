## Snaps the [TileBasedPositionComponent]'s coordinates to the mouse pointer.
## Used for displaying selection cursors etc.
## Requirements: [TileBasedPositionComponent]

class_name TileBasedMouseControlComponent
extends Component

# TODO: Option to ignore mouse outside the window


#region Parameters
@export var isEnabled: bool = true
#endregion


#region Dependencies
@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent # TBD: Static or dynamic?

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent]
#endregion


func _input(event: InputEvent) -> void:
	if not isEnabled or not event is InputEventMouseMotion: return

	var tileMap: TileMapLayer = tileBasedPositionComponent.tileMap
	tileBasedPositionComponent.currentCellCoordinates = tileMap.local_to_map(tileMap.get_local_mouse_position())
	tileBasedPositionComponent.snapEntityPositionToTile(tileBasedPositionComponent.currentCellCoordinates)
