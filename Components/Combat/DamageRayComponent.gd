## A subclass of [DamageComponent] that uses a [RayCast2D] instead of an [Area2D] for physics collisions.
## NOTE: Prevents one projectile from colliding with multiple overlapping [DamageReceivingComponent]s in a single physics frame;
## only the first physics contact is reported in a collision.
## TIP: May be more suitable for projectiles such as arrows and small bullets.
## @experimental

class_name DamageRayComponent
extends DamageComponent

# TODO: Compare performance impact.
# TODO: Remove excluded hurtboxes after leaving their area, so we can try to roll again when re-entering them.
# TBD:  Also use [Area2D]-based signals and THEN check the [RayCast2D]?
# TBD:  Ensure onAreaExited() is called? To remove `damageReceivingComponentsInContact`?


#region Parameters
## If `true` and the [RayCast2D] collides with multiple physics objects in the same frame,
## then this component will continue searching through those objects until a [DamageReceivingComponent] is found.
## If `false` then only the first colliding object is reported.
## WARNING: May impact performance.
@export var shouldSearchForDamageReceiver: bool = true
#endregion


#region State
@onready var selfAsRayCast: RayCast2D = self.get_node(^".") as RayCast2D
var recentCollidingObject:  Object # PERFORMANCE: Store as a class property to avoid recreating it on every update
#endregion


func _ready() -> void:
	super._ready()
	self.didMiss.connect(onDidMiss)
	self.set_physics_process(isEnabled)


## @experimental
func _physics_process(_delta: float) -> void:
	# if not isEnabled: return # Set by `super.isEnabled` setter and _ready()
	# Keep scanning until a [DamageReceivingComponent] is found, if any.
	while selfAsRayCast.is_colliding():
		recentCollidingObject = selfAsRayCast.get_collider()
		if debugMode: printTrace([recentCollidingObject])
		if recentCollidingObject is DamageReceivingComponent:
			self.onAreaEntered(recentCollidingObject)
			break # Get out of the Matrix
		else:
			selfAsRayCast.add_exception(recentCollidingObject)
			selfAsRayCast.force_raycast_update()
		if not shouldSearchForDamageReceiver: break


func onDidMiss(damageReceivingComponent: DamageReceivingComponent, _totalChance: int, _roll: int) -> void:
	# NOTE: Do not retry to hit the same DamageReceivingComponent we just missed our chance at,
	# otherwise the chance will be tried EVERY FRAME while this DamageRayComponent remains in the DamageReceivingComponent's hurtbox.
	selfAsRayCast.add_exception(damageReceivingComponent.area)
	# TODO: Remove exception after exiting area
