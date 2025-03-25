## Base class for components that add or remove other components, nodes, or remove the parent Entity itself.
## To use, call these methods from other scripts or connect via Signals: [method removeNodes], [method removeComponents], [method createComponents], [method removeEntity]
## TIP: To add/remove nodes based on physics collisions, use [ModifyOnCollisionComponent].
## For modifying nodes after a specific period of time, use [ModifyOnTimerComponent]

class_name NodeModifierComponentBase
extends Component


#region Parameters
@export var shouldRemoveEntity: bool			## Removes the entity itself. NOTE: Prevents the addition or removal of components or nodes.
@export var nodesToRemove:		Array[Node]		## Occurs BEFORE [member componentsToRemove]. Overridden by [member shouldRemoveEntity]
@export var componentsToRemove: Array[Script]	## Occurs BEFORE [member componentsToCreate] and AFTER [member nodesToRemove]. Overridden by [member shouldRemoveEntity]
@export var componentsToCreate: Array[Script]	## Occurs AFTER [member componentsToRemove]. Overridden by [member shouldRemoveEntity]
@export var payload:			Payload			## An optional [Payload] to execute. The `source` is this component's parent [Entity] and the `target` depends on the subclass implementation (`null` by default). Occurs last.
@export var isEnabled:			bool = true
#endregion


#region State
var savedParentEntity: Entity # NOTE: Save the parent Entity in case THIS component ITSELF is among the removed nodes! because that invalidates parentEntity
#endregion


#region Signals
signal willRemoveEntity
signal didAddComponents(components: Array[Component])
#endregion


func removeEntity() -> void:
	if debugMode: printDebug(str("removeEntity(): ", shouldRemoveEntity, ", isEnabled: " if isEnabled else ""))
	if not isEnabled or not shouldRemoveEntity or not is_instance_valid(parentEntity): return
	savedParentEntity = self.parentEntity
	self.willRemoveEntity.emit()
	self.requestDeletionOfParentEntity()


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
	

## Returns an array of the newly created [Component]s.
func createComponents(entityOverride: Entity = self.savedParentEntity) -> Array[Component]:
	if debugMode: printDebug(str("createComponents(): ", componentsToCreate, ", isEnabled" if isEnabled else ""))
	if not isEnabled or componentsToCreate.is_empty(): return []
	var newComponents: Array[Component] = entityOverride.createNewComponents(componentsToCreate)
	didAddComponents.emit(newComponents)
	return newComponents


func executePayload(target: Variant) -> void:
	if debugMode: printDebug(str("executePayload(): ", payload, ", target: ", target))
	if payload: payload.execute(self.parentEntity, target)


## Calls all the other methods in order: If [member shouldRemoveEntity] then only [method removeEntity], otherwise: [method removeNodes] → [method removeComponents] → [method createComponents]
func performAllModifications() -> void:
	if shouldRemoveEntity:
		removeEntity()
	else:
		removeNodes()
		removeComponents()
		createComponents()
		executePayload(null)
