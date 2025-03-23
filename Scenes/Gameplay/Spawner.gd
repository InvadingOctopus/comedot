## Node that creates copies of a specified Scene as new children of itself or another node as their parent.
## NOTE: To actually spawn anything, some other script or Signal must call [member spawn]
## TIP: Use subclasses such as [SpawnTimer] or [RandomSpawnTimer] to spawn monsters or collectibles etc. at regular intervals.

class_name Spawner
extends Node

# TBD: Rename to SpawnerBase and designate as a base class?


#region Parameters

## The path of the Scene to spawn copies of.
@export_file("*.tscn") var sceneToSpawn: String # DESIGN: A String instead of PackedScene to avoid loading until needed, right?

## The parent node to add the new spawns to. If `null`, the spawns will be added as children of this area.
@export var parentOverride:	Node

## An optional group to add the spawned nodes to.
@export var groupToAddTo:	StringName

## Maintains a counter and stops spawning nodes when the maximum number is reached.
## NOTE: Does NOT monitor the deletion of previous nodes; so the counter never decreases. Use [member maximumLimitInGroup] to maintain a specific amount of nodes currently in the scene.
## If this value is -1 or any other negative number, then it is ignored. CAUTION: Spawning nodes infinitely will eventually cause system slowdown and a crash.
## Supersedes [member maximumLimitInGroup]
@export var maximumTotalToSpawn: int = -1

## Stops spawning nodes if [member groupToAddTo] has the specified amount of members.
## If this value is -1 or any other negative number, then it is ignored. CAUTION: Spawning nodes infinitely will eventually cause system slowdown and a crash.
## NOTE: [member maximumTotalToSpawn] supersedes this value and is checked first.
@export var maximumLimitInGroup: int = -1

## If [member sceneToSpawn] is an [Entity] and this flag is `true` then [member Entity.isLoggingEnabled] is set to `false`, in order to reduce log clutter.
## NOTE: Does NOT disable [member Entity.debugMode]
@export var suppressEntityLogs: bool = true

## If [member sceneToSpawn] is an [Entity] and this flag is `true` AND [member suppressEntityLogs] is `false` then [member Entity.debugMode] is also set to `true`
@export var debugMode: bool = false

@export var isEnabled: bool = true

#endregion


#region State
var totalNodesSpawned: int
#region


#region Signals

## Emitted before [member sceneToSpawn] is loaded and a copy is instantiated.
## TIP: This allows a signal handler to conditionally choose a different scene if needed.
signal willSpawn(scenePathToSpawn: String)

## Emitted before the newly-instantiated scene copy is added to the parent node.
## TIP: This allows the position etc. to be modified before the child node is made visible.
signal willAddSpawn(newSpawn: Node2D, parent: Node2D)

## Emitted after [signal willAddSpawn]
## TIP: To modify positioning, use the earlier signal to prevent visually-jarring jumps etc.
signal didSpawn(newSpawn: Node2D, parent: Node2D)

#endregion


## Creates and returns a new instance of [member sceneToSpawn]
func spawn() -> Node2D:
	# Validate first...

	if sceneToSpawn.is_empty():
		Debug.printWarning("No sceneToSpawn", self)
		return null
	
	# NOTE: <0 is ignored
	if maximumTotalToSpawn >= 0 \
	and totalNodesSpawned >= maximumTotalToSpawn:
		if debugMode: Debug.printDebug(str("totalNodesSpawned: ", totalNodesSpawned, " >= maximumTotalToSpawn: ", maximumTotalToSpawn), self)
		return null

	# NOTE: <0 is ignored
	if maximumLimitInGroup >= 0 \
	and not groupToAddTo.is_empty():
		var groupCount: int = self.get_tree().get_node_count_in_group(groupToAddTo)
		if groupCount >= maximumLimitInGroup:
			if debugMode: Debug.printDebug(str("maximumLimitInGroup: ", maximumLimitInGroup, " >= nodes in ", groupToAddTo, ": ", groupCount), self)
			return null

	# NOTE: Emit the `will` signal before loading the scene path,
	# in case a signal handler might want to modify `sceneToSpawn`
	willSpawn.emit(sceneToSpawn)

	# Load

	var sceneResource   := load(sceneToSpawn)
	var newSpawn: Node2D = sceneResource.instantiate()

	if not newSpawn:
		Debug.printWarning("Unable to instantiate scene: " + sceneToSpawn, self)
		return null
	
	# Prep the newborn

	if newSpawn is Entity:
		if self.suppressEntityLogs:
			newSpawn.isLoggingEnabled = false
			# NOTE: Do NOT suppress `Entity.debugMode` because that is an explicit decision when debugging so it should be left as is.
		elif self.debugMode: 
			# If we're not explicitly silencing Entity logs and the spawner is in debugMode, log the spawned Entity too!
			newSpawn.isLoggingEnabled = true
			newSpawn.debugMode = true

	# Add the new node to the parent
	
	var parent: Node

	if not parentOverride: parent = self.get_parent() # The [Timer]'s parent because [Timer] is not a [Node2D]
	else: parent = parentOverride

	# Let the game-specific subclasses, if any, customize the new copies.

	if validateNewNode(newSpawn, parent):

		if not groupToAddTo.is_empty():
			newSpawn.add_to_group(groupToAddTo, true)

		willAddSpawn.emit(newSpawn, parent) # TBD: Should this be emitted before adding to a group?
		parent.add_child(newSpawn, false) # PERFORMANCE: not force_readable_name (very slow according to Godot docs)

		if newSpawn.get_parent() == parent: # NOTE: Make sure the new node has not been reparented during its `_ready()`
			newSpawn.owner = parent # INFO: Necessary for persistence to a [PackedScene] for save/load.
		
		totalNodesSpawned += 1
		didSpawn.emit(newSpawn, parent)
		return newSpawn
	
	else:
		return null


## A method for subclasses to override. Prepares newly spawned node with further game-specific logic.
## May suppress the creation of a newly spawned node by checking additional conditions and returning `false`.
@warning_ignore("unused_parameter")
func validateNewNode(newSpawn: Node2D, parent: Node) -> bool:
	return isEnabled
