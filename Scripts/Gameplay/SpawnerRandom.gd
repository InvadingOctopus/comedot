## A subclass of [Spawner] that spawns a random scene from a "weighted" [Dictionary] on each [method spawn] call.
## TIP: To use a non-random sequential list of scenes, use [SpawnerList]
## TIP: To use with a [SpawnPoint] or [SpawnArea] etc., enable "Editable Children" and replace the [Spawner] script with this script.

class_name SpawnerRandom
extends Spawner


#region Parameters

## A [Dictionary] of scene paths and their "relative weights" used to randomly pick which scene to spawn.
## EXAMPLE: `{ "res://Common.tscn": 3.0, "res://Rare.tscn": 1.0 }` = 75% chance for Common, 25% for Rare
## NOTE: Entries with weights <= 0 are ignored.
## IMPORTANT: [member spawnChance] is rolled BEFORE this list is used; if the roll doesn't succeed, then NO scene is spawned.
@export var scenes: Dictionary[String, float]

## The chance percent rolled on every [method spawn] call BEFORE a scene is randomly chosen from [member scenes]
@export_range(0, 100, 1, "suffix:%") var spawnChance: int = 100 # TBD: Should this be a float 0.0 to 1.0? or will that cause float comparison effery?

#endregion


## Overrides [method Spawner.spawn] to check [member spawnChance] then pick a random scene from [member scenes]
## The random scene path is "injected" into [member sceneToSpawn] before calling `super.spawn()`
func spawn() -> Node2D:
	if not isEnabled: return null # validateSceneToSpawn() will be checked by `super.spawn()`

	if scenes.is_empty():
		Debug.printWarning("spawn(): `scenes` is empty", self)
		return null

	# Before choosing a random scene, roll to see if we should spawn anything at all or not
	if spawnChance >= 100 \
	or GameState.randomNumberGenerator.randi_range(1, 100) <= spawnChance: # i.e. if the chance is 10%, then any number from 1-10 should succeed. If 0 then never succeed.
		# Success
		if debugMode: Debug.printDebug(str("spawn(): roll <= spawnChance: ", spawnChance), self)
	else:
		return null

	# Choose a random scene
	var randomScenePath: String = Tools.pickRandomFromWeightsDictionary(scenes, "") as String
	if  randomScenePath.is_empty(): # Validate `randomScenePath` here because validateSceneToSpawn() doesn't
		if debugMode: Debug.printWarning("spawn(): Tools.pickRandomFromWeightsDictionary() did not return a non-empty path from `scenes`", self)
		return null

	self.sceneToSpawn = randomScenePath
	return super.spawn()


func validateSceneToSpawn(printWarnings: bool = self.debugMode) -> bool:
	# Don't call `super` because it's okay if `sceneToSpawn` is empty.
	# Log warnings only on `debugMode` to avoid noise if a caller is just checking
	if scenes.is_empty():
		if printWarnings: Debug.printWarning("validateSceneToSpawn(): `scenes` is empty", self)
		return false
	# TBD: PERFORMANCE: Check for a non-empty Dictionary with all empty paths or 0 weights? To avoid consuming GameState.randomNumberGenerator rolls..
	return true
