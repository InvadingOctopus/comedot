## A variant of [SpawnTimer] that has a specific chance to spawn any scene from a list of scenes on each [Timer] timeout.
## NOTE: To use with a [SpawnPoint] or [SpawnArea] etc., enable "Editable Children" and replace the [SpawnTimer] script with this script.

class_name RandomSpawnTimer
extends SpawnTimer

# TODO: A separate chance for each scene
# TODO: Option for a sequential index


#region Parameters

## A list of scene paths that will be randomly chosen from to spawn a copy of. Each scene has an equal chance.
## NOTE: [member spawnChance] must succeed first before any scene is spawned.
@export_file("*.tscn") var randomScenesList: Array[String]

## The chance in percentage for an instance to be created whenever the Timer counts down.
@export_range(0, 100, 1, "suffix:%") var spawnChance: int = 100

#endregion


func onTimeout() -> void:
	if spawnChance >= 100 \
	or randi_range(1, 100) <= spawnChance: # i.e. if the chance is 10%, then any number from 1-10 should succeed.
		if debugMode: Debug.printDebug(str("onTimeout() roll >= spawnChance: ", spawnChance), self)

		# Choose a random scene
		self.sceneToSpawn = self.randomScenesList.pick_random()
		spawn()
