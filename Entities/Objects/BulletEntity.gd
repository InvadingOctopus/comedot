## A base class for any [Entity] which represents bullets or other "bullet-like" projectiles.
## IMPORTANT: An entity can NOT cause any damage or move on its own: Add [DamageComponent], [LinearMotionComponent], and [OffscreenRemovalComponent].

class_name BulletEntity
extends Entity

# TBD: Move the removal-on-collision functionality to a component.


#region Parameters

## Should the bullet be removed on any collision that matches the [collision_mask] of the Entity's [Area2D]?
## This does NOT apply to the [DamageComponent]'s area.
@export var removeOnAnyCollision: bool = true



#endregion


#region Collisions

func onAreaEntered(areaEntered: Area2D) -> void:
	if not areaEntered.owner == self: 
		if shouldShowDebugInfo: printDebug(str(areaEntered))
		onCollide()


func onBodyEntered(bodyEntered: Node2D) -> void:
	if not bodyEntered.owner == self:
		if shouldShowDebugInfo: printDebug(str(bodyEntered))
		onCollide()


func onCollide() -> void:
	if removeOnAnyCollision:
		printDebug("onCollide(): removeOnAnyCollision")
		self.requestDeletion()

#endregion
