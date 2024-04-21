class_name BulletEntity
extends Entity


## Should the bullet be removed on any collision that matches the [collision_mask] of the Entity's [Area2D]?
## This does NOT apply to the [DamageComponent]'s area.
@export var removeOnAnyCollision := true

## Should the bullet be removed when the [DamageComponent] collides with a [DamageReceivingComponent]?
@export var removeOnCollisionWithDamageReceiver := true


func onDamageComponent_didCollideWithReceiver(damageReceivingComponent: DamageReceivingComponent) -> void:
	if removeOnCollisionWithDamageReceiver:
		self.requestRemoval()


func onAreaEntered(area: Area2D) -> void:
	if not area.owner == self: onCollide()


func onBodyEntered(body: Node2D) -> void:
	if not body.owner == self: onCollide()


func onCollide():
	if removeOnAnyCollision:
		self.requestRemoval()
