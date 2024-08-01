class_name BulletEntity
extends Entity


## Should the bullet be removed on any collision that matches the [collision_mask] of the Entity's [Area2D]?
## This does NOT apply to the [DamageComponent]'s area.
@export var removeOnAnyCollision := true

## Should the bullet be removed when the [DamageComponent] collides with a [DamageReceivingComponent]?
@export var removeOnCollisionWithDamageReceiver := true


func onDamageComponent_didCollideWithReceiver(_damageReceivingComponent: DamageReceivingComponent) -> void:
	if removeOnCollisionWithDamageReceiver:
		self.requestDeletion()


func onAreaEntered(areaEntered: Area2D) -> void:
	if not areaEntered.owner == self: onCollide()


func onBodyEntered(bodyEntered: Node2D) -> void:
	if not bodyEntered.owner == self: onCollide()


func onCollide() -> void:
	if removeOnAnyCollision:
		self.requestDeletion()
