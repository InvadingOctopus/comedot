## Handles saving and loading of component state for an [Entity].
## Records component additions, removals, and modifications to persist across game sessions.
## Requirements: [SavableStateManager] must be added to GameState nodes.

class_name SaveComponent
extends Component


#region Parameters

## Unique identifier for this entity in the save system.
## Used to store information in [member GameState.globalData] "saveState"
@export var entityUid: String

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue
		self.set_process(isEnabled)
		self.set_process_input(isEnabled)

## List of property names on the parent [Entity] to persist across saves.
@export var persistProps: Array[String]

## Whether to persist the freeing of an [Entity] in state.
@export var persistFreed: bool = false

#endregion


#region State
var _manager: SavableStateManager
#endregion


#region Signals
#signal didSomethingHappen ## Placeholder
#endregion


#region Dependencies

#var coComponent: Component = coComponents.Component ## Placeholder # WARNING: "Memoization" (caching the reference) may cause bugs if a new component of the same type is later added to the entity.
#
### Returns a list of required component types that this component depends on.
#func getRequiredComponents() -> Array[Script]:
	#return []

#endregion


func _ready() -> void:
	# Apply setters because Godot doesn't on initialization
	self.set_process(isEnabled)
	self.set_process_input(isEnabled)
	
	## Enforce requirements and validation
	assert(entityUid, "No entityUid set for SaveComponent on Entity %s" % parentEntity.name)
	_manager = GameState.get_node_or_null("SavableStateManager")
	assert(_manager != null, "SavableStateManager is required for %s. Add it to GameStateNodes" % name)
	_validateProps()

	## Load data
	await awaitNodeReady(parentEntity)
	_applySavedChanges()


#region Active Persist

## Variant of [method Entity.createNewComponent] for persisting changes.
## Serializes added [Component] into state using [SavableStateManager] which will be loaded on next session.
func createNewComponentPersist(type: Script)  -> Component:
	var newComponent: Component = parentEntity.createNewComponent(type)
	_manager.getEntity(entityUid).recordCreateNewComponent(type)
	return newComponent

# Variant of [method Entity.createNewComponents] for persisting changes.
## Serializes added [Component]s into state using [SavableStateManager] which will be loaded on next session.
func createNewComponentsPersist(componentTypesToCreate: Array[Script]) -> Array[Component]:
	var newComponents: Array[Component] = parentEntity.createNewComponents(componentTypesToCreate)
	for newComponentType in componentTypesToCreate:
		_manager.getEntity(entityUid).recordCreateNewComponent(newComponentType)
	return newComponents


## Variant of [method Entity.removeComponent] for persisting changes.
## Records component removal with [SavableStateManager].
func removeComponentPersist(type: Script) -> bool:
	var removed: bool = parentEntity.removeComponent(type)
	if removed:
		_manager.getEntity(entityUid).recordRemoveComponent(type)
	return removed


## Variant of [method Entity.removeComponents] for persisting changes.
## Records component removals with [SavableStateManager].
func removeComponentsPersist(componentTypes: Array[Script], shouldFree: bool = true) -> int:
	var removalCount: int = 0
	for componentType in componentTypes:
		if parentEntity.removeComponent(componentType, shouldFree):
			removalCount += 1
			_manager.getEntity(entityUid).recordRemoveComponent(componentType)
	return removalCount

## Provides a method for setting new properties on a [Component] and persisting them using [SavableStateManager].
func updateComponentPropertyPersist(type: Script, propertyName: String, propertyValue: Variant)  -> Component:
	var modifiedComponent: Component = parentEntity.getComponent(type)
	if not modifiedComponent:
		Debug.printWarning("Component '%s' does not exist on Entity '%s'" % [type.get_global_name(), entityUid], self)
	
	if not modifiedComponent.get(propertyName):
		Debug.printWarning("Property '%s' does not exist on component '%s'" % [propertyName, modifiedComponent.name], self)
		
	modifiedComponent.set(propertyName, propertyValue)
	_manager.getEntity(entityUid).recordModifyComponent(type, {propertyName: var_to_str(propertyValue)})
	return modifiedComponent

#endregion


#region Passive Persist

## Verifies any prop specified to persist exists on [Entity].
func _validateProps() -> void:
	for prop in persistProps:
		assert(prop in parentEntity, "Invalid persisted prop %s in Entity %s" % [prop, parentEntity.name])

## Records persisted prop values with [SavableStateManager].
## Iterates through [member persistProps] and saves each property's current value.
func _savePersistProps() -> void:
	if not _isSaveSystemValid():
		return
	
	for prop in persistProps:
		if not parentEntity.get(prop):
			Debug.printWarning("Property '%s' does not exist on entity '%s', skipping" % [prop, parentEntity.name], self)
			continue

		_manager.getEntity(entityUid).recordProp(prop, parentEntity.get(prop))


## Check if the [Entity] being freed should be persisted and record the removal.
func _exit_tree() -> void:
	if not persistFreed:
		return
	
	if not _isSaveSystemValid():
		return
	
	_manager.getEntity(entityUid).recordRemoved()
	
## Called for passive persist to save current data using [SavableStateManager]
func save() -> void:
	if not _isSaveSystemValid():
		return
	_savePersistProps()
#endregion

## Method for applying changes stored in [member GameState.globalData.saveState]
func _applySavedChanges() -> void:
	if not _manager.checkEntityExists(entityUid):
		return
	
	
	var saveData: Dictionary = _manager.getEntity(entityUid).getData()
	
	if("removed" in saveData and saveData["removed"]):
		parentEntity.queue_free()
		return
	
	if "componentChanges" in saveData:
		for component: String in saveData["componentChanges"].keys():
			var change: Dictionary = saveData["componentChanges"][component]
			if change["action"] == "add" or change["action"] == "edit":
				var newComponent: Script = getScriptFromString(component)
				if not parentEntity.hasComponent(newComponent):
					parentEntity.createNewComponent(getScriptFromString(component))
			if change["action"] == "edit":
				var modifiedComponent: Component = parentEntity.getComponent(getScriptFromString(component))
				for propertyName: String in change["properties"]:
					modifiedComponent.set(propertyName, str_to_var(change["properties"][propertyName]))
					
	
	if "propertyChanges" in saveData:
		for propName: String in saveData["propertyChanges"].keys():
			if(parentEntity.get(propName)):
				parentEntity.set(propName, str_to_var(saveData["propertyChanges"][propName]))

## Verifies the [Entity] and [SavableStateManager] exist.
func _isSaveSystemValid() -> bool:
	if not _manager:
		Debug.printError("SavableStateManager not available for saving properties", self)
		return false
	
	if not parentEntity:
		Debug.printError("Parent entity not available for saving properties", self)
		return false
	
	return true

#region Util

## Waits for a [Node] to be ready, handling cases where it's not yet in the tree.
static func awaitNodeReady(n: Node) -> void:
	if n == null:
		return
	if n.is_node_ready():
		return
	if not n.is_inside_tree():
		await n.tree_entered
	await n.ready


## Returns a [Script] resource from a class name string.
static func getScriptFromString(className: String) -> Script:
	var classes := ProjectSettings.get_global_class_list()
	for cls in classes:
		if cls.has("class") and cls["class"] == className:
			if cls.has("path"):
				return load(cls["path"])
	return null

#endregion
