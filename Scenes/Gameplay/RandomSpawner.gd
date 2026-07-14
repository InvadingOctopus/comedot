## A subclass of [Spawner] that has a specific chance to spawn any scene from a list of scenes on each [method spawn] call.
## TIP: To use with a [SpawnPoint] or [SpawnArea] etc., enable "Editable Children" and replace the [Spawner] script with this script.

class_name RandomSpawner
extends Spawner

# TODO: A separate chance for each scene
# TODO: Option for a sequential index


#region Parameters

## A list of scene paths that will be randomly chosen from to spawn a copy of. Each scene has an equal chance.
## NOTE: [member spawnChance] must succeed first before any scene is spawned.
@export_file("*.tscn") var randomScenesList: Array[String]

## The chance percent for an instance to be created whenever the Timer counts down.
@export_range(0, 100, 1, "suffix:%") var spawnChance: int = 100 # TBD: Should this be a float 0.0 to 1.0? or will that cause float comparison effery?

#endregion


## Overrides [method Spawner.spawn] to first roll [member spawnChance]
## then if the roll succeeds, a different random scene from [member randomScenesList] is "injected" into [member sceneToSpawn] before calling `super.spawn()`
func spawn() -> Node2D:
	if not isEnabled: return null # validateSceneToSpawn() will be checked after the initial roll

	# Before choosing a random scene, roll to see if we should spawn anything at all or not
	if spawnChance >= 100 \
	or randi_range(1, 100) <= spawnChance: # i.e. if the chance is 10%, then any number from 1-10 should succeed. If chance is 0 then never succeed.
		# Success
		if debugMode: Debug.printDebug(str("spawn(): roll <= spawnChance: ", spawnChance), self)
	else:
		return

	if not validateSceneToSpawn(true): return null # printWarnings

	# Choose a random scene
	self.sceneToSpawn = self.randomScenesList.pick_random()
	return super.spawn()


func validateSceneToSpawn(printWarnings: bool = self.debugMode) -> bool:
	# Don't call `super` because it's okay if `sceneToSpawn` is empty.
	# Log warnings only on `debugMode` to avoid noise if a caller is just checking
	if randomScenesList.is_empty():
		if printWarnings: Debug.printWarning("validateSceneToSpawn(): randomScenesList is empty", self)
		return false

	return true
