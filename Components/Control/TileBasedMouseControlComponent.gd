## Snaps the [TileBasedPositionComponent]'s coordinates to the mouse pointer.
## Used for displaying selection cursors etc.
## Requirements: [TileBasedPositionComponent]

class_name TileBasedMouseControlComponent
extends Component

# TODO: Option to ignore mouse outside the window


#region Parameters

## If `true`, then the position is updated every frame via the [method Node._process] function. This allows accurate updates when a [TileMapLayer] or [Camera2D] is moving.
## If `false` (default), then the position is only updated when a mouse motion event is received via the [method Node._input] function. This improves performance.
@export var shouldProcessEveryFrame: bool = false:
	set(newValue):
		if newValue != shouldProcessEveryFrame:
			shouldProcessEveryFrame = newValue
			self.set_process(shouldProcessEveryFrame)

@export var isEnabled: bool = true

#endregion


#region Dependencies
@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent # TBD: Static or dynamic?

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent]
#endregion


func _ready() -> void:
	self.set_process(self.shouldProcessEveryFrame)


func _input(event: InputEvent) -> void:
	if not isEnabled or shouldProcessEveryFrame or not event is InputEventMouseMotion: return
	updatePosition()


func _process(_delta: float) -> void:
	if not isEnabled or not shouldProcessEveryFrame: return
	updatePosition()


func updatePosition() -> void:
	var tileMap: TileMapLayer = tileBasedPositionComponent.tileMap
	tileBasedPositionComponent.currentCellCoordinates = tileMap.local_to_map(tileMap.get_local_mouse_position())
	tileBasedPositionComponent.snapEntityPositionToTile(tileBasedPositionComponent.currentCellCoordinates)
