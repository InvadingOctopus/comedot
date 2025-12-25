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


func resetSaveState() -> void:
	_saveState = {
		"entities": {}
	}


func saveStateAsJson(filepath: String) -> bool:
	var saveFile := FileAccess.open(filepath, FileAccess.WRITE)
	if not saveFile:
		Debug.printError("Cannot open file for writing: " + filepath, self)
		return false
	
	var jsonString := JSON.stringify(_saveState)
	saveFile.store_line(jsonString)
	saveFile.close()
	return true


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


func checkEntityExists(uid: String) -> bool:
	return hasNestedKey(["entities", uid])


func getEntity(uid: String) -> GameStateEntity:
	return GameStateEntity.new(uid, self)


func getSaveState() -> Dictionary:
	return _saveState


#region GameStateEntity

## Wrapper class for handling nuances of storing data about an [Entity].
## Handles initialization and formatting of entity save data.

class GameStateEntity:
	var _uid: String
	var _manager: SavableStateManager
	var _exists: bool = false

	func _init(uid: String, manager: SavableStateManager) -> void:
		_uid = uid
		_manager = manager
		_exists = _manager.checkEntityExists(uid)
	
	
	## Initializes the [Entity] boilerplate in [GameState] to record further changes.
	## Currently triggered on modification to avoid adding an empty entry.
	func _initialize() -> void:
		if _exists:
			return
		
		_manager.setNestedKey(["entities", _uid], {
			"componentChanges": {},
			"removed": false
		})
		_exists = true

	
	## Helper function for handling updates to state.
	## Can only run if the component does not exist or is set to be removed.
	## Will do nothing if component already queued to be added or edited.
	func recordCreateNewComponent(type: Script) -> void:
		_initialize()
		var componentName: String = type.get_global_name() as String
		var currentComponent: Variant = _manager.getNestedKey(["entities", _uid, "componentChanges", componentName])
		if not currentComponent or currentComponent["action"] == "delete":
			_manager.setNestedKey(["entities", _uid, "componentChanges", componentName], {"action": "add", "properties": {}})
		else:
			Debug.printError("recordCreateNewComponent(): Component already exists", self)
	
	
	## For modifying components that already exist.
	func recordModifyComponent(type: Script, newProperties: Dictionary) -> void:
		_initialize()
		var componentName: String = type.get_global_name() as String
		var currentComponent: Variant = _manager.getNestedKey(["entities", _uid, "componentChanges", componentName])
		if currentComponent and currentComponent["action"] == "remove":
			Debug.printError("recordModifyComponent(): Component has been removed", self)
		elif currentComponent and currentComponent["properties"]:
			_manager.setNestedKey(
				['entities', _uid, 'componentChanges', componentName, 'properties'],
				currentComponent['properties'].merged(newProperties, true)
			)
		else:
			_manager.setNestedKey(
				["entities", _uid, "componentChanges", componentName],
				{"action": "edit", "properties": newProperties}
			)
	
	
	## Removes the component (and clears any previous saved modifications).
	func recordRemoveComponent(type: Script) -> void:
		_initialize()
		var componentName: String = type.get_global_name() as String
		_manager.setNestedKey(
			["entities", _uid, "componentChanges", componentName],
			{"action": "remove"}
		)
	
	
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
