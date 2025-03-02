## Removes or "stops" the parent Entity when the specified [Area2D] collides with another area or [PhysicsBody2D] which matches the physics masks.

class_name RemovalOnCollisionComponent
extends AreaComponentBase

# TODO: Add delay Timer


#region Signals
signal willRemoveEntity
#endregion


func _ready() -> void:
	super.connectSignals()


func onCollide(_collidingNode: Node2D) -> void:
	if not isEnabled: return
	self.willRemoveEntity.emit()
	self.requestDeletionOfParentEntity()
