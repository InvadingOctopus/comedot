## Adds or removes a specified set of components, or removes the parent Entity itself, when an [Area2D] collides with another area or [PhysicsBody2D] with matching physics masks.
## May be used for bullets to remove the bullet on collision with terrain etc.
## TIP: In the case of arrow-like projectiles, remove the [DamageComponent] and [LinearMotionComponent] to have the arrow get "stuck" in the ground or other objects,
## or add a hypothetical [ExplosionComponent] to animate an explosion and THEN remove the projectile entity.
## TIP: To remove the entity or add/remove components after a specific period of time, use [ModifyOnTimerComponent]

class_name ModifyOnCollisionComponent
extends AreaCollisionComponent


#region Parameters
@export var shouldRemoveEntity: bool		  ## Removes the entity itself. NOTE: Prevents the addition or removal of components or nodes.
@export var nodesToRemove:		Array[Node]   ## Occurs BEFORE [member componentsToRemove]. Overridden by [member shouldRemoveEntity]
@export var componentsToRemove: Array[Script] ## Occurs BEFORE [member componentsToCreate] and AFTER [member nodesToRemove]. Overridden by [member shouldRemoveEntity]
@export var componentsToCreate: Array[Script] ## Occurs AFTER [member componentsToRemove]. Overridden by [member shouldRemoveEntity]
@export var payload:			Payload		  ## An optional [Payload] to execute. The `source` is this component's parent [Entity] and the `target` is the colliding Node. Occurs last.
#endregion


#region Signals
signal willRemoveEntity
signal didAddComponents(components: Array[Component])
#endregion


func _ready() -> void:
	super.connectSignals()


func onCollide(collidingNode: Node2D) -> void:
	if not isEnabled: return
	if debugMode: printDebug(str("onCollide() area: ", self.area, ", collidingNode: ", collidingNode, ", shouldRemoveEntity: ", shouldRemoveEntity, ", nodesToRemove: ", nodesToRemove, ", componentsToRemove: ", componentsToRemove, ", componentsToCreate: ", componentsToCreate, ", payload: ", payload))
	
	super.onCollide(collidingNode)

	if shouldRemoveEntity:
		self.willRemoveEntity.emit()
		self.requestDeletionOfParentEntity()

	else:
		var entity: Entity = self.parentEntity # NOTE: Save the parent Entity in case THIS component ITSELF is among the removed nodes! Which invalidates parentEntity

		# Check for valid parents to avoid crashes if we collided TOO soon :')

		for node in nodesToRemove:
			if is_instance_valid(node.get_parent()): node.get_parent().remove_child(node)
			node.queue_free() # TBD: Should this be optional?
		
		if is_instance_valid(entity):
			entity.removeComponents(componentsToRemove)
			didAddComponents.emit(entity.createNewComponents(componentsToCreate))
		
		if payload: payload.execute(self.parentEntity, collidingNode)
