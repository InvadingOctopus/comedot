## A subclass of [VisibleOnScreenNotifier2D] & [SpawnLocationTrigger] with a [SpawnerStack] for spawning enemy waves at specific locations on a scrolling map.
## EXAMPLE: In a scrolling shoot-em-up.
## TIP: Enable "Editable Children" to access the internal [Spawner] & [Timer] properties.

class_name SpawnWaveTrigger
extends SpawnLocationTrigger


#region Parameters

## If not empty, replaces the scenes list of a [SpawnerList] or [SpawnerStack] BEFORE adding [member appendScenesList]
@export_file("*.tscn") var replaceScenesList:	Array[String]

## Adds more scenes to a [SpawnerList] or [SpawnerStack] AFTER assigning [member replaceScenesList] if not empty.
## ALERT: If a wave is aborted e.g. on [signal Spawner.didFailSpawn] then leftover paths in the [member SpawnerStack.scenesList] may cause duplicates when [member appendScenesList] is appended again. Set [member shouldClearListOnFailure] to prevent duplicates.
@export_file("*.tscn") var appendScenesList:	Array[String]

## Clears the [member SpawnerStack.scenesList] on [signal Spawner.didFailSpawn] etc. to avoid duplicate paths on the next merge of [member appendScenesList]
## WARNING: This will clear any directly-assigned [SpawnerStack] list even if [member appendScenesList] is empty!
@export var shouldClearListOnFailure:			bool = true

## If `true` (default) then the first spawn is immediately attempted on [method trigger] → [method spawnWave] before waiting for the first [signal Timer.timeout] of the [member spawnTimer]
## TIP: This may eliminate or reduce the visual lag between this [SpawnWaveTrigger] node appearing on screen and the first spawn, not counting any distance introduced by the [member initialPositionPlaceholder] etc.
## NOTE: This does NOT omit the [member delayTimer] if any is set.
@export var shouldSpawnImmediatelyOnTrigger:	bool = true

## Optional. If specified, new spawns will be placed at the node specified by this path,
## THEN the spawns will be aligned to this [SpawnWaveTrigger] if [member shouldMatchThisNodeX] / [member shouldMatchThisNodeY]
## TIP: Set this path to one of the [SpawnPoint]s in [SpawnEdge] to spawn enemy waves from a specific side of the screen, but at different lateral positions along that side
## EXAMPLE: `%SpawnEdge/Points/SpawnPointN` in a vertically-scrolling shoot-em-up etc.
@export_node_path("Node2D") var initialPositionPlaceholder: NodePath

#endregion

#region State
@onready var spawnerStack:	SpawnerStack = $SpawnerStack
@onready var spawnTimer:	Timer		 = $SpawnerStack/SpawnTimer

var isSpawningWave: bool:
	get: return spawnTimer and not spawnTimer.is_stopped() # Avoid crash before _ready()
#endregion


func _ready() -> void:
	if self.debugMode: spawnerStack.debugMode = true # Enable if we're also in `debugMode` but don't disable the Spawner's `debugMode` if we're not.
	super._ready()


#region Trigger

## Re-enables the [member spawnerStack] when not empty.
## Connect to [signal OnScreenTrigger.didTrigger]
func spawnWave() -> bool:
	if not isEnabled or isSpawningWave or not self.is_node_ready(): return false

	updateLists(spawnerStack)

	# Check the spawner's list AFTER stuffing our scenes into it
	if not spawnerStack.scenesList.is_empty(): spawnerStack.isEnabled = true # In case the Spawner was previously disabled, or its list was updated outside of our updateLists()
	else: return false

	# Start the Timer BEFORE the optional immediate spawn, because a spawn failure should stop the Timer.
	spawnTimer.start()

	if shouldSpawnImmediatelyOnTrigger: spawnerStack.spawn()

	return true


## Applies this [member replaceScenesList] / [member appendScenesList] to the inner [SpawnerStack]
func updateLists(spawner: SpawnerSequenceBase = self.spawnerStack) -> Array[String]:
	if not is_instance_valid(spawner): return []
	if replaceScenesList.is_empty() and appendScenesList.is_empty(): return spawner.scenesList

	# Replace?
	if not replaceScenesList.is_empty():
		if debugMode: Debug.printDebug(str("updateLists() ", spawner, ": ", spawner.scenesList, " → ", replaceScenesList), self)
		# Copy the paths without sharing a reference to our Array via `=` assignment,
		# because when SpawnerStack removes entries, that would mutate this class's Array too.
		spawner.scenesList.assign(replaceScenesList)
		if spawner is SpawnerList: spawner.currentSceneIndex = 0 # Reset the spawner's index in its list

	# Append?
	if not appendScenesList.is_empty():
		if debugMode: Debug.printDebug(str("updateLists() ", spawner, ": ", spawner.scenesList, " + ", appendScenesList), self)
		spawner.scenesList.append_array(appendScenesList)

	return spawner.scenesList


func onSpawnerStack_didFailSpawn(_scenePath: String, _parent: Node) -> void:
	if shouldClearListOnFailure: spawnerStack.scenesList.clear()

#endregion


#region Placement

## Aligns the [param newSpawn]'s [member Node2D.position] with [member initialPositionPlaceholder] if any,
## then calls the [SpawnLocationTrigger] superclass to align the spawn with this [SpawnWaveTrigger] node, before the spawn is added to [param parent]
## NOTE: Accurate alignment across different [CanvasLayer]s requires this [SpawnLocationTrigger] and [param parent] to use the same [Viewport]
## If [param parent] is a [Node] then the alignment may not be accurate.
func onSpawner_willAddSpawn(newSpawn: Node2D, parent: Node) -> void:
	if not self.initialPositionPlaceholder.is_empty():
		var placementNode: Node2D = self.get_node_or_null(self.initialPositionPlaceholder)
		if  placementNode:
			# Convert the placement node's origin to `parent`'s local space, including any Camera2D or CanvasLayer transforms.
			if is_instance_of(parent, CanvasItem):
				newSpawn.position = parent.make_canvas_position_local(placementNode.get_global_transform_with_canvas() * Vector2.ZERO)
			else:
				newSpawn.position = placementNode.global_position

	super.onSpawner_willAddSpawn(newSpawn, parent)

#endregion
