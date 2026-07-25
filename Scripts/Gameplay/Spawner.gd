## A [Node] that creates copies of a specified Scene, such as monsters or collectibles etc.
## and adds new instances as children of the specified parent node.
## NOTE: To actually spawn anything, [method spawn] must be called via [member shouldSpawnOnReady] or manually from other scripts or signals such as [signal Timer.timeout] etc.
## TIP: This script may be replaced with subclasses such as [SpawnerList] or [SpawnerRandom] to use lists of different spawns etc.
## TIP: See [SpawnPoint], [SpawnArea] & [SpawnEdge] etc. to spawn at specific positions or regions.
## TIP: See [OnScreenTrigger] or connect to [signal VisibleOnScreenNotifier2D.screen_entered] to spawn when the player reaches specific locations on a level map etc.

class_name Spawner
extends Node

# TBD: Rename to SpawnerBase and designate as a base class?


#region Parameters

@export var isEnabled: bool = true

## If [member sceneToSpawn] is an [Entity] and this flag is `true` AND [member shouldSuppressEntityLogs] is `false` then [member Entity.debugMode] is also set to `true`
@export var debugMode: bool = false


@export_group("Spawns")

## The path of the Scene to spawn copies of.
@export_file("*.tscn") var sceneToSpawn: String: # DESIGN: A String instead of PackedScene to avoid loading until needed, right?
	set(newValue):
		if newValue != sceneToSpawn:
			if debugMode: Debug.printChange("sceneToSpawn", sceneToSpawn, newValue, true) # logAsTrace
			sceneToSpawn = newValue

## If `true`, newly spawned nodes are added as children of the current scene's root node.
## NOTE: Suppresses [member parentOverride]
@export var shouldSpawnInSceneRoot:	bool = false

## The path to the node to set as the parent of new spawns.
## If empty or invalid, spawns will be added to the parent of this [Spawner] node.
## NOTE: Ignored if [member shouldSpawnInSceneRoot] is `true`
@export var parentOverride:		NodePath = ^".."

## An optional group to add the spawned nodes to, such as `&"enemies"` etc.
@export var groupToAddTo:		StringName

## If `true` then [method spawn] is deferred-called on [method _ready]
@export var shouldSpawnOnReady:	bool = false

## If [member sceneToSpawn] is an [Entity] and this flag is `true` then [member Entity.isLoggingEnabled] is set to `false`, in order to reduce log clutter.
## NOTE: Does NOT disable [member Entity.debugMode]
@export var shouldSuppressEntityLogs: bool = true


@export_group("Limits")

## Maintains a counter and stops spawning nodes when the maximum number is reached.
## NOTE: Does NOT monitor the deletion of previous nodes; so the counter never decreases. Use [member maxLimitInGroup] to maintain a specific amount of nodes currently in the scene.
## If this value is -1 or any other negative number, then it is ignored. CAUTION: Spawning nodes infinitely will eventually cause system slowdown and a crash.
## Supersedes [member maxLimitInGroup]
@export var maxTotalToSpawn:	int = -1

## Stops spawning nodes if [member groupToAddTo] has the specified amount of members.
## If this value is -1 or any other negative number, then it is ignored. CAUTION: Spawning nodes infinitely will eventually cause system slowdown and a crash.
## NOTE: [member maxTotalToSpawn] supersedes this value and is checked first.
@export var maxLimitInGroup:	int = -1

#endregion


#region State
@export_storage var totalNodesSpawned: int
#region


#region Signals

## Emitted before [member sceneToSpawn] is loaded and a copy is instantiated.
## TIP: This allows a signal handler to conditionally choose a different scene if needed.
signal willSpawn(scenePathToSpawn: String)

## Emitted before the newly-instantiated scene copy is added to the parent node.
## TIP: This allows the position etc. to be modified before the child node is made visible.
signal willAddSpawn(newSpawn: Node2D, parent: Node)

## Emitted after [signal willAddSpawn]
## TIP: To modify positioning, use the earlier signal to prevent visually-jarring jumps etc.
signal didSpawn(newSpawn: Node2D, parent: Node)

#endregion


func _ready() -> void:
	self.add_to_group(Global.Groups.spawners, true) # persistent
	if shouldSpawnOnReady: # Other checks may be performed by subclasses
		spawn.call_deferred()


#region It's Alive!!

## Creates and returns a new instance of [member sceneToSpawn]
func spawn() -> Node2D:
	# TBD: Add an `isSpawning` flag to avoid "re-entrancy" or let signal handlers spawn multiple times etc?
	if not isEnabled or not validateSceneToSpawn(true): return null # printWarnings

	# NOTE: <0 is ignored
	if maxTotalToSpawn >= 0 \
	and totalNodesSpawned >= maxTotalToSpawn:
		if debugMode: Debug.printDebug(str("totalNodesSpawned: ", totalNodesSpawned, " >= maxTotalToSpawn: ", maxTotalToSpawn), self)
		return null

	# NOTE: <0 is ignored
	if maxLimitInGroup >= 0 \
	and not groupToAddTo.is_empty():
		var groupCount: int = self.get_tree().get_node_count_in_group(groupToAddTo)
		if  groupCount >= maxLimitInGroup:
			if debugMode: Debug.printDebug(str("maxLimitInGroup: ", maxLimitInGroup, " >= nodes in ", groupToAddTo, ": ", groupCount), self)
			return null

	# NOTE: Emit the `will` signal before loading the scene path,
	# in case a signal handler might want to modify `sceneToSpawn`
	willSpawn.emit(sceneToSpawn)

	# Load

	var sceneResource: PackedScene = load(sceneToSpawn)
	if not sceneResource:
		Debug.printError("spawn() cannot load sceneToSpawn: " + sceneToSpawn, self)
		return null

	var newSpawn: Node2D = sceneResource.instantiate()
	if not newSpawn:
		Debug.printError("spawn() unable to instantiate scene: " + sceneToSpawn, self)
		return null

	# Prep the newborn

	if newSpawn is Entity:
		if self.shouldSuppressEntityLogs:
			newSpawn.isLoggingEnabled = false
			# NOTE: Do NOT suppress `Entity.debugMode` because that is an explicit decision when debugging so it should be left as is.
		elif self.debugMode:
			# If we're not explicitly silencing Entity logs and the spawner is in debugMode, log the spawned Entity too!
			newSpawn.isLoggingEnabled = true
			newSpawn.debugMode = true

	# Choose a parent

	var parent: Node

	if shouldSpawnInSceneRoot:			parent = self.get_tree().current_scene # DUMBDOT: Can't use `^"/"` to spawn at root because `get_node_or_null(^"/")` returns `null` and `^"/root"` resolves to the [Window] wtf
	elif not parentOverride.is_empty():	parent = self.get_node_or_null(parentOverride)

	# If neither the scene root or `parentOverride` are available, fall back to our parent
	if not parent: 						parent = self.get_parent()

	# Still an orphan? :(
	if not parent:
		Debug.printWarning(str("spawn() cannot find valid parent node for: ", newSpawn), self)
		newSpawn.queue_free()
		return null

	# Let the game-specific subclasses, if any, verify & customize the new copies.

	if validateNewNode(newSpawn, parent):

		if not groupToAddTo.is_empty():
			newSpawn.add_to_group(groupToAddTo, true) # persistent

		if debugMode: Debug.printDebug(str("spawn() willAddSpawn: ", newSpawn, " in ", parent, ", group: ", groupToAddTo), self)
		willAddSpawn.emit(newSpawn, parent) # TBD: Should this be emitted before adding to a group?
		parent.add_child(newSpawn,  false) # PERFORMANCE: not force_readable_name

		if  newSpawn.get_parent() == parent: # NOTE: Make sure the new node has not been reparented during its `_ready()`
			newSpawn.owner = parent # INFO: Necessary for persistence to a [PackedScene] for save/load.

		totalNodesSpawned += 1
		if debugMode: Debug.printDebug(str("spawn() didSpawn: ", newSpawn, " in ", newSpawn.get_parent(), ", total: ", totalNodesSpawned, ", total in group: ", self.get_tree().get_nodes_in_group(groupToAddTo).size()), self)
		didSpawn.emit(newSpawn, parent)
		return newSpawn

	# If a subclass rejects a spawn for whatever reason, abort it :'(
	else:
		newSpawn.visible = false # Just in case
		newSpawn.queue_free()
		return null

#endregion


#region Validation

## Validates [member sceneToSpawn]
## May be overridden by subclasses to add different checks.
func validateSceneToSpawn(printWarnings: bool = self.debugMode) -> bool:
	# Log warnings only on `debugMode` to avoid noise if a caller is just checking
	if sceneToSpawn.is_empty():
		if printWarnings: Debug.printWarning("validateSceneToSpawn(): sceneToSpawn is empty", self)
		return false

	return true


## A method for subclasses to override. Prepares newly spawned node with further game-specific logic.
## May suppress the creation of a newly spawned node by checking additional conditions and returning `false`.
@warning_ignore("unused_parameter")
func validateNewNode(newSpawn: Node2D, parent: Node) -> bool:
	return isEnabled

#endregion
