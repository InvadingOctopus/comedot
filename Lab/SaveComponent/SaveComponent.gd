## Handles saving and loading of component state for an [Entity].
## Records component additions, removals, and modifications to persist across game sessions.
## Requirements: [SavableStateManager] must be added to GameState nodes.

class_name SaveComponent
extends Component


#region Parameters

## Unique identifier for this entity in the save system.
@export var entityUid: String

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue
		# PERFORMANCE: Set once instead of every frame
		self.set_process(isEnabled)
		self.set_process_input(isEnabled)

## List of property names on the parent [Entity] to persist across saves.
@export var persistProps: Array[String]

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
	# Placeholder: Add any code needed to configure and prepare the component.
	assert(entityUid, "No entityUid set for SaveComponent on Entity %s" % parentEntity.name)
	_manager = GameState.get_node_or_null("SavableStateManager")
	assert(_manager != null, "SavableStateManager is required for %s. Add it to GameStateNodes" % name)
	_validateProps()
	await awaitNodeReady(parentEntity)
	_applySavedChanges()


#region Active Persist Methods

## Variant of [method Entity.createNewComponent] for persisting changes.
## Serializes added [Component] into [SavableState] which will be loaded on next session.
func createNewComponentPersist(type: Script)  -> Component:
	var newComponent: Component = parentEntity.createNewComponent(type)
	_manager.getEntity(entityUid).recordCreateNewComponent(type)
	return newComponent

func createNewComponentsPersist(componentTypesToCreate: Array[Script]) -> Array[Component]:
	var newComponents: Array[Component] = parentEntity.createNewComponents(componentTypesToCreate)
	for newComponentType in componentTypesToCreate:
		_manager.getEntity(entityUid).recordCreateNewComponent(newComponentType)
	return newComponents


## Variant of [method Entity.removeComponent] for persisting changes.
## Records component removal in [SavableState].
func removeComponentPersist(type: Script) -> bool:
	var removed: bool = parentEntity.removeComponent(type)
	if removed:
		_manager.getEntity(entityUid).recordRemoveComponent(type)
	return removed


## Variant of [method Entity.removeComponents] for persisting changes.
## Records component removals in [SavableState].
func removeComponentsPersist(componentTypes: Array[Script], shouldFree: bool = true) -> int:
	var removalCount: int = 0
	for componentType in componentTypes:
		if parentEntity.removeComponent(componentType, shouldFree):
			removalCount += 1
			_manager.getEntity(entityUid).recordRemoveComponent(componentType)
	return removalCount

#endregion


#region Passive Persist Methods

func _validateProps() -> void:
	for prop in persistProps:
		assert(prop in parentEntity, "Invalid persisted prop %s in Entity %s" % [prop, parentEntity.name])

## Records persisted prop values in [SavableState].
## Iterates through [member persistProps] and saves each property's current value.
func _savePersistProps() -> void:
	if not _isSaveSystemValid():
		return
	
	for prop in persistProps:
		if not parentEntity.has(prop):
			Debug.printWarning("Property '%s' does not exist on entity '%s', skipping" % [prop, parentEntity.name], self)
			continue

		_manager.getEntity(entityUid).recordProp(prop, parentEntity.get(prop))


#endregion


func _applySavedChanges() -> void:
	if not _manager.checkEntityExists(entityUid):
		return
	
	var saveData: Dictionary = _manager.getEntity(entityUid).getData()
	if "componentChanges" in saveData:
		for component: String in saveData["componentChanges"].keys():
			var change: Dictionary = saveData["componentChanges"][component]
			if change["action"] == "add":
				parentEntity.createNewComponent(getScriptFromString(component))

func _isSaveSystemValid() -> bool:
	if not _manager:
		Debug.printError("SavableStateManager not available for saving properties", self)
		return false
	
	if not parentEntity:
		Debug.printError("Parent entity not available for saving properties", self)
		return false
	
	return true

#region Util

## Waits for a node to be ready, handling cases where it's not yet in the tree.
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
