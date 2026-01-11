## Autoload
## Manages save state for entities and their components.
## Stores data in [member GameState.globalData] under the "saveState" key.

class_name SavableStateManager
extends Node


#region State

## For accessing a namespace in [member GameState.globalData] to store save data.
var _saveState: Dictionary[Variant, Variant]:
	get:
		return GameState.globalData["saveState"]
	set(value):
		GameState.globalData["saveState"] = value

#endregion


func _ready() -> void:
	## Initializes the [_saveState] in [member GameState.globalData] if it does not already exist.
	if not GameState.globalData.has("saveState"):
		resetSaveState()


## Resets the save state to an empty dictionary with an "entities" key.
## This clears all saved entity data from [member GameState.globalData].
func resetSaveState() -> void:
	_saveState = {
		"entities": {}
	}


## Saves the current [_saveState] to a JSON file at the specified [param filepath].
## Returns `true` if the save was successful, `false` otherwise.
## Logs an error if the file cannot be opened for writing.
func saveStateAsJson(filepath: String) -> bool:
	var saveFile := FileAccess.open(filepath, FileAccess.WRITE)
	if not saveFile:
		Debug.printError("Cannot open file for writing: " + filepath, self)
		return false
	
	var jsonString := JSON.stringify(_saveState)
	saveFile.store_line(jsonString)
	saveFile.close()
	return true


## Loads save state from a JSON file at the specified [param filepath].
## Parses the JSON and replaces the current [_saveState] with the loaded data.
## Returns `true` if the load was successful, `false` otherwise.
## Logs warnings if the file doesn't exist, and errors if the file cannot be read or parsed.
func loadStateFromFile(filepath: String) -> bool:
	if not FileAccess.file_exists(filepath):
		Debug.printWarning("Save file does not exist: " + filepath, self)
		return false
	
	var saveFile := FileAccess.open(filepath, FileAccess.READ)
	if not saveFile:
		Debug.printError("Cannot open file for reading: " + filepath, self)
		return false
	
	var saveText: String = saveFile.get_as_text()
	saveFile.close()
	
	# Creates the helper class to interact with JSON.
	var json := JSON.new()
	var parseResult: Variant = json.parse(saveText)
	
	if not parseResult == OK:
		Debug.printError("JSON Parse Error: " + json.get_error_message() + " in " + saveText + " at line " + str(json.get_error_line()), self)
		return false
	
	_saveState = json.data
	return true


## Checks if an entity with the given [param uid] exists in the save state.
func checkEntityExists(uid: String) -> bool:
	return hasNestedKey(["entities", uid])


## Creates and returns a [GameStateEntity] wrapper for the entity with the given [param uid].
## The wrapper provides methods to record changes to the entity's properties and components.
## The entity does not need to exist in the save state yet; it will be initialized on first modification.
func getEntity(uid: String) -> GameStateEntity:
	return GameStateEntity.new(uid, self)


## Returns the current save state dictionary.
## This contains all saved entity data under the "entities" key.
func getSaveState() -> Dictionary:
	return _saveState


#region GameStateEntity

## Wrapper class for handling nuances of storing data about an [Entity].
## Handles initialization and formatting of entity save data.

class GameStateEntity:
	## The unique identifier of the entity this wrapper represents.
	var _uid: String
	## Reference to the [SavableStateManager] that owns this entity's save data.
	var _manager: SavableStateManager
	## Whether this entity already exists or needs initialized
	var _exists: bool = false

	## Constructor requires a unique id and reference to the manager
	## Checks if the entity already exists in the save state and stores the result in [_exists].
	func _init(uid: String, manager: SavableStateManager) -> void:
		_uid = uid
		_manager = manager
		_exists = _manager.checkEntityExists(uid)
	
	
	## Initializes the [Entity] boilerplate in [GameState] to record further changes.
	## Currently triggered on modification to avoid adding an empty entry.
	func _initializeEntityInState() -> void:
		if _exists:
			return
		
		_manager.setNestedKey(["entities", _uid], {
			"propertyChanges": {},
			"componentChanges": {},
			"removed": false
		})
		_exists = true

	##region Component methods
	
	## Records that a new component should be created for this entity.
	## [param type] is the component's script class.
	## Can only run if the component does not exist or is set to be removed.
	## Will log an error if the component is already queued to be added or edited.
	func recordCreateNewComponent(type: Script) -> void:
		_initializeEntityInState()
		var componentName: String = type.get_global_name() as String
		var currentComponent: Variant = _manager.getNestedKey(["entities", _uid, "componentChanges", componentName])
		if not currentComponent or currentComponent["action"] == "delete":
			_manager.setNestedKey(["entities", _uid, "componentChanges", componentName], {"action": "add", "properties": {}})
		else:
			Debug.printError("recordCreateNewComponent(): Component already exists", self)
	
	
	## Records modifications to an existing component for this entity.
	## [param type] is the component's script class.
	## [param newProperties] is a dictionary of property names with new values.
	## Merges with existing property changes if the component was already being edited.
	## Logs an error if the component has been marked for removal.
	func recordModifyComponent(type: Script, newProperties: Dictionary) -> void:
		_initializeEntityInState()
		var componentName: String = type.get_global_name() as String
		var currentComponent: Variant = _manager.getNestedKey(["entities", _uid, "componentChanges", componentName])
		if currentComponent and currentComponent["action"] == "remove":
			Debug.printError("recordModifyComponent(): Component has been removed", self)
			return
		
		var serializedProps: Dictionary ={}
		for prop: String in newProperties:
			serializedProps[prop] = var_to_str(newProperties[prop])
			
		if currentComponent and currentComponent["properties"]:
			_manager.setNestedKey(
				['entities', _uid, 'componentChanges', componentName, 'properties'],
				currentComponent['properties'].merged(serializedProps, true)
			)
		else:
			_manager.setNestedKey(
				["entities", _uid, "componentChanges", componentName],
				{"action": "edit", "properties": serializedProps}
			)
	
	
	## Records that a component should be removed from this entity.
	## [param type] is the component's script class.
	## This clears any previous saved modifications to the component.
	func recordRemoveComponent(type: Script) -> void:
		_initializeEntityInState()
		var componentName: String = type.get_global_name() as String
		_manager.setNestedKey(
			["entities", _uid, "componentChanges", componentName],
			{"action": "remove"}
		)
	#endregion

	#region property methods

	## Records a property change for this entity.
	## [param propName] is the name of the property to save.
	## [param value] is the new value, which is converted to a string using [var_to_str] for serialization.
	func recordProp(propName: String, value: Variant) -> void:
		_initializeEntityInState()
		_manager.setNestedKey(
			["entities", _uid, "propertyChanges", propName],
			var_to_str(value)
		)

	#endregion
	
	## Marks the entity as removed in the save state.
	## This indicates the entity should be deleted when the save state is applied.
	func recordRemoved() -> void:
		_initializeEntityInState()
		_manager.setNestedKey(
			["entities", _uid, "removed"],
			true
		)

	
	
	## Returns the entity's save data dictionary from the save state.
	## Returns an empty dictionary if the entity does not exist in the save state.
	func getData() -> Dictionary:
		var payload: Variant = _manager.getNestedKey(["entities", _uid])
		return payload if payload != null else {}

#endregion


#region Util

## Conveniently returns a value from a [Dictionary] without worrying about access errors.
## Returns `null` if the nested [param path] does not exist.
## [param dict] defaults to [member _saveState] to access data in [GameState].
func getNestedKey(path: Array, dict: Dictionary = _saveState) -> Variant:
	var target: Variant = dict
	for key: Variant in path:
		if target is not Dictionary or not target.has(key):
			Debug.printError("getNestedKey: missing key %s in path %s" % [key, path], dict)
			return null
		target = target[key]
	return target


## Conveniently checks if a nested path from a [Dictionary] exists without worrying about access errors.
## [param dict] defaults to [member _saveState] to check data in [GameState].
func hasNestedKey(path: Array, dict: Dictionary = _saveState) -> bool:
	var target: Variant = dict
	for key: Variant in path:
		if target is not Dictionary or not target.has(key):
			return false
		target = target[key]
	return true


## Lazy initialization for a nested value in [Dictionary] without worrying if the [param path] exists.
## Initializes keys from the [param path] with empty objects if they don't already exist.
## [param dict] defaults to [member _saveState] to store data in [GameState].
func setNestedKey(path: Array, value: Variant, dict: Dictionary = _saveState) -> void:
	var target: Variant = dict
	for i in range(path.size() - 1):
		if target is not Dictionary or not target.has(path[i]):
			target[path[i]] = {}
		target = target[path[i]]
	target[path[-1]] = value

#endregion
