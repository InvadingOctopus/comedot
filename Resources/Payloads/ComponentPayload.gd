## A [Payload] which creates or removes [Components] for a receiving [Entity].
## TIP: To attach instances of general Scenes and Nodes, use [NodePayload]

class_name ComponentPayload
extends Payload


#region Parameters
@export var componentsToRemove: Array[Script] ## Occurs BEFORE [member componentsToCreate]
@export var componentsToCreate: Array[Script] ## Occurs AFTER [member componentsToRemove]
#endregion


## Returns an array of [Component]s that were created from the [member componentsToCreate] list.
func executeImplementation(source: Variant, target: Variant) -> Array[Component]:
	printLog(str("executeImplementation() componentsToRemove: ", componentsToRemove, ", componentsToCreate: ", componentsToCreate, ", source: ", source, ", target: ", target))
	
	if self.componentsToRemove.is_empty() and self.componentsToCreate.is_empty():
		Debug.printWarning("No componentsToRemove or componentsToCreate", self.logName)
		return []

	if target is not Entity:
		Debug.printWarning(str("Payload target is not an Entity: ", target), self.logName)
		return []
	
	self.willExecute.emit(source, target)
	removeComponents(target as Entity)
	return createComponents(target as Entity)


func removeComponents(entity: Entity) -> void:
	if not Entity or componentsToRemove.is_empty(): return
	entity.removeComponents(componentsToRemove)


## Returns an array of the newly created [Component]s.
func createComponents(entity: Entity) -> Array[Component]:
	if not Entity or componentsToCreate.is_empty(): return []
	var newComponents: Array[Component] = entity.createNewComponents(componentsToCreate)
	return newComponents
