## A [Payload] variant of [ComponentPayload] to persist changes to state.
## Creates or removes [Component]s for a receiving [Entity] with a [SaveComponent].

class_name PersistComponentPayload
extends ComponentPayload


## Overrides [method ComponentPayload.removeComponents] to persist changes via [SaveComponent].
func removeComponents(entity: Entity) -> void:
	if not is_instance_valid(entity) or componentsToRemove.is_empty() or not entity.hasComponent(SaveComponent):
		return
	
	var saveComponent: SaveComponent = entity.getComponent(SaveComponent)
	saveComponent.removeComponentsPersist(componentsToRemove)


## Overrides [method ComponentPayload.createComponents] to persist changes via [SaveComponent].
## Returns an array of the newly created [Component]s.
func createComponents(entity: Entity) -> Array[Component]:
	if not is_instance_valid(entity) or componentsToCreate.is_empty() or not entity.hasComponent(SaveComponent):
		return []
	
	var saveComponent: SaveComponent = entity.getComponent(SaveComponent)
	return saveComponent.createNewComponentsPersist(componentsToCreate)
