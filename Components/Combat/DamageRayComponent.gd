## A subclass of [DamageComponent] that uses a [RayCast2D] instead of an [Area2D] for physics collisions.
## NOTE: Prevents one projectile from colliding with multiple overlapping [DamageReceivingComponent]s in a single physics frame;
## only the first physics contact is reported in a collision.
## TIP: May be more suitable for projectiles such as arrows and small bullets.
## @experimental

class_name DamageRayComponent
extends DamageComponent

# TBD: Also use [Area2D]-based signals and THEN check the [RayCast2D]?
# Ensure onAreaExited() is called? To remove `damageReceivingComponentsInContact`?


#region State
@onready var selfAsRayCast: RayCast2D = self.get_node(^".") as RayCast2D
#endregion


func _physics_process(_delta: float) -> void:
	if selfAsRayCast.is_colliding():
		var collidingObject := selfAsRayCast.get_collider()
		if debugMode: printDebug(str(collidingObject))
		if collidingObject is Area2D:
			self.onAreaEntered(collidingObject)
