## A subclass of [DamageComponent] which causes damage to destructible [TileMapLayer] cells.

class_name TileDamageComponent
extends DamageComponent

# TBD: Add contacts to an array similar to`damageReceivingComponentsInContact`?


#region Collisions

## Suppresses [method DamageComponent.onAreaEntered] to disable collisions with regular [Area2D]s
func onAreaEntered(_areaEntered: Area2D) -> void:
	pass


## Suppresses [method DamageComponent.onAreaExited] to disable collisions with regular [Area2D]s
func onAreaExited(_areaExited: Area2D) -> void:
	# TBD: Should we respect removal of `damageReceivingComponentsInContact`?
	pass


@warning_ignore("unused_parameter")
func onBodyShapeEntered(bodyRID: RID, bodyEntered: Node2D, bodyShapeIndex: int, localShapeIndex: int) -> void:
	if not isEnabled or bodyEntered is not TileMapLayer or bodyEntered == self.parentEntity or bodyEntered.owner == self.parentEntity: return
	var cellCoordinates: Vector2i = bodyEntered.get_coords_for_body_rid(bodyRID)

	if debugMode:
		printDebug(str("TileMapLayer entered: ", bodyEntered, " @", cellCoordinates))
		TextBubble.create.call(str(cellCoordinates), bodyEntered).label.label_settings.font_color = Color.YELLOW
	
	Tools.damageTileMapCell(bodyEntered, cellCoordinates)


@warning_ignore("unused_parameter")
func onBodyShapeExited(bodyRID: RID,  bodyExited: Node2D,  bodyShapeIndex: int, localShapeIndex: int) -> void:
	pass
	# UNUSED:
	# if bodyExited is not TileMapLayer or bodyExited == self.parentEntity or bodyExited.owner == self.parentEntity: return
	# var cellCoordinates: Vector2i = bodyExited.get_coords_for_body_rid(bodyRID)
	# if debugMode: printDebug(str("TileMapLayer exited: ", bodyExited, " @", cellCoordinates))

#endregion
