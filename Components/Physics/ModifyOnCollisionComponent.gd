## Adds or removes a specified set of components, or removes the parent Entity itself, when an [Area2D] collides with another area or [PhysicsBody2D] with matching physics masks.
## May be used for bullets to remove the bullet on collision with terrain etc.
## TIP: In the case of arrow-like projectiles, remove the [DamageComponent] and [LinearMotionComponent] to have the arrow get "stuck" in the ground or other objects,
## or add a hypothetical [ExplosionComponent] to animate an explosion and THEN remove the projectile entity.

class_name RemovalOnCollisionComponent
extends AreaComponentBase

# TODO: Add delay Timer


#region Parameters
@export var shouldRemoveEntity: bool = false  ## Prevents the addition or removal of components.
@export var componentsToRemove: Array[Script] ## Occurs BEFORE [member componentsToAdd]. Overridden by [member shouldRemoveEntity]
@export var componentsToCreate: Array[Script] ## Occurs AFTER [member componentsToRemove]. Overridden by [member shouldRemoveEntity]
#endregion


#region Signals
signal willRemoveEntity
signal didAddComponents(components: Array[Component])
#endregion


func _ready() -> void:
	super.connectSignals()


func onCollide(_collidingNode: Node2D) -> void:
	if not isEnabled: return
	if shouldRemoveEntity:
		self.willRemoveEntity.emit()
		self.requestDeletionOfParentEntity()
	else:
		parentEntity.removeComponents(componentsToRemove)
		didAddComponents.emit(parentEntity.addNewComponents(componentsToCreate))
