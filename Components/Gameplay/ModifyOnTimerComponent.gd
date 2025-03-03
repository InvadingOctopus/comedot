## Adds or removes a specified set of components, or removes the parent Entity itself, after the supplied [Timer] times out.
## NOTE: By default, the `$InternalTimer` child of this component performs ALL actions after 3 seconds, in order:
## [method removeEntity] if [member shouldRemoveEntity] → [method removeNodes] → [method removeComponents] → [method createComponents]
## To use a different time for each of those tasks, enable `Editable Children` and disable `$InternalTimer`, then connect any other [Timer] to any of those methods.
## TIP: To add/remove nodes based on physics collisions, use [ModifyOnCollisionComponent]

class_name ModifyOnTimerComponent
extends Component


#region Parameters
@export var shouldRemoveEntity: bool		  ## Removes the entity itself. NOTE: Prevents the addition or removal of components or nodes.
@export var nodesToRemove:		Array[Node]   ## Occurs BEFORE [member componentsToRemove]. Overridden by [member shouldRemoveEntity]
@export var componentsToRemove: Array[Script] ## Occurs BEFORE [member componentsToAdd] and AFTER [member nodesToRemove]. Overridden by [member shouldRemoveEntity]
@export var componentsToCreate: Array[Script] ## Occurs AFTER [member componentsToRemove]. Overridden by [member shouldRemoveEntity]
@export var isEnabled:			bool = true
#endregion


#region Signals
signal willRemoveEntity
signal didAddComponents(components: Array[Component])
#endregion


#region State
var savedParentEntity: Entity # NOTE: Save the parent Entity in case THIS component ITSELF is among the removed nodes! because that invalidates parentEntity
#endregion


func createComponents() -> void:
	if debugMode: printDebug(str("createComponents(): ", componentsToCreate, ", isEnabled" if isEnabled else ""))
	if not isEnabled or componentsToCreate.is_empty(): return
	didAddComponents.emit(savedParentEntity.createNewComponents(componentsToCreate))


func removeNodes() -> void:
	if debugMode: printDebug(str("removeNodes(): ", nodesToRemove, ", isEnabled: " if isEnabled else ""))
	if not isEnabled or nodesToRemove.is_empty(): return
	if parentEntity: savedParentEntity = self.parentEntity
	for node in nodesToRemove:
		node.get_parent().remove_child(node)
		node.queue_free() # TBD: Should this be optional?


func removeComponents() -> void:
	if debugMode: printDebug(str("removeComponents(): ", componentsToRemove, ", isEnabled: " if isEnabled else ""))
	if not isEnabled or componentsToRemove.is_empty(): return
	if parentEntity: savedParentEntity = self.parentEntity
	savedParentEntity.removeComponents(componentsToRemove)
	

func removeEntity() -> void:
	if debugMode: printDebug(str("removeEntity(): ", shouldRemoveEntity, ", isEnabled: " if isEnabled else ""))
	if not isEnabled or not shouldRemoveEntity or not is_instance_valid(parentEntity): return
	savedParentEntity = self.parentEntity
	self.willRemoveEntity.emit()
	self.requestDeletionOfParentEntity()


func onInternalTimer_timeout() -> void:
	removeEntity() # shouldRemoveEntity checked in method
	removeNodes()
	removeComponents()
	createComponents()
 