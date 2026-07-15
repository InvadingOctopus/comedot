## A subclass of [Spawner] that spawns copies of different scenes in REVERSE order from the END of a given list.
## Each scene is REMOVED on each [method spawn] call, and this Spawner stops after the list is empty.
## This may be ideal for generating enemy waves etc.
## TIP: To spawn from a sequential list without popping, use [SpawnerList]
## TIP: To choose a random scene from a set of "weighted" options, use [SpawnerRandom]
## TIP: To use with a [SpawnPoint] or [SpawnArea] etc., enable "Editable Children" and replace the [Spawner] script with this script.

class_name SpawnerStack
extends Spawner


#region Parameters
## A stack of scene paths to spawn copies from, starting from the LAST index.
## NOTE: Each path is permanently removed BEFORE its spawn is attempted, EVEN IF the spawn is not successful.
## This ensures that enemy "waves" etc. are fully emptied.
@export_file("*.tscn") var scenesList: Array[String]
#endregion


#region State
var isPopping: bool ## `true` while an item has been popped from [member scenesList] during a [method spawn] call. Reset back to `false` after the method finishes.
#endregion


## Overrides [method Spawner.spawn] to pop the path at the last [member scenesList] index
## and "injects" it into [member sceneToSpawn] then calls `super.spawn()`
func spawn() -> Node2D:
	if not isEnabled:
		# Did we forget to re-enable?
		if debugMode and not scenesList.is_empty(): Debug.printDebug(str("spawn(): not isEnabled but scenesList has ", scenesList.size(), " items　・　Remember to re-enable manually after adding new scenes."), self)
		return null

	# Did we empty ourselves during the last call?
	if scenesList.is_empty():
		sceneToSpawn	= "" # Avoid stale paths from confusing later validation
		self.isEnabled  = false # Power down until there are new items in the list
		return null

	if not validateSceneToSpawn(true): return null # printWarnings

	var sceneIndexToSpawn: int = scenesList.size() - 1

	# DESIGN: Pop entries EVEN IF the spawn was NOT successful
	# so that enemy "waves" may be fully emptied, because that would be the expected behavior.
	if debugMode: Debug.printDebug(str("spawn(): Popping index ", sceneIndexToSpawn, ": ", scenesList.back()), self)
	self.isPopping		= true
	self.sceneToSpawn	= self.scenesList.pop_back()

	var newSpawn: Node2D

	if sceneToSpawn.is_empty():
		Debug.printWarning(str("spawn(): Empty path at index ", sceneIndexToSpawn), self)
	else:
		newSpawn = super.spawn()

	if scenesList.is_empty():
		if debugMode: Debug.printDebug("spawn(): scenesList emptied ・ isEnabled → false", self)
		sceneToSpawn	= "" # Avoid stale paths from confusing later validation
		self.isEnabled	= false

	self.isPopping = false
	return newSpawn


## Validates [member scenesList] before a scene is selected.
## After the final path is popped, delegates to [method Spawner.validateSceneToSpawn] to validate the selected path.
func validateSceneToSpawn(printWarnings: bool = self.debugMode) -> bool:
	if scenesList.is_empty():
		if self.isPopping:
			# Delegate to the superclass' single scene validation behavior,
			# in case this is the last scene we popped before calling `super.spawn()`
			return super.validateSceneToSpawn(printWarnings)
		# NOTE: Don't print warnings for an empty stack because that is expected behavior after popping the last item
		if printWarnings: Debug.printDebug("validateSceneToSpawn(): scenesList is empty", self)
		return false # But still return false becasue we can't spawn nothin!

	return true
