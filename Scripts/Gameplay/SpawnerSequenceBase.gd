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

## If `true`, empty paths in [member scenesList] are silently skipped instead of treated as failures.
## Each skip "consumes" an item in the sequence, i.e. incrementing the [member SpawnerList.currentSceneIndex] or popping [SpawnerStack]
## and skips one [method spawnBatch] iteration without spawning a node.
## TIP: This may be used with a [Timer] to add delays during enemy waves,
## e.g. a wave of 3 normal enemies, a short delay, then a "wave leader/boss" etc.
@export var shouldSkipEmptyPaths: bool

#endregion


#region Shared Logic

func _init() -> void:
	# Wire signals in _init() to ensure the list/index is updated after spawn()
	if not self.didSpawn.is_connected(self.onDidSpawn):
		self.didSpawn.connect(self.onDidSpawn) # TBD: `Object.CONNECT_PERSIST?`


## Calls [method selectNextScene] after a successful spawn.
func onDidSpawn(newSpawn: Node2D, _parent: Node) -> void:
	if is_instance_valid(newSpawn): selectNextScene()


## Abstract; MUST be implemented by subclasses to advance the sequence,
## i.e. incrementing the array index in [SpawnerList] or popping the stack in [SpawnerStack]
## DESIGN: This ensures that waves like "normal monster → normal → normal → super monster" are preserved and spawned in order.
## TIP: [member shouldSkipEmptyPaths] acts as a delay during waves e.g. "normal → skip/wait → super"
@abstract func selectNextScene() -> void


## Validates [member scenesList] before a scene is selected.
## Subclasses may add extra checks.
func validateList(printWarnings: bool = self.debugMode) -> bool:
	if scenesList.is_empty():
		# NOTE: Don't print warnings for an empty stack because that is expected behavior after popping the last item
		if printWarnings and debugMode: Debug.printDebug("validateList(): scenesList empty", self)
		# Clean up if we're empty
		sceneToSpawn = "" # Avoid invalid/stale paths from confusing validateSceneToSpawn() etc
		return false # But still return false because we can't spawn nothin!

	return true


## Overrides superclass to suppress normal failure handling for empty paths if [member shouldSkipEmptyPaths]
func abortSpawn(scenePath: String, parent: Node, debugMessage: String = "") -> void:
	if shouldSkipEmptyPaths and sceneToSpawn.is_empty() and isEnabled and validateList(false): # not printWarnings; Make sure the list has remaining items
		if debugMode: Debug.printDebug("abortSpawn() shouldSkipEmptyPaths, ignoring abort reason: \"" + debugMessage + "\"", self)
		selectNextScene()
		isSpawning = false # Avoid "re-entrancy" until the list/sequence updates are finished
	else:
		super.abortSpawn(scenePath, parent, debugMessage)
		return


## Calls [method spawn] repeatedly to spawn multiple scenes from [member scenesList]
## until [param maxSpawnsForThisCall] or until a spawn fails or [member isEnabled] is set to `false`
## If [member shouldSkipEmptyPaths] then an empty string in [member scenesList] does not abort the batch, effectively adding a delay if used with a [Timer]
## TIP: Useful for spawning an entire wave of enemies in a single signal etc.
## PERFORMANCE: [param returnSpawns] is disabled by default to avoid wasting memory on an [Array] unless the caller needs to access the spawned nodes.
func spawnBatch(maxSpawnsForThisCall: int = 100, returnSpawns: bool = false) -> Array[Node2D]:
	# DESIGN: Let spawn() perform all setup and validation.
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
		if newSpawn == null: # Stop on failures or emptying the list
			# If `shouldSkipEmptyPaths` then treat empty paths as delays e.g. for [Timer]s etc.
			if not shouldSkipEmptyPaths or not sceneToSpawn.is_empty() or not validateList(false): break
		elif returnSpawns:
			spawns.append(newSpawn) # PERFORMANCE: Don't waste memory if a list of spawns isn't needed

		if not isEnabled: break # Recheck conditions in case the state was mutated by a signal handler etc.

	return spawns # == [] if not returnSpawns

#endregion
