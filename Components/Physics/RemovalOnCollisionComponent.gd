## Removes the parent Entity when the specified [Area2D] collides with another area or [PhysicsBody2D] (that matches the physics masks.)

class_name RemovalOnCollisionComponent
extends AreaManipulatingComponentBase

# TODO: Add delay Timer


#region Parameters
@export var isEnabled: bool = true
#endregion


#region Signals
signal willRemoveEntity
#endregion


func _ready() -> void:
	connectSignals()


func connectSignals() -> void:
	Tools.reconnectSignal(area.area_entered, onArea_areaEntered)
	Tools.reconnectSignal(area.body_entered, onArea_bodyEntered)


func onArea_areaEntered(areaEntered: Area2D) -> void:
	if debugMode: printDebug(str("areaEntered: ", areaEntered, ", owner: ", areaEntered.owner))
	if not isEnabled or areaEntered.owner == self or areaEntered.owner == self.parentEntity: return # Avoid running into ourselves
	self.onCollide()


func onArea_bodyEntered(bodyEntered: Node2D) -> void:
	if debugMode: printDebug(str("bodyEntered: ", bodyEntered, ", owner: ", bodyEntered.owner))
	if not isEnabled or bodyEntered.owner == self or bodyEntered.owner == self.parentEntity: return # Avoid running into ourselves
	self.onCollide()


func onCollide() -> void:
	if not isEnabled: return
	self.willRemoveEntity.emit()
	self.requestDeletionOfParentEntity()
