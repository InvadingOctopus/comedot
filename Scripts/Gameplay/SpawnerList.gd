## A subclass of [Spawner] that spawns copies of different scenes in succession from a given list,
## to generate enemy waves etc.
## TIP: To spawn from a "stack" where each scene is removed on spawn, use [SpawnerStack]
## TIP: To choose a random scene from a set of "weighted" options, use [SpawnerRandom]
## TIP: To use with a [SpawnPoint] or [SpawnArea] etc., enable "Editable Children" and replace the [Spawner] script with this script.

class_name SpawnerList
extends Spawner


#region Parameters
## A list of scene paths to spawn copies of, in sequential order.
@export_file("*.tscn") var scenesList: Array[String]
#endregion


#region State
## The index in [member scenesList] that will be used by the next [method spawn] call.
## Wraps around to 0 after fetching the last index.
@export_storage var currentSceneIndex: int:
	set(newValue):
		if newValue != currentSceneIndex:
			if debugMode: Debug.printChange("currentSceneIndex", currentSceneIndex, newValue, true) # logAsTrace
			currentSceneIndex = newValue
#endregion


## Overrides [method Spawner.spawn] to "inject" the scene at [member currentSceneIndex] into [member sceneToSpawn]
## then increments the index and calls `super.spawn()`
func spawn() -> Node2D:
	if not isEnabled or not validateSceneToSpawn(true): return null # printWarnings

	var sceneIndexToSpawn: int = currentSceneIndex
	self.sceneToSpawn = self.scenesList[currentSceneIndex]
	# DESIGN: Advance the index whether the spawn succeeds or not so the next scene can be attempted.
	self.currentSceneIndex = wrapi(currentSceneIndex + 1, 0, scenesList.size())

	if sceneToSpawn.is_empty():
		Debug.printWarning(str("spawn(): Empty path at index ", sceneIndexToSpawn), self)
		return null

	return super.spawn()


## Validates [member scenesList] and [member currentSceneIndex] before a scene is selected.
func validateSceneToSpawn(printWarnings: bool = self.debugMode) -> bool:
	if scenesList.is_empty():
		if printWarnings: Debug.printWarning("validateSceneToSpawn(): scenesList is empty", self)
		return false

	if currentSceneIndex < 0 or currentSceneIndex >= scenesList.size(): # Last valid index is size-1
		if printWarnings: Debug.printWarning(str("validateSceneToSpawn(): currentSceneIndex is out of bounds: ", currentSceneIndex, " in list size: ", scenesList.size()), self)
		return false

	return true
