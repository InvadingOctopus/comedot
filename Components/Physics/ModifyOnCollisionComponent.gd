## Adds or removes a specified set of components, or removes the parent Entity itself, when an [Area2D] collides with another area or [PhysicsBody2D] with matching physics masks.
## May be used for bullets to remove the bullet on collision with terrain etc.
## TIP: In the case of arrow-like projectiles, remove the [DamageComponent] and [LinearMotionComponent] to have the arrow get "stuck" in the ground or other objects,
## or add a hypothetical [ExplosionComponent] to animate an explosion and THEN remove the projectile entity.
## TIP: To remove the entity or add/remove components after a specific period of time, use [ModifyOnTimerComponent]

class_name ModifyOnCollisionComponent
extends AreaComponentBase


#region Parameters
@export var shouldRemoveEntity: bool		  ## Removes the entity itself. NOTE: Prevents the addition or removal of components or nodes.
@export var nodesToRemove:		Array[Node]   ## Occurs BEFORE [member componentsToRemove]. Overridden by [member shouldRemoveEntity]
@export var componentsToRemove: Array[Script] ## Occurs BEFORE [member componentsToAdd] and AFTER [member nodesToRemove]. Overridden by [member shouldRemoveEntity]
@export var componentsToCreate: Array[Script] ## Occurs AFTER [member componentsToRemove]. Overridden by [member shouldRemoveEntity]
#endregion


#region Signals
signal willRemoveEntity
signal didAddComponents(components: Array[Component])
#endregion


func _ready() -> void:
	super.connectSignals()


func onCollide(collidingNode: Node2D) -> void:
	if not isEnabled: return
	if debugMode: printDebug(str("onCollide(): ", collidingNode, ", shouldRemoveEntity: ", shouldRemoveEntity, ", nodesToRemove: ", nodesToRemove, ", componentsToRemove: ", componentsToRemove, ", componentsToCreate: ", componentsToCreate))
	if shouldRemoveEntity:
		self.willRemoveEntity.emit()
		self.requestDeletionOfParentEntity()
	else:
		# NOTE: Save the parent Entity in case THIS component ITSELF is among the removed nodes! Which invalidates parentEntity
		var entity: Entity = self.parentEntity
		for node in nodesToRemove:
			node.get_parent().remove_child(node)
			node.queue_free() # TBD: Should this be optional?
		entity.removeComponents(componentsToRemove)
		didAddComponents.emit(entity.createNewComponents(componentsToCreate))
