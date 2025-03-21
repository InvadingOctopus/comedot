## Monitors an [Area2D] and emits signals when it collides with a [TileMapLayer], including the specific cell coordinates.
## IMPORTANT: To detect [TileMapLayer]s, BOTH [member Area2D.monitoring] & [member Area2D.monitorable] flags must be enabled!
## WORKAROUND: Godot 4.5.dev1: [member TileMapLayer.physics_quadrant_size] must be set to 1

class_name TileCollisionComponent
extends AreaComponentBase


#region Parameters
## If `false`, no new collisions are reported.
## Also effects [member Area2D.monitoring] & [member Area2D.monitorable]
## NOTE: Does NOT affect the EXIT signals for TileMap cells which leave contact with this component.
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			if area:
				selfAsArea.monitoring  = isEnabled
				selfAsArea.monitorable = isEnabled
#endregion


#region Signals
signal didEnterTileCell(map: TileMapLayer, cellCoordinates: Vector2i)
signal didExitTileCell(map:  TileMapLayer, cellCoordinates: Vector2i)
#endregion


func _ready() -> void:
	Tools.connectSignal(area.body_shape_entered, self.onBodyShapeEntered)
	Tools.connectSignal(area.body_shape_exited,  self.onBodyShapeExited)


#region Events

# DESIGN: All functions below: Only look for TileMapLayers.
# Ignore collisions when the node is the parent Entity or any of its children.
# Call Cell signals/methods before the Body signals, in case the body handlers modify the TileMap afterwards.


@warning_ignore("unused_parameter")
func onBodyShapeEntered(bodyRID: RID, bodyEntered: Node2D, bodyShapeIndex: int, localShapeIndex: int) -> void:
	if not isEnabled or bodyEntered == self.parentEntity or bodyEntered.owner == self.parentEntity: return
	if bodyEntered is TileMapLayer: # Dummy Godot can't cast without this
		if bodyEntered.physics_quadrant_size != 1:
			printWarning(str("TileMapLayer.physics_quadrant_size is not 1! Cannot get cell coordinates: ", bodyEntered))
			return

		var cellCoordinates: Vector2i = bodyEntered.get_coords_for_body_rid(bodyRID)

		if debugMode:
			printDebug(str("TileMapLayer entered: ", bodyEntered, " @", cellCoordinates))
			TextBubble.create(str("IN ", cellCoordinates), self.parentEntity).label.label_settings.font_color = Color.GREEN

		self.onCollideCell(bodyEntered, cellCoordinates)
		didEnterTileCell.emit(bodyEntered, cellCoordinates)


## NOTE: If the cell was destroyed, for example by [method Tools.damageTileMapCell], then the coordinates are reported as (-1,-1)
@warning_ignore("unused_parameter")
func onBodyShapeExited(bodyRID: RID, bodyExited: Node2D, bodyShapeIndex: int, localShapeIndex: int) -> void:
	if bodyExited == self.parentEntity or bodyExited.owner == self.parentEntity: return
	if bodyExited is TileMapLayer: # Dummy Godot can't cast without this
		if bodyExited.physics_quadrant_size != 1:
			printWarning(str("TileMapLayer.physics_quadrant_size is not 1! Cannot get cell coordinates: ", bodyExited))
			return

		var cellCoordinates: Vector2i
		cellCoordinates = bodyExited.get_coords_for_body_rid(bodyRID) if bodyExited.has_body_rid(bodyRID) else Vector2i(-1, -1) # Avoid errors if the cell is being destroyed.

		if debugMode:
			printDebug(str("TileMapLayer exited: ", bodyExited, " @", cellCoordinates))
			TextBubble.create(str("EX ", cellCoordinates), self.parentEntity).label.label_settings.font_color = Color.CYAN

		self.onExitCell(bodyExited, cellCoordinates)
		didExitTileCell.emit(bodyExited, cellCoordinates)

#endregion


#region Abstract Methods

## Called when a [TileMapLayer] comes into contact.
## NOTE: Called BEFORE [signal didEnterTileCell]
## Abstract; Must be implemented by subclass.
@warning_ignore("unused_parameter")
func onCollideCell(map: TileMapLayer, cellCoordinates: Vector2i) -> void:
	pass


## Called when a [TileMapLayer] leaves contact.
## NOTE: If the cell was destroyed, for example by [method Tools.damageTileMapCell], then the [param cellCoordinates] are reported as (-1,-1)
## NOTE: Called BEFORE [signal didExitTileCell]
## Abstract; Must be implemented by subclass.
@warning_ignore("unused_parameter")
func onExitCell(map: TileMapLayer, cellCoordinates: Vector2i) -> void:
	pass

#endregion
