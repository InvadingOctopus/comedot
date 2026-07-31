## A [Node] that creates copies of a specified Scene, such as monsters or collectibles etc.
## and adds new instances as children of the specified parent node.
## NOTE: To actually spawn anything, [method spawn] must be called via [member shouldSpawnOnReady] or manually from other scripts or signals such as [signal Timer.timeout] etc.
## TIP: This script may be replaced with subclasses such as [SpawnerList] or [SpawnerRandom] to use lists of different spawns etc.
## TIP: See [SpawnPoint], [SpawnArea] & [SpawnEdge] etc. to spawn at specific positions or regions.
## TIP: See [OnScreenTrigger] or connect to [signal VisibleOnScreenNotifier2D.screen_entered] to spawn when the player reaches specific locations on a level map etc.

@tool
class_name Spawner
extends Node

# TBD: Rename to SpawnerBase and designate as a base class?


#region Parameters

@export var isEnabled: bool = true

## If [member sceneToSpawn] is an [Entity] and this flag is `true` AND [member shouldSuppressEntityLogs] is `false` then [member Entity.debugMode] is also set to `true`
@export var debugMode: bool


@export_group("Spawns")

## The path of the Scene to spawn copies of.
## IMPORTANT: The spawned scene's root node must be a [Node2D] subclass; spawns are assumed to be positionable etc.
@export_file("*.tscn") var sceneToSpawn: String: # PERFORMANCE: A [String] instead of [PackedScene] to avoid loading until needed
	set(newValue):
		if newValue != sceneToSpawn:
			if debugMode: Debug.printChange("sceneToSpawn", sceneToSpawn, newValue, true) # logAsTrace
			sceneToSpawn = newValue

## If `true`, newly spawned nodes are added as children of the current scene's root node.
## NOTE: Suppresses [member parentOverride]
@export var shouldSpawnInSceneRoot:	bool

## The path to the node to set as the parent of new spawns.
## If empty or invalid, spawns will be added to the parent of this [Spawner] node.
## NOTE: Ignored if [member shouldSpawnInSceneRoot] is `true`
@export var parentOverride:		NodePath = ^".."

## An optional group to add the spawned nodes to, such as `&"enemies"` etc.
@export var groupToAddTo:		StringName

## If `true` then [method spawn] is deferred-called on [method _ready]
@export var shouldSpawnOnReady:	bool

## If [member sceneToSpawn] is an [Entity] and this flag is `true` then [member Entity.isLoggingEnabled] is set to `false`, in order to reduce log clutter.
## NOTE: Does NOT disable [member Entity.debugMode]
@export var shouldSuppressEntityLogs: bool = true

## Adds a [Timer] as a child of this [Spawner] and connects its [signal Timer.timeout] → [method Spawner.spawn]
## If there's already a [Timer] child node, it is reused.
## NOTE: Not usable from [Spawner] subclasses such as [SpawnerRandom] etc.
@export_tool_button("Add Timer", "Timer") var addTimerButton: Callable = addTimerInEditor


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
var isSpawning: bool ## Set to `true` during an active [method spawn] call.
#endregion


#region Signals

## Emitted at the start of [method setupSpawn] before a [member sceneToSpawn] is chosen.
## TIP: This allows a signal handler to modify the [Spawner] state.
signal willSetupSpawn

## Emitted before [member sceneToSpawn] is validated, loaded and a copy is instantiated.
## TIP: This allows a signal handler to conditionally choose a different scene if needed.
signal willSpawn(scenePathToSpawn: String)

## Emitted before the newly-instantiated scene copy is added to the parent node.
## TIP: This allows the position etc. to be modified before the child node is made visible.
signal willAddSpawn(newSpawn:	Node2D, parent: Node)

## Emitted after [signal willAddSpawn]
## TIP: To modify positioning, use the earlier signal to prevent visually-jarring jumps etc.
signal didSpawn(newSpawn:		Node2D, parent: Node)

## Emitted if [method spawn] or [method validateSpawnedNode] fails.
## NOTE: The [param parent] argument may be `null` if the spawn fails before a parent can be chosen.
## TIP: Connect to [method Timer.stop] to stop retrying invalid spawns/waves etc.
signal didFailSpawn(scenePath:	String, parent: Node)

#endregion


#region Setup & Validation

func _ready() -> void:
	if Engine.is_editor_hint(): return

	self.add_to_group(Global.Groups.spawners, true) # persistent
	if shouldSpawnOnReady: # Other checks may be performed by subclasses
		spawn.call_deferred()


## An abstract hook for subclasses to prepare and/or pick a scene to spawn, such as in [SpawnerList] & [SpawnerStack]
func setupSpawn() -> bool:
	return true


## Validates [member sceneToSpawn]
## May be overridden by subclasses to add different checks.
func validateSceneToSpawn(printWarnings: bool = self.debugMode) -> bool:
	# Log warnings only on `debugMode` to avoid noise if a caller is just checking
	if sceneToSpawn.is_empty():
		if printWarnings: Debug.printWarning("validateSceneToSpawn(): sceneToSpawn is empty", self)
		return false
	elif not ResourceLoader.exists(sceneToSpawn, "PackedScene"):
		if printWarnings: Debug.printWarning("validateSceneToSpawn(): sceneToSpawn does not exist or is not a PackedScene: " + sceneToSpawn, self)
		return false
	else:
		return true


## A method for subclasses to override. Prepares newly spawned node with further game-specific logic.
## May suppress the creation of a newly spawned node by checking additional conditions and returning `false`.
@warning_ignore("unused_parameter")
func validateSpawnedNode(newSpawn: Node2D, parent: Node) -> bool:
	return isEnabled # NOTE: Let `isEnabled` be used by handlers/hooks to abort a spawn


## Called by [method spawn] on failure.
func abortSpawn(scenePath: String, parent: Node, debugMessage: String = "") -> void:
	if debugMode and not debugMessage.is_empty(): Debug.printDebug(debugMessage, self)
	didFailSpawn.emit(scenePath, parent)
	# NOTE: Clear `isSpawning` AFTER `didFailSpawn` to prevent handlers from calling spawn() recursively
	isSpawning = false

#endregion


#region It's Alive!!

## Creates and returns a new instance of [member sceneToSpawn]
func spawn() -> Node2D:
	if Engine.is_editor_hint(): return null

	if not isEnabled or isSpawning: return null # TBD: Log warning if `isSpawning`?

	# Guard against nested spawns & "re-entrancy"
	isSpawning = true

	# Allow subclasses to pick a scene
	willSetupSpawn.emit() # NOTE: Handlers may disable `isEnabled` to abort a spawn…
	# …so we check `isEnabled` again
	if not isEnabled or not setupSpawn():
		abortSpawn(sceneToSpawn, null)
		return null

	# NOTE: Emit the `will` signal before loading the scene path,
	# in case a signal handler wants to modify `sceneToSpawn`
	# IMPORTANT: Emit before validation in case handlers mutate our state!
	willSpawn.emit(sceneToSpawn)

	if not validateSceneToSpawn(true): # printWarnings
		abortSpawn(sceneToSpawn, null)
		return null	

	# NOTE: <0 is ignored
	if  maxTotalToSpawn >= 0 \
	and totalNodesSpawned >= maxTotalToSpawn:
		abortSpawn(sceneToSpawn, null, str("totalNodesSpawned: ", totalNodesSpawned, " >= maxTotalToSpawn: ", maxTotalToSpawn))
		return null

	# NOTE: <0 is ignored
	if  maxLimitInGroup >= 0 \
	and not groupToAddTo.is_empty():
		var groupCount: int = self.get_tree().get_node_count_in_group(groupToAddTo)
		if  groupCount >= maxLimitInGroup:
			abortSpawn(sceneToSpawn, null, str("maxLimitInGroup: ", maxLimitInGroup, " >= nodes in ", groupToAddTo, ": ", groupCount))
			return null

	# Load

	var sceneResource: PackedScene = load(sceneToSpawn)
	if not sceneResource:
		Debug.printError("spawn() cannot load sceneToSpawn: " + sceneToSpawn, self)
		abortSpawn(sceneToSpawn, null)
		return null

	var instance := sceneResource.instantiate() # Do NOT cast `as Node2D` so we can free it; casting would give `null` if the scene is a [Node] etc. # TBD: PERFORMANCE: Crash if not [Node2D] instead of creating another `var`?
	var newSpawn: Node2D = instance as Node2D
	if not newSpawn:
		Debug.printError("spawn() unable to instantiate scene or not a Node2D subclass: " + sceneToSpawn, self)
		if instance: instance.queue_free()
		abortSpawn(sceneToSpawn, null)
		return null

	# Prep the newborn

	if newSpawn is Entity:
		if self.shouldSuppressEntityLogs:
			newSpawn.isLoggingEnabled = false
			# NOTE: Do NOT suppress `Entity.debugMode` because that is an explicit decision when debugging so it should be left as is.
		elif self.debugMode:
			# If we're not explicitly silencing Entity logs and the spawner is in debugMode, log the spawned Entity too!
			newSpawn.isLoggingEnabled = true
			newSpawn.debugMode		  = true

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
		abortSpawn(sceneToSpawn, null)
		return null

	# Let the game-specific subclasses, if any, verify & customize the new copies.

	if validateSpawnedNode(newSpawn, parent):

		if not groupToAddTo.is_empty():
			newSpawn.add_to_group(groupToAddTo, true) # persistent

		if debugMode: Debug.printDebug(str("spawn() willAddSpawn: ", newSpawn, " in ", parent, ", group: ", groupToAddTo), self)
		willAddSpawn.emit(newSpawn, parent) # TBD: Should this be emitted before adding to a group?
		parent.add_child(newSpawn,  false) # PERFORMANCE: not force_readable_name

		if  newSpawn.get_parent() == parent: # NOTE: Make sure the new node has not been reparented during its _ready()
			# Set the "owner" for persistence etc.
			# NOTE: Godot docs say "The owner needs to be the current scene root."
			# TBD: PERFORMANCE: Get the scene root or use a shortcut of reusing the `parent.owner`?
			newSpawn.owner  = parent.owner if parent.owner else parent # Default to `parent` in case `parent` IS the scene root

		totalNodesSpawned += 1
		if debugMode: Debug.printDebug(str("spawn() didSpawn: ", newSpawn, " in ", newSpawn.get_parent(), ", total: ", totalNodesSpawned, ", total in group: ", self.get_tree().get_nodes_in_group(groupToAddTo).size()), self)
		didSpawn.emit(newSpawn, parent)
		isSpawning = false
		return newSpawn

	# If a subclass rejects a spawn for whatever reason, abort it :'(
	else:
		newSpawn.visible = false # Just in case
		newSpawn.queue_free()
		abortSpawn(sceneToSpawn, parent)
		return null

#endregion


#region Editor Convenience

func addTimerInEditor() -> void:
	if not Engine.is_editor_hint(): return

	var spawnMethod: Callable = Callable(self, &"spawn")

	# A naive check to see if there's already any other Timer
	var existingTimer: Timer = NodeTools.findFirstChildOfType(self, Timer)
	if  existingTimer:
		if not existingTimer.timeout.is_connected(spawnMethod):
			# Connect signals with an existing Timer
			var undoManager: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
			undoManager.create_action("Connect " + existingTimer.name + ".timeout → " + self.name + ".spawn()")
			undoManager.add_do_method(existingTimer,	&"connect",		&"timeout",	spawnMethod, Object.CONNECT_PERSIST)
			undoManager.add_undo_method(existingTimer,	&"disconnect",	&"timeout",	spawnMethod)
			undoManager.commit_action()
		EditorTools.selectNode.call_deferred(existingTimer)
		return

	# Create a new Timer

	var sceneRoot: Node = EditorInterface.get_edited_scene_root()
	if not sceneRoot: return

	var newTimer: Timer	= Timer.new()
	newTimer.name		= self.name + "Timer"
	newTimer.autostart	= true

	var connectTimer:	Callable = Callable(newTimer, &"connect").bind(&"timeout", spawnMethod, Object.CONNECT_PERSIST)
	var disconnectTimer:Callable = Callable(newTimer, &"disconnect").bind(&"timeout", spawnMethod)

	var didAddTimer: bool = EditorTools.addNodeWithUndo(
		newTimer, self,
		"Add Timer for " + self.name,
		false, # showEditableChildren
		[connectTimer], [disconnectTimer])

	if didAddTimer: EditorTools.selectNode.call_deferred(newTimer)
	else: newTimer.free()

#endregion
