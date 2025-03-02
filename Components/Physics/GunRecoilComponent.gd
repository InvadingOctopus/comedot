## Applies a knockback to the [CharacterBody2D] of the parent [Entity] when a [GunComponent] fires a bullet.
## TIP: Use a [VelocityClampComponent] to prevent the entity from "rocketing" away when too many bullets are fired too quickly.

class_name GunRecoilComponent
extends CharacterBodyDependentComponentBase

# TODO: Better physics
# TODO: Option to apply dynamic knockback based on the bullet's velocity.
# TODO: Handle dynamic removal and addition of a [GunComponent]


#region Parameters
## The amount to multiply the normalized knockback vector by.
@export_range(0, 1000, 50.0) var knockbackForce: float = 150.0

@export var isEnabled: bool = true
#endregion


#region Dependencies
@onready var gunComponent: GunComponent = coComponents.GunComponent # TBD: Static or dynamic?
#endregion


func _ready() -> void:
	if not gunComponent:
		printWarning("No GunComponent found in parent Entity: " + parentEntity.logName) # TBD: Warning or Error?
	gunComponent.didFire.connect(self.onGunComponentDidFire)


func onGunComponentDidFire(bullet: Entity) -> void:
	if not isEnabled: return

	#var bulletLinearMotionComponent: LinearMotionComponent = bullet.getComponent(LinearMotionComponent)

	#if not bulletLinearMotionComponent:
		#printWarning("Bullet entity cannot find a LinearMotionComponent: " + str(bullet))

	# Get the bullet's direction.

	var forceVector: Vector2 = Vector2.from_angle(bullet.global_rotation)

	# Knock the parent entity's body back in the opposite direction.

	forceVector = forceVector * -1
	body.velocity += forceVector * knockbackForce
	characterBodyComponent.queueMoveAndSlide()
