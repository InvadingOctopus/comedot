## A subclass of [VisibleOnScreenNotifier2D] & [OnScreenTrigger] that triggers a [Spawner] when this node enters the screen view,
## and aligns the X/Y position of new spawns with this node.
## TIP: This may be used with the [SpawnPoint]s in [SpawnEdge] to keep spawns at one side of the screen but "slide" them along the edge.
## IMPORTANT: To use, connect [signal Spawner.willAddSpawn] → [method SpawnLocationTrigger.onSpawner_willAddSpawn]
## and/or [signal SpawnLocationTrigger.didTrigger] (unbind 1 argument) → [method Spawner.spawn] or [method SpawnerList.spawnBatch] or [method Timer.start] etc.
## TIP: Connect [signal SpawnLocationTrigger.screen_exited] to [method Timer.stop] to stop spawning.
## TIP: Place on a large scrolling level map to trigger enemy waves from an edge of the screen when the player arrives at specific locations,
## via [SpawnerList] or [SpawnerStack]

class_name SpawnLocationTrigger
extends OnScreenTrigger


#region Parameters
@export var shouldMatchThisNodeX: bool = false ## If `true` then each new spawn is horizontally aligned with this node in canvas space.
@export var shouldMatchThisNodeY: bool = false ## If `true` then each new spawn is vertically aligned with this node in canvas space.
@export var offset: Vector2 ## The amount by which to shift each new spawn's position after aligning.
#endregion


#region Trigger

## Aligns the [param newSpawn]'s [member Node2D.position] with this trigger node before the spawn is added to [param parent]
## NOTE: Accurate alignment across different [CanvasLayer]s requires this [SpawnLocationTrigger] and [param parent] to use the same [Viewport]
## If [param parent] is a [Node] then the alignment may not be accurate.
func onSpawner_willAddSpawn(newSpawn: Node2D, parent: Node) -> void:
	if  not isEnabled \
	or (not shouldMatchThisNodeX and not shouldMatchThisNodeY): return
	if debugMode: Debug.printDebug(str("onSpawner_willAddSpawn(): ", newSpawn), self)

	# Convert positions

	var spawnPosition:		Vector2	= newSpawn.position # The current unparented position; a future CanvasItem parent will interpret it as parent-local.
	var targetPosition:		Vector2	= self.global_position + self.offset # The target in this trigger's canvas coordinates, with `offset` applied before viewport conversion.
	var isParentCanvasItem:	bool	= is_instance_of(parent, CanvasItem) # Whether `parent` supports local-to-viewport and viewport-to-local conversions.

	# Convert both positions to viewport space so their X/Y coordinates use the same coordinate system, including transforms from [Camera] & [CanvasLayer] if any
	# WHY: to_global() & to_local() may not work across different CanvasLayers etc.
	if  isParentCanvasItem:
		spawnPosition  = parent.get_global_transform_with_canvas() * spawnPosition # Predict the spawn's viewport position using its future parent's full local-to-viewport transform.
		targetPosition = self.get_canvas_transform() * targetPosition # The target is already canvas-global, so apply only this trigger's canvas-to-viewport transform.

	# Align the spawn's axes with the target position in viewport space
	if   shouldMatchThisNodeX and shouldMatchThisNodeY: spawnPosition = targetPosition
	elif shouldMatchThisNodeX: spawnPosition.x = targetPosition.x
	elif shouldMatchThisNodeY: spawnPosition.y = targetPosition.y

	# Convert the aligned viewport position back to `parent`'s local coordinates.
	# If `parent` is a [Node] it will have no [CanvasItem] transform, so use the aligned position directly.
	newSpawn.position = parent.make_canvas_position_local(spawnPosition) if isParentCanvasItem else spawnPosition

#endregion
