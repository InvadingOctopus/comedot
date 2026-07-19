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
## Incremented after successful spawns and wraps around to 0 after the last index.
@export_storage var currentSceneIndex: int:
	set(newValue):
		if newValue != currentSceneIndex:
			if debugMode: Debug.printChange("currentSceneIndex", currentSceneIndex, newValue, true) # logAsTrace
			currentSceneIndex = newValue
#endregion


## Overrides [method Spawner.spawn] to "inject" the scene at [member currentSceneIndex] into [member sceneToSpawn]
## then calls `super.spawn()` and increments the index if successful.
func spawn() -> Node2D:
	if not isEnabled or not validateSceneToSpawn(true): return null # printWarnings

	# Pluck the next scene from the list
	var sceneIndexToSpawn: int = currentSceneIndex
	self.sceneToSpawn = self.scenesList[currentSceneIndex]

	if sceneToSpawn.is_empty():
		Debug.printWarning(str("spawn(): Empty path at index ", sceneIndexToSpawn), self)
		return null

	# Ask the Spawner superclass to spawn
	var newSpawn: Node2D = super.spawn()

	# Advance the index
	# NOTE: Do NOT advance the index if the spawn wasn't successful, to prevent indexes from being "eaten up" .
	# DESIGN: This ensures that waves like "normal monster → normal → normal → super monster" are preserved and spawned in order.
	if newSpawn != null:
		self.currentSceneIndex = wrapi(sceneIndexToSpawn + 1, 0, scenesList.size()) # Calculate from `sceneIndexToSpawn` because `currentSceneIndex` may be mutated
 
	return newSpawn


## Validates [member scenesList] and [member currentSceneIndex] before a scene is selected.
func validateSceneToSpawn(printWarnings: bool = self.debugMode) -> bool:
	if scenesList.is_empty():
		if printWarnings: Debug.printWarning("validateSceneToSpawn(): scenesList is empty", self)
		return false

	if currentSceneIndex < 0 or currentSceneIndex >= scenesList.size(): # Last valid index is size-1
		if printWarnings: Debug.printWarning(str("validateSceneToSpawn(): currentSceneIndex is out of bounds: ", currentSceneIndex, " in list size: ", scenesList.size()), self)
		return false

	return true
