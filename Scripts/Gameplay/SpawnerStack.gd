## A subclass of [Spawner] that spawns copies of different scenes in REVERSE order from the END of a given list.
## Each scene is REMOVED after a successful [method spawn] call, and this Spawner stops after the list is empty.
## This may be ideal for generating enemy waves etc.
## TIP: To spawn from a sequential list without popping, use [SpawnerList]
## TIP: To choose a random scene from a set of "weighted" options, use [SpawnerRandom]
## TIP: To use with a [SpawnPoint] or [SpawnArea] etc., enable "Editable Children" and replace the [Spawner] script with this script.

class_name SpawnerStack
extends Spawner


#region Parameters
## A stack of scene paths to spawn copies from, starting from the LAST index.
## NOTE: Each path is permanently removed ONLY IF its spawn is successful.
## This ensures that enemy "waves" etc. are fully spawned in the correct order.
@export_file("*.tscn") var scenesList: Array[String]
#endregion


## Overrides [method Spawner.spawn] to "inject" the LAST scene in [member scenesList] into [member sceneToSpawn]
## then calls `super.spawn()` and pops the stack to remove the last scene if the spawn was successful.
func spawn() -> Node2D:
	if not isEnabled:
		# Did we forget to re-enable?
		if debugMode and not scenesList.is_empty(): Debug.printDebug(str("spawn(): not isEnabled but scenesList has ", scenesList.size(), " items　・　Remember to re-enable manually after adding new scenes."), self)
		return null

	# Did we empty ourselves during the last call?
	if  scenesList.is_empty():
		sceneToSpawn	= "" # Avoid stale paths from confusing later validation
		self.isEnabled  = false # Power down until there are new items in the list
		return null

	if not validateSceneToSpawn(true): return null # printWarnings

	# Pluck the next scene from the stack, NOTE: but don't remove it yet!
	var sceneIndexToSpawn: int = scenesList.size() - 1
	self.sceneToSpawn = self.scenesList[sceneIndexToSpawn]

	if sceneToSpawn.is_empty():
		Debug.printWarning(str("spawn(): Empty path at index ", sceneIndexToSpawn), self)
		return null

	# Ask the Spawner superclass to spawn
	var newSpawn: Node2D = super.spawn()
	if  newSpawn == null: return null

	# DESIGN: Pop entries ONLY IF the spawn was successful
	# This ensures that waves like "normal monster → normal → normal → super monster" are preserved and spawned in order.
	if debugMode: Debug.printDebug(str("spawn() successful: ", newSpawn, " ・ Popping index ", sceneIndexToSpawn, ": ", scenesList.back()), self)
	self.scenesList.pop_back() # TBD: Pop the entry that actually spawned? Because signal handlers etc may have mutated the `scenesList` ..or should we allow that?

	# Did we drain ourself?
	if scenesList.is_empty():
		if debugMode: Debug.printDebug("spawn(): scenesList emptied ・ isEnabled → false", self)
		self.isEnabled	  = false
		self.sceneToSpawn = "" # Avoid stale paths from confusing later validation

	return newSpawn


## Validates [member scenesList] before a scene is selected.
func validateSceneToSpawn(printWarnings: bool = self.debugMode) -> bool:
	if scenesList.is_empty():
		# NOTE: Don't print warnings for an empty stack because that is expected behavior after popping the last item
		if printWarnings: Debug.printDebug("validateSceneToSpawn(): scenesList is empty", self)
		return false # But still return false becasue we can't spawn nothin!

	return true
