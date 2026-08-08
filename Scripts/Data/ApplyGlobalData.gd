## Creates bindings for values from the shared [member GameState.globalData] key-value store to the properties of this or any other [Node]s.
## NOTE: Automatically updates properties when [signal GlobalData.didChangeValue] is emitted for the mapped keys.
## Erasing a key leaves its last applied property value unchanged.

@tool
class_name ApplyGlobalData
extends Node

# DESIGN: This is a workaround for Godot's lack of a way to use global variable names in the Inspector Dock UI:
# e.g. writing "#playerColor" in the [member CanvasItem.modulate] color field, and having it be dynamically updated etc.
# Hopefully this feature will be added in a future Godot version or fork :')


#region Parameters

## Updates bindings in the Godot Editor.
## NOTE: Bindings are NOT updated if a key is erased.
@export_tool_button("Refresh Bindings", "Reload") var applyButton: Callable = applyAllKeys

## A [Dictionary] of "bindings" where the keys are [StringName]s matching the keys of the [member GameState.globalData] [member GlobalData.dictionary]
## and the values are [NodePath]s pointing to properties of other [Node]s in the same scene.
## NOTE: The paths must be relative to this node and must include properties to modify.
## EXAMPLE: `&"monsterColor": ^"../Monster:modulate"`
## NOTE: Keys missing from [member GameState.globalData] are skipped until they are added via [method GlobalData.setValue]
## NOTE: If no Node is specified in the path, only a ":property" then this Node itself is used.
@export var globalDataBindings: Dictionary[StringName, NodePath]

@export var debugMode: bool

#endregion


#region Editor
var editorGlobalData:	GlobalData ## The [GlobalData] instance used in the Godot Editor during development-time, where the runtime-only [GameState] AutoLoad is unavailable.
const debug:			Script = preload("res://AutoLoad/Debug.gd") # To avoid Dumbdot's annoying "static called on instance" warning
#endregion


#region Life Cycle

func _enter_tree() -> void:
	var globalData: GlobalData = loadGlobalData()

	if not globalData.didChangeValue.is_connected(self.onGlobalData_didChangeValue):
		globalData.didChangeValue.connect(self.onGlobalData_didChangeValue)

	# `_ready()` only runs once unless requested again, so reapply here if this node reenters the SceneTree
	if self.is_node_ready(): self.applyAllKeys.call_deferred()


func _ready() -> void:
	# NOTE: call_deferred() to apply after every other node is _ready()
	# so the scripts of target nodes cannot overwrite the initial values applied by this script during scene setup.
	self.applyAllKeys.call_deferred()


## If at runtime, returns [member GameState.globalData] as normal.
## At development-time in the Godot Editor, loads the [GlobalData] configured in [member ComedotProjectSettings.globalDataPath]
## Creates a new empty [GlobalData] on failure.
func loadGlobalData() -> GlobalData:
	# Do we already have a GlobalData?
	if not Engine.is_editor_hint(): return GameState.globalData
	if editorGlobalData: return editorGlobalData

	# If not, load it from the specified path
	var projectSettings: ComedotProjectSettings = ComedotProjectSettings.loadSettingsResource()
	if  projectSettings and not projectSettings.globalDataPath.is_empty():
		editorGlobalData = load(projectSettings.globalDataPath) as GlobalData
		if not editorGlobalData:
			debug.printEditorWarning("loadGlobalData(): Unable to find or load GlobalData Resource at ComedotProjectSettings.globalDataPath: " + projectSettings.globalDataPath, self)

	# If all else fails, just create new store
	if not editorGlobalData: editorGlobalData = GlobalData.new()
	return editorGlobalData


func onGlobalData_didChangeValue(key: StringName, _previousValue: Variant, _newValue: Variant) -> void:
	if self.globalDataBindings.has(key): self.applyKey(key)


func _exit_tree() -> void:
	var globalData: GlobalData = loadGlobalData()
	if  globalData.didChangeValue.is_connected(self.onGlobalData_didChangeValue):
		globalData.didChangeValue.disconnect(self.onGlobalData_didChangeValue)

#endregion


#region Bindings

## Attempts to apply every key from [member globalDataBindings]
func applyAllKeys() -> void:
	for key: StringName in self.globalDataBindings:
		self.applyKey(key)


## Calls [method applyGlobalDataToProperty] for the [param key] and associated [NodePath] in [member globalDataBindings]
func applyKey(key: StringName) -> bool:
	if self.globalDataBindings.has(key):
		return self.applyGlobalDataToProperty(key, self.globalDataBindings[key]) # StringName, NodePath
	else:
		if debugMode: debug.printEditorWarning("applyKey(): globalDataBindings missing key: " + key, self)
		return false


## Applies the value for [param key] from [member GameState.globalData.dictionary] to the [Node] property [NodePath] associated with the same key in this script's [member globalDataBindings]
## if the target node path can be resolved.
## Skips keys that are missing from [member GameState.globalData.dictionary]
## Returns `true` if the target already contains the new value or the value was assigned.
## NOTE: Destination property setters and other factors may prevent the value from being applied.
func applyGlobalDataToProperty(key: StringName, path: NodePath) -> bool:
	var globalData: GlobalData = self.loadGlobalData()

	if not globalData.dictionary.has(key):
		if debugMode: debug.printEditorWarning("applyGlobalDataToProperty(): GameState.globalData.dictionary missing key: " + key, self)
		return false

	# Split the path into Node:Property
	var nodeAndPropertyPaths: Array[NodePath] = Tools.splitPathIntoNodeAndProperty(path)
	var targetNodePath:		NodePath = nodeAndPropertyPaths[0]
	var targetPropertyPath:	NodePath = nodeAndPropertyPaths[1]

	# Validate
	# TBD: Warnings or Errors?

	# Make sure the path includes a ":property"
	if targetPropertyPath.is_empty():
		debug.printEditorWarning(str("applyGlobalDataToProperty(): NodePath for key \"", key, "\" does not include a property: ", path), self)
		return false

	# Make sure the Node exists
	var targetNode: Node = self if targetNodePath.is_empty() else self.get_node_or_null(targetNodePath)
	if not is_instance_valid(targetNode):
		debug.printEditorWarning(str("applyGlobalDataToProperty(): Cannot find target Node for key \"", key, "\" with path: ", path), self)
		return false

	# Make sure the target Node has a property with that name
	var targetPropertyName: StringName = targetPropertyPath.get_subname(0)
	if  targetPropertyName not in targetNode:
		debug.printEditorWarning(str("applyGlobalDataToProperty(): Target Node: ", targetNode, " does not have property \"", targetPropertyName, "\" for key \"", key, "\" with path: ", path), self)
		return false

	# Just return if the values are the same
	var existingValue:	Variant = targetNode.get_indexed(targetPropertyPath)
	var newValue:		Variant = globalData.dictionary.get(key)
	if is_same(existingValue, newValue): return true

	# Attempt to set the property; NOTE: custom setters may reject or modify the attempt.
	if debugMode: debug.printEditorLog(str(targetNode, targetPropertyPath, ": ", existingValue, " → ", newValue))
	targetNode.set_indexed(targetPropertyPath, newValue)
	return true

#endregion
