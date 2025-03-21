## A subclass of [DamageComponent] which causes damage to destructible [TileMapLayer] cells.
## Calls [method Tools.damageTileMapCell] which changes a TileMap cell's tile to a different tile,
## depending on the tile's [member Global.TileMapCustomData.isDestructible] & [member Global.TileMapCustomData.nextTileOnDamage] custom data layers, which must be set in the TileSet itself.
## If there is no "next tile" specified or both X & Y coordinates are below 0 i.e. (-1,-1) then the cell is erased/destroyed.
## WORKAROUND: Godot 4.5.dev1: [member TileMapLayer.physics_quadrant_size] must be set to 1
## @experimental

class_name TileDamageComponent
extends TileCollisionComponent

# TODO: Variable damage & cell health
# TBD: Add contacts to an array similar to`damageReceivingComponentsInContact`?


func _ready() -> void:
	Tools.connectSignal(area.body_shape_entered, self.onBodyShapeEntered)
	# Ignore exits # UNUSED: Tools.connectSignal(area.body_shape_exited,  self.onBodyShapeExited)


#region Collisions

@warning_ignore("unused_parameter")
func onBodyShapeEntered(bodyRID: RID, bodyEntered: Node2D, bodyShapeIndex: int, localShapeIndex: int) -> void:
	# TBD: Remove code duplication from TileCollisionComponent
	if not isEnabled or bodyEntered is not TileMapLayer or bodyEntered == self.parentEntity or bodyEntered.owner == self.parentEntity: return
	if bodyEntered is TileMapLayer: # Dummy Godot can't cast without this
		if bodyEntered.physics_quadrant_size != 1:
			printWarning(str("TileMapLayer.physics_quadrant_size is not 1! Cannot get cell coordinates: ", bodyEntered))
			return
	
		var cellCoordinates: Vector2i = bodyEntered.get_coords_for_body_rid(bodyRID)

		if debugMode:
			printDebug(str("TileMapLayer entered: ", bodyEntered, " @", cellCoordinates))
			TextBubble.create.call(str(cellCoordinates), bodyEntered).label.label_settings.font_color = Color.YELLOW

		Tools.damageTileMapCell(bodyEntered, cellCoordinates) # TBD: Should this happen before signals?
		self.onCollideCell(bodyEntered, cellCoordinates)
		didEnterTileCell.emit(bodyEntered, cellCoordinates)


## Suppresses [method TileCollisionComponent.onBodyShapeExited] to ignore events of leaving physical contact with a [TileMapLayer] cell.
@warning_ignore("unused_parameter")
func onBodyShapeExited(bodyRID: RID,  bodyExited: Node2D,  bodyShapeIndex: int, localShapeIndex: int) -> void:
	pass
	# UNUSED: super.onBodyShapeExited(bodyRID, bodyExited, bodyShapeIndex, localShapeIndex)

#endregion
