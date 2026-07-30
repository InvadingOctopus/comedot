## A subclass of [Spawner] that spawns copies of different scenes in succession from a given list,
## to generate enemy waves etc.
## TIP: To spawn from a "stack" where each scene is removed on spawn, use [SpawnerStack]
## TIP: To choose a random scene from a set of "weighted" options, use [SpawnerRandom]
## TIP: To use with a [SpawnPoint] or [SpawnArea] etc., enable "Editable Children" and replace the [Spawner] script with this script.

@warning_ignore("missing_tool")
class_name SpawnerList extends SpawnerSequenceBase


#region Parameters
## A list of scene paths to spawn copies of, in sequential order.
# in SpawnerSequenceBase: @export_file("*.tscn") var scenesList: Array[String]
#endregion


#region State
## The index in [member scenesList] that will be used by the next [method spawn] call.
## Incremented after successful spawns and wraps around to 0 after the last index.
@export_storage var currentSceneIndex: int:
	set(newValue):
		if newValue != currentSceneIndex:
			if debugMode: Debug.printChange("currentSceneIndex", currentSceneIndex, newValue, true) # logAsTrace
			currentSceneIndex = newValue
#endregion


## Validates [member scenesList] and [member currentSceneIndex] before a scene is selected.
func validateList(printWarnings: bool = self.debugMode) -> bool:
	if not super.validateList(printWarnings): return false

	if currentSceneIndex < 0 or currentSceneIndex >= scenesList.size(): # Last valid index is size-1
		if printWarnings: Debug.printWarning(str("validateList(): currentSceneIndex is out of bounds: ", currentSceneIndex, " in list size: ", scenesList.size()), self)
		return false

	return true


## "Injects" the scene at [member currentSceneIndex] into [member sceneToSpawn]
func setupSpawn() -> bool:
	# `isEnabled` checked by Spawner.spawn()
	if not validateList(true): return false # printWarnings

	# Pluck the next scene from the list
	sceneToSpawn = scenesList[currentSceneIndex]
	if debugMode: Debug.printDebug(str("setupSpawn() currentSceneIndex ", currentSceneIndex, ": ", sceneToSpawn), self)

	# NOTE: Do NOT increment the index if the spawn wasn't successful, to prevent indexes from being "eaten up"
	# Increment in onDidSpawn()
	
	return true


func onDidSpawn(newSpawn: Node2D, _parent: Node) -> void:
	# Increment the index only if the spawn was successful
	# DESIGN: This ensures that waves like "normal monster → normal → normal → super monster" are preserved and spawned in order.
	if not is_instance_valid(newSpawn): return
	# DESIGN: `currentSceneIndex` may have been modified by signal handlers or other hooks,
	# but that's fine and allows for complex game-specific "hacks"

	# Are we already empty?
	if scenesList.is_empty():
		sceneToSpawn = "" # Avoid stale paths from confusing later validation
		return

	currentSceneIndex = wrapi(currentSceneIndex + 1, 0, scenesList.size())

