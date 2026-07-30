## An abstract base class for all [Spawner] variants that can instantiate copies of more than 1 scene,
## such as [SpawnerList] & [SpawnerStack]
## NOTE: [SpawnerRandom] uses a "weights" [Dictionary] so it's excluded from this "family"

@warning_ignore("missing_tool")
@abstract class_name SpawnerSequenceBase extends Spawner


#region Parameters
## A list of scene paths to spawn copies from.
## NOTE: Different scripts may use this differently:
## [SpawnerList] spawns in order from first to last.
## [SpawnerStack] spawns in REVERSE order from the last item, "popping" (removing) each item from the list on each spawn.
## WARNING: Modifying this array during an ongoing [method spawnBatch] call may cause bugs or unexpected behavior!
@export_file("*.tscn") var scenesList: Array[String]
#endregion


#region Shared Logic

func _init() -> void:
	# Wire signals in _init() to ensure the list is updated for all possible spawn() calls
	# Update the list/index after successful spawns
	if not self.didSpawn.is_connected(self.onDidSpawn):
		self.didSpawn.connect(self.onDidSpawn) # TBD: `Object.CONNECT_PERSIST?`


## Subclasses must implement this to update the [member scenesList], e.g. increment an index or pop an item.
@abstract func onDidSpawn(newSpawn: Node2D, parent: Node) -> void


## Validates [member scenesList] before a scene is selected.
## Subclasses may add extra checks.
func validateList(printWarnings: bool = self.debugMode) -> bool:
	if scenesList.is_empty():
		# NOTE: Don't print warnings for an empty stack because that is expected behavior after popping the last item
		if printWarnings: Debug.printDebug("validateList(): scenesList empty", self)
		# Clean up if we're empty
		sceneToSpawn = "" # Avoid invalid/stale paths from confusing validateSceneToSpawn() etc
		return false # But still return false because we can't spawn nothin!

	return true


## Calls [method spawn] repeatedly to spawn multiple scenes from [member scenesList]
## until [param maxSpawnsForThisCall] or until a spawn fails or [member isEnabled] is set to `false`
## TIP: Useful for spawning an entire wave of enemies in a single signal etc.
## PERFORMANCE: [param returnSpawns] is disabled by default to avoid wasting memory on an [Array] unless the caller needs to access the spawned nodes.
func spawnBatch(maxSpawnsForThisCall: int = 100, returnSpawns: bool = false) -> Array[Node2D]:
	# DESIGN: Do not call validateList() or perform any further validation;
	# Let spawn() do all the checks and let spawnBatch() simply be a `for` loop around spawn()
	# ALLOWED: Signal handlers/hooks may modify the list or other state before each spawn() call
	# for complex game-specific behavior.

	if not isEnabled or isSpawning or maxSpawnsForThisCall < 1: return []

	var spawns:	  Array[Node2D]
	var newSpawn: Node2D

	# Let spawn() → setupSpawn() prep the list before we can check it
	# UNUSED: maxSpawnsForThisCall = mini(maxSpawnsForThisCall, scenesList.size())

	for _count in maxSpawnsForThisCall:
		# NOTE: Let spawn() set `isSpawning`
		# DESIGN: Do NOT check scenesList.is_empty() because [SpawnerStack] will pop the last item from the array
		# but the next setupSpawn() or `willSetupSpawn` handler may "refill" the list.
		newSpawn = spawn()
		if newSpawn == null: break # The stack will not be popped on a failed spawn, so don't retry
		if returnSpawns: spawns.append(newSpawn) # PERFORMANCE: Don't waste memory if a list of spawns isn't needed
		if not isEnabled: break # Recheck conditions in case the state was mutated by a signal handler etc.

	return spawns # == [] if not returnSpawns

#endregion
