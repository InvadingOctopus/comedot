## Creates bindings for values from the shared [member GameState.globalData] key-value store to the properties of this or any other [Node]s.
## NOTE: Automatically updates properties when [signal GlobalData.didChangeValue] is emitted for the mapped keys.
## Erasing a key leaves its last applied property value unchanged.

class_name ApplyGlobalData
extends Node

# DESIGN: This is a workaround for Godot's lack of a way to use global variable names in the Inspector Dock UI:
# e.g. writing "#playerColor" in the [member CanvasItem.modulate] color field, and having it be dynamically updated etc.
# Hopefully this feature will be added in a future Godot version or fork :')

# TBD: @tool?


#region Parameters

## A [Dictionary] of "bindings" where the keys are [StringName]s matching the keys of the [member GameState.globalData] [member GlobalData.dictionary]
## and the values are [NodePath]s pointing to properties of other [Node]s in the same scene.
## NOTE: The paths must be relative to this node and must include properties to modify.
## EXAMPLE: `&"monsterColor": ^"../Monster:modulate"`
## NOTE: Keys missing from [member GameState.globalData] are skipped until they are added via [method GlobalData.setValue]
## NOTE: If no Node is specified in the path, only a ":property" then this Node itself is used.
@export var globalDataBindings: Dictionary[StringName, NodePath]

@export var debugMode: bool

#endregion


#region Life Cycle

func _enter_tree() -> void:
	if not GameState.globalData.didChangeValue.is_connected(self.onGlobalData_didChangeValue):
		GameState.globalData.didChangeValue.connect(self.onGlobalData_didChangeValue)

	# `_ready()` only runs once unless requested again, so reapply here if this node reenters the SceneTree
	if self.is_node_ready(): self.applyAllKeys.call_deferred()


func _ready() -> void:
	# NOTE: call_deferred() to apply after every other node is _ready()
	# so the scripts of target nodes cannot overwrite the initial values applied by this script during scene setup.
	self.applyAllKeys.call_deferred()


func onGlobalData_didChangeValue(key: StringName, _previousValue: Variant, _newValue: Variant) -> void:
	if self.globalDataBindings.has(key): self.applyKey(key)


func _exit_tree() -> void:
	if  GameState.globalData.didChangeValue.is_connected(self.onGlobalData_didChangeValue):
		GameState.globalData.didChangeValue.disconnect(self.onGlobalData_didChangeValue)

#endregion


#region Set Properties

## Attempts to apply every key from [member globalDataBindings]
func applyAllKeys() -> void:
	for key: StringName in self.globalDataBindings:
		self.applyKey(key)


## Calls [method applyGlobalDataToProperty] for the [param key] and associated [NodePath] in [member globalDataBindings]
func applyKey(key: StringName) -> bool:
	if self.globalDataBindings.has(key):
		return self.applyGlobalDataToProperty(key, self.globalDataBindings[key]) # StringName, NodePath
	else:
		if debugMode: Debug.printWarning("applyKey(): globalDataBindings missing key: " + key, self)
		return false


## Applies the value for [param key] from [member GameState.globalData.dictionary] to the [Node] property [NodePath] associated with the same key in this script's [member globalDataBindings]
## if the target node path can be resolved.
## Skips keys that are missing from [member GameState.globalData.dictionary]
## Returns `true` if the target already contains the new value or the value was assigned.
## NOTE: Destination property setters and other factors may prevent the value from being applied.
func applyGlobalDataToProperty(key: StringName, path: NodePath) -> bool:
	if not GameState.globalData.dictionary.has(key):
		if debugMode: Debug.printWarning("applyGlobalDataToProperty(): GameState.globalData.dictionary missing key: " + key, self)
		return false

	# Split the path into Node:Property
	var nodeAndPropertyPaths: Array[NodePath] = Tools.splitPathIntoNodeAndProperty(path)
	var targetNodePath:		NodePath = nodeAndPropertyPaths[0]
	var targetPropertyPath:	NodePath = nodeAndPropertyPaths[1]

	# Validate
	# TBD: Warnings or Errors?

	# Make sure the path includes a ":property"
	if targetPropertyPath.is_empty():
		Debug.printWarning(str("applyGlobalDataToProperty(): NodePath for key \"", key, "\" does not include a property: ", path), self)
		return false

	# Make sure the Node exists
	var targetNode: Node = self if targetNodePath.is_empty() else self.get_node_or_null(targetNodePath)
	if not is_instance_valid(targetNode):
		Debug.printWarning(str("applyGlobalDataToProperty(): Cannot find target Node for key \"", key, "\" with path: ", path), self)
		return false

	# Make sure the target Node has a property with that name
	var targetPropertyName: StringName = targetPropertyPath.get_subname(0)
	if  targetPropertyName not in targetNode:
		Debug.printWarning(str("applyGlobalDataToProperty(): Target Node: ", targetNode, " does not have property \"", targetPropertyName, "\" for key \"", key, "\" with path: ", path), self)
		return false

	# Just return if the values are the same
	var existingValue:	Variant = targetNode.get_indexed(targetPropertyPath)
	var newValue:		Variant = GameState.globalData.dictionary.get(key)
	if is_same(existingValue, newValue): return true

	# Attempt to set the property; NOTE: custom setters may reject or modify the attempt.
	if debugMode: Debug.printChange(str(targetNode, targetPropertyPath), existingValue, newValue)
	targetNode.set_indexed(targetPropertyPath, newValue)
	return true

#endregion
