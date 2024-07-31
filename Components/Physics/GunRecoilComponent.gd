## Applies a knockback to the [CharacterBody2D] of the parent [Entity] when a [GunComponent] fires a bullet.
class_name GunRecoilComponent
extends CharacterBodyManipulatingComponentBase


# TODO: Beter physics
# TODO: Handle dynamic removal and addition of a [GunComponent]


## The amount to multiply the normalized knockback vector by.
@export_range(0, 1000, 50.0) var knockbackForce: float = 150.0


func _ready() -> void:
	var gunComponent: GunComponent = self.getCoComponent(GunComponent)
	if not gunComponent:
		printError("No GunComponent found in parent Entity: " + parentEntity.logName) # TBD: Warning or Error?
	gunComponent.didFire.connect(self.onGunComponentDidFire)


func onGunComponentDidFire(bullet: Entity) -> void:

	# TODO: Option to apply dynamic knockback based on the bullet's velocity.

	#var bulletLinearMotionComponent: LinearMotionComponent = bullet.getComponent(LinearMotionComponent)

	#if not bulletLinearMotionComponent:
		#printWarning("Bullet entity cannot find a LinearMotionComponent: " + str(bullet))

	# Get the bullet's direction.

	var forceVector := Vector2.from_angle(bullet.global_rotation)

	# Knock the parent entity's body back in the opposite direction.

	forceVector = forceVector * -1
	body.velocity += forceVector * knockbackForce
	characterBodyComponent.queueMoveAndSlide()
