## A subclass of [Spawner] that spawns copies of different scenes in REVERSE order from the END of a given list.
## Each scene is REMOVED after a successful [method spawn] call, and this Spawner stops after the list is empty.
## This may be ideal for generating enemy waves etc.
## TIP: Call [method spawnBatch] to spawn multiple scenes from the stack.
## TIP: To spawn from a sequential list without popping, use [SpawnerList]
## TIP: To choose a random scene from a set of "weighted" options, use [SpawnerRandom]
## TIP: To use with a [SpawnPoint] or [SpawnArea] etc., enable "Editable Children" and replace the [Spawner] script with this script.

@warning_ignore("missing_tool")
class_name SpawnerStack extends SpawnerSequenceBase


#region Parameters
## A stack of scene paths to spawn copies from, starting from the LAST index.
## NOTE: Each path is permanently removed ONLY IF its spawn is successful.
## This ensures that enemy "waves" etc. are fully spawned in the correct order.
# in SpawnerSequenceBase: @export_file("*.tscn") var scenesList: Array[String] # DESIGN: Not named "scenesStack" to keep compatibility and drop-in replacement with SpawnerList etc.
#endregion


#region Signals
signal didPopFinalItem ## Emitted after the last item in the [member scenesList] stack has been popped.
#endregion


## "Injects" the LAST scene in [member scenesList] into [member sceneToSpawn]
func setupSpawn() -> bool:
	# `isEnabled` checked by spawn()
	if not validateList(true): return false # printWarnings

	# TBD: Warn in case we forgot to re-enable?
	# Debug.printDebug(str("spawn(): not isEnabled but scenesList has ", scenesList.size(), " items　・　Remember to re-enable manually after adding new scenes."), self)

	# Pluck the next scene from the stack, NOTE: but don't remove it yet!
	# Pop in onDidSpawn()
	sceneToSpawn = scenesList[scenesList.size() - 1]

	return true


func onDidSpawn(newSpawn: Node2D, _parent: Node) -> void:
	# DESIGN: Pop entries ONLY IF the spawn was successful
	# This ensures that waves like "normal monster → normal → normal → super monster" are preserved and spawned in order.
	if not is_instance_valid(newSpawn): return

	# Are we already empty?
	if scenesList.is_empty():
		sceneToSpawn = "" # Avoid stale paths from confusing later validation
		# NOTE: Do NOT emit `didPopFinalItem` here because the stack may have been emptied long ago!
		return

	# DESIGN: `scenesList` may have been modified by signal handlers or other hooks,
	# but that's fine and allows for complex game-specific "hacks"
	if debugMode: Debug.printDebug(str("spawn() successful: ", newSpawn, " ・ Popping index ", scenesList.size() - 1, ": ", scenesList.back()), self)
	scenesList.pop_back() # TBD: Pop the entry that actually spawned? Because signal handlers etc may have mutated the `scenesList` ..or should we allow that?

	# Did we deplete ourselves?
	if scenesList.is_empty():
		if debugMode: Debug.printDebug("spawn(): scenesList emptied", self)
		sceneToSpawn = "" # Avoid stale paths from confusing later validation
		didPopFinalItem.emit()
