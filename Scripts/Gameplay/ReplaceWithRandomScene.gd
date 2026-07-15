## Replaces a node with 1 other node randomly chosen from the provided [Dictionary].
## May be used for loading different variations for monsters, maps, etc.
## TIP: For lazily-loaded [InstancePlaceholder]s, see [RandomPlaceholder].gd
## NOTE: [method replaceWithRandomScene] is called from [method Node._enter_tree]
## but is called with [method Object.call_deferred] so the replacement may NOT be available before other nodes/scripts are `_ready()`
## TIP: so dependent scripts must use [signal didReplaceWithScene]

class_name ReplaceWithRandomScene
extends Node2D

# TODO: TBD: Add a delay Timer?


#region Parameters

## A [Dictionary] of scene paths and their relative "weights".
## EXAMPLE: `{ "res://Common.tscn": 3.0, "res://Rare.tscn": 1.0 }` = 75% chance for Common, 25% for Rare
## NOTE: Entries with weights <= 0 are ignored.
@export var scenes: Dictionary[String, float]

## The scene to load if [member scenes] is empty or has no positive weights.
@export var fallbackScenePath: String

@export var debugMode: bool

#endregion


#region Signals
signal didReplaceWithScene(path: String, instance: CanvasItem)
#endregion


# NOTE: Replace during `_enter_tree()` so that the replacement can be available as soon as possible.
func _enter_tree() -> void:
	# NOTE: call_deferred() to avoid the Godot error about replacing a child while its parent is still setting up the scene tree.
	replaceWithRandomScene.call_deferred()


#region Interface

## Calls [method Tools.pickRandomFromWeightsDictionary] to return a random scene from [member scenes]
## NOTE: Perform necessary validation before "consuming"  the [member GameState.randomNumberGenerator] roll.
func getRandomPath() -> String:
	if scenes.is_empty():
		if debugMode: Debug.printDebug("getRandomPath(): scenes empty, returning fallbackScenePath: " + fallbackScenePath, self)
		return fallbackScenePath if not fallbackScenePath.is_empty() else ""

	var path: String = Tools.pickRandomFromWeightsDictionary(scenes, fallbackScenePath) as String
	if debugMode: Debug.printDebug(str("getRandomPath(): ", path), self)
	return path


func replaceWithRandomScene(pathOverride: String = "") -> CanvasItem:

	# Parent check
	var parent: Node = self.get_parent()

	if not is_instance_valid(parent) or parent.is_queued_for_deletion() \
	or self.is_queued_for_deletion():
		if debugMode: Debug.printDebug("replaceWithRandomScene(): Placeholder parent is invalid or queued for deletion", self)
		return null

	# Path check
	# NOTE: "Consume" the `GameState.randomNumberGenerator` roll after performing other checks
	var path: String = pathOverride if not pathOverride.is_empty() else self.getRandomPath()
	
	if  path.is_empty():
		Debug.printWarning("replaceWithRandomScene(): path empty", self)
		return null

	if debugMode: Debug.printDebug("replaceWithRandomScene(): " + path, self)

	# Scene check
	var scene: PackedScene = load(path)
	if not scene:
		Debug.printWarning("replaceWithRandomScene() cannot load: " + path, self)
		return null

	var sceneInstance := scene.instantiate()
	if not is_instance_valid(sceneInstance):
		Debug.printWarning("replaceWithRandomScene() cannot instantiate: " + path, self)
		return null
	
	if sceneInstance is not CanvasItem:
		Debug.printWarning(str("replaceWithRandomScene() sceneInstance is not a CanvasItem: ", sceneInstance), self)
		sceneInstance.queue_free()
		return null

	# Replace
	var didReplace: bool = NodeTools.replaceChild(parent, self, sceneInstance, true, true, true, true, true) # copyPosition, copyRotation, copyScale, copyTransform, freeReplacedChild
	if  didReplace:
		self.didReplaceWithScene.emit(path, sceneInstance)
		return sceneInstance
	else:
		Debug.printWarning(str("replaceWithRandomScene() → replaceChild() could not replace: " , self, " with ", sceneInstance))
		sceneInstance.queue_free()
		return null

#endregion
