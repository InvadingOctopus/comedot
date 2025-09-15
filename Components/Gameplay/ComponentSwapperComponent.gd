## Swaps between different [ComponentSet]s, adding & removing components to/from the entity when a new set is chosen.
## @experimental

class_name ComponentSwapperComponent
extends Component


#region Parameters
@export var componentSets: Dictionary[StringName, ComponentSet]
@export var shouldFree: bool = true ## Call [method Node.queue_free] on [Component]s when swapping them out?
#endregion


#region State

@export_storage var currentSetName: StringName

var currentSet: ComponentSet:
	get: return componentSets.get(currentSetName)

#endregion


#region Signals
signal willLoadSet(setName:		StringName)
signal didLoadSet(setName:		StringName, components: Array[Component])

signal willRemoveSet(setName:	StringName, components: Array[Script])
signal didRemoveSet(setName:	StringName)
#endregion


#region Control

## Removes the [member currentSet] of components from the entity and loads the specified [ComponentSet].
## Set [param forceReload] to reload the [member currentSet] if the [param newSetName] is the same.
## Returns: The number of components added.
func swapToSet(newSetName: StringName, forceReload: bool = false) -> int:
	if newSetName.is_empty():
		printWarning("Empty newSetName")
		return 0
	elif not componentSets.has(newSetName):
		printWarning("componentSets has no set named: " + newSetName)
		return 0

	# Reload current set if the name is the same?
	if not self.currentSetName.is_empty() \
	and self.currentSetName == newSetName \
	and not forceReload:
		if debugMode: printDebug("swapToSet() currentSetName == newSetName and not forceReload: " + newSetName)
		return 0

	# Remove any currently active components from the previous set
	if not currentSetName.is_empty() and currentSet:
		printLog("swapToSet(): " + currentSetName + " → " + newSetName)
		self.removeCurrentSet() # Clears componentsRecentlySwappedIn
	else:
		printLog("swapToSet() → " + newSetName)

	# Swap the new set in
	willLoadSet.emit(newSetName)
	var newComponentSet: ComponentSet	  = componentSets[newSetName]
	var newComponents:	 Array[Component] = parentEntity.createNewComponents(newComponentSet.components)

	# Update state
	if not newComponents.is_empty():
		self.currentSetName = newSetName
		didLoadSet.emit(currentSetName, newComponents)
		return newComponents.size()
	else:
		printWarning("Entity.createNewComponents() returned 0 components when swapping in " + newSetName)
		return 0


## Clears [param componentsRecentlySwappedIn] and removes the [member currentSet] of components from the entity.
## Returns: The number of components removed.
func removeCurrentSet(shouldFreeOverride: bool = self.shouldFree) -> int:
	if currentSetName.is_empty():
		printLog("removeCurrentSet(): No currentSetName")
		return 0
	elif not componentSets.has(currentSetName) or not currentSet:
		printWarning("componentSets has no set named: " + currentSetName)
		return 0
	elif currentSet.components.is_empty():
		if debugMode: printDebug(str("removeCurrentSet(): currentSet has no components: ", currentSet))
		return 0

	willRemoveSet.emit(currentSetName, self.currentSet)

	# DESIGN: Use [currentSet] not [componentsRecentlySwappedIn]
	# to ensure removal even if other component instances were later added to the entiy,
	# Because that will be the expected behavior: If a component's name is on the list, it MUST be added/removed.
	var removedComponentsCount: int = parentEntity.removeComponents(self.currentSet.components, shouldFreeOverride)
	var removedSetName: StringName = currentSetName
	currentSetName = "" # Clear the name before the signal
	didRemoveSet.emit(removedSetName)

	return removedComponentsCount

#endregion
