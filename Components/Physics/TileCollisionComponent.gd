## Monitors an [Area2D] and emits signals when it collides with a [TileMapLayer], including the specific cell coordinates.

class_name TileCollisionComponent
extends AreaCollisionComponent


#region Signals
signal didEnterTileCell(map: TileMapLayer, cellCoordinates: Vector2i) ## Emitted AFTER [signal AreaCollisionComponent.didEnterBody]
signal didExitTileCell(map:  TileMapLayer, cellCoordinates: Vector2i) ## Emitted AFTER [signal AreaCollisionComponent.didExitBody]
#endregion


#region State
var currentZones: Array[Area2D] ## The list of [Area2D]s which belong to the "zones" group and overlap this component's area.
#endregion


func _ready() -> void:
	self.shouldMonitorAreas  = false
	self.shouldMonitorBodies = true
	self.shouldConnectSignalsOnReady = true
	super._ready()


#region Events

## Overrides [method AreaCollisionComponent.connectSignals] to only monitor physics "bodies" which include [TileMapLayer]s
## Affected by [member shouldMonitorBodies]
func connectSignals() -> void:
	if shouldMonitorBodies:
		Tools.connectSignal(area.body_shape_entered, self.onBodyShapeEntered)
		Tools.connectSignal(area.body_shape_exited,  self.onBodyShapeExited)


# DESIGN: All functions below: Only look for TileMapLayers.
# Ignore collisions when the node is the parent Entity or any of its children.
# Call Cell signals/methods before the Body signals, in case the body handlers modify the TileMap afterwards.


@warning_ignore("unused_parameter")
func onBodyShapeEntered(bodyRID: RID, bodyEntered: Node2D, bodyShapeIndex: int, localShapeIndex: int) -> void:
	if not isEnabled or bodyEntered is not TileMapLayer or bodyEntered == self.parentEntity or bodyEntered.owner == self.parentEntity: return
	var cellCoordinates: Vector2i = bodyEntered.get_coords_for_body_rid(bodyRID)

	if debugMode:
		printDebug(str("TileMapLayer entered: ", bodyEntered, " @", cellCoordinates))
		TextBubble.create(str("IN ", cellCoordinates), self.parentEntity).label.label_settings.font_color = Color.GREEN

	self.onCollideCell(bodyEntered, cellCoordinates)
	self.onCollide(bodyEntered)
	didEnterTileCell.emit(bodyEntered, cellCoordinates)
	didEnterBody.emit(bodyEntered)


@warning_ignore("unused_parameter")
func onBodyShapeExited(bodyRID: RID, bodyExited: Node2D, bodyShapeIndex: int, localShapeIndex: int) -> void:
	if bodyExited is not TileMapLayer or bodyExited == self.parentEntity or bodyExited.owner == self.parentEntity: return
	var cellCoordinates: Vector2i = bodyExited.get_coords_for_body_rid(bodyRID)

	if debugMode:
		printDebug(str("TileMapLayer exited: ", bodyExited, " @", cellCoordinates))
		TextBubble.create(str("EX ", cellCoordinates), self.parentEntity).label.label_settings.font_color = Color.CYAN

	self.onExitCell(bodyExited, cellCoordinates)
	self.onExit(bodyExited)
	didExitTileCell.emit(bodyExited, cellCoordinates)
	didExitBody.emit(bodyExited)

#endregion


#region Abstract Methods

## Called when a [TileMapLayer] comes into contact.
## NOTE: Called BEFORE [method AreaCollisionComponent.onCollide] → [signal didEnterTileCell] → [signal AreaCollisionComponent.didEnterBody]
## Abstract; Must be implemented by subclass.
@warning_ignore("unused_parameter")
func onCollideCell(map: TileMapLayer, cellCoordinates: Vector2i) -> void:
	pass


## Called when a [TileMapLayer] leaves contact.
## NOTE: Called BEFORE [method AreaCollisionComponent.onExit] → [signal didExitTileCell] → [signal AreaCollisionComponent.didExitBody]
## Abstract; Must be implemented by subclass.
@warning_ignore("unused_parameter")
func onExitCell(map: TileMapLayer, cellCoordinates: Vector2i) -> void:
	pass

#endregion
