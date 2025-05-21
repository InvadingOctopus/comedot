## Replaces a node with 1 other node randomly chosen from the provided list.
## May be used for loading different variations for monsters, maps, etc.
## TIP: For lazily-loaded [InstancePlaceholder]s, see [RandomPlaceholder].gd
## NOTE: The replacement occurs during [method Node._enter_tree] BEFORE [method Node._ready] so that the replacement can be available for any other nodes/scripts which may depend on it.

class_name ReplaceWithRandomScene
extends Node2D

# TODO: TBD: Add a delay Timer?


#region Parameters
## A [Dictionary] of Scene paths associated with a percentage chance.
## Each entry is "rolled" in order. If the chance succeeds, the node this script is attached to will be replaced by an instance of that random scene.
@export var scenes: Dictionary[String, int]

## The scene to load if none of the [member scenes] were chosen by random chance.
@export var fallbackScenePath: String

@export var debugMode: bool = false
#endregion


#region Signals
signal didReplaceWithScene(path: String, instance: CanvasItem)
#endregion



# NOTE: Replace during `_enter_tree()` BEFORE `_ready()` so that the replacement can be available for any other nodes/scripts which may depend on it.
func _enter_tree() -> void:
	replaceWithRandomScene()


#region Interface

func getRandomPath() -> String:
	if scenes.is_empty(): 
		if debugMode: Debug.printDebug("getRandomPath(): No scenes, returning: " + fallbackScenePath, self)
		return fallbackScenePath if not fallbackScenePath.is_empty() else ""

	var chance: int # Create once outside loop
	for path in scenes:
		chance = scenes[path]
		if chance == 100 or (chance != 0 and randi_range(1, 100) <= chance): # i.e. if the chance is 10%, then any number from 1-10 should succeed.
			if debugMode: Debug.printDebug(str("getRandomPath(): ", chance, "%% ", path), self)
			return path

	# If no scene was rolled, use the fallback
	if debugMode: Debug.printDebug("getRandomPath(): No scenes succeeded their chance, returning: " + fallbackScenePath, self)
	return fallbackScenePath if not fallbackScenePath.is_empty() else ""


func replaceWithRandomScene(pathOverride: String = "") -> CanvasItem:
	var path: String = pathOverride if not pathOverride.is_empty() else self.getRandomPath()
	if debugMode: Debug.printDebug("replaceWithRandomScene(): " + path, self)
	
	var scene: PackedScene = load(path)
	if not scene:
		Debug.printWarning("replaceWithRandomScene() cannot load: " + path, self)
		return null

	var sceneInstance := scene.instantiate()
	if not is_instance_valid(sceneInstance):
		Debug.printWarning("replaceWithRandomScene() cannot instantiate: " + path, self)
		return null
	
	Tools.replaceChild.call_deferred(self.get_parent(), self, sceneInstance, true, true, true, true) # copyPosition, copyRotation, copyScale, freeReplacedChild
	# DEBUG: else: Debug.printWarning(str("replaceWithRandomScene() could not replace: " , self, " with ", sceneInstance))

	self.didReplaceWithScene.emit(path, sceneInstance)
	return sceneInstance

#endregion
