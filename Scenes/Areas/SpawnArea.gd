## Creates copies of the specified scene at a random position on regular intervals.
## Currently only optimized for rectangular area shapes.

class_name SpawnArea
extends Area2D


#region Parameters

@export var sceneToSpawn: PackedScene

## The parent node to add the new spawns to. If `null`, the spawns will be added as children of this area.
@export var parentOverride: Node

## An optional group to add the spawned nodes to.
@export var groupToAddTo: StringName

## Maintains a counter and stops spawning nodes when the maximum number is reached.
## NOTE: Does NOT monitor the deletion of previous nodes; so the counter never decreases. Use [member maximumLimitInGroup] to maintain a specific amount of nodes currently in the scene.
## If this value is -1 or any other negative number, then it is ignored. CAUTION: Spawning nodes infinitely will eventually cause system slowdown and a crash.
## Supercedes [member maximumLimitInGroup]
@export var maximumTotalToSpawn: int = -1

## Stops spawning nodes if [member groupToAddTo] has the specified amount of members.
## If this value is -1 or any other negative number, then it is ignored. CAUTION: Spawning nodes infinitely will eventually cause system slowdown and a crash.
## NOTE: [member maximumTotalToSpawn] supercedes this value and is checked first.
@export var maximumLimitInGroup: int = -1

## Use for non-rectangular areas. If `true`, each randomly generated position is tested to ensure that it is inside the shape.
## This may be a slower process than choosing a random position within a simple rectangle.
# @export var shouldVerifyWithinArea := false # TODO: Cannot check if a point is within an area :( [as of 4.3 Dev 3]

@export var isEnabled: bool = true
@export var shouldShowDebugInfo: bool = false
#endregion


#region State
@onready var spawnAreaShapeNode: CollisionShape2D = %SpawnAreaShape

var totalNodesSpawned: int
#region


#region Signals
signal didSpawn(newSpawn: Node2D, parent: Node2D)
#endregion


func onSpawnTimer_timeout() -> void:
	spawn()


## Returns: The newly spawned node
func spawn() -> Node2D:
	if not isEnabled: return null

	# Validate

	# <0 is ignored
	if maximumTotalToSpawn >= 0 \
	and totalNodesSpawned >= maximumTotalToSpawn:
		if shouldShowDebugInfo: Debug.printDebug(str("totalNodesSpawned: ", totalNodesSpawned, " >= maximumTotalToSpawn: ", maximumTotalToSpawn), self)
		return null

	# <0 is ignored
	if maximumLimitInGroup >= 0 \
	and not groupToAddTo.is_empty():
		var groupCount: int = self.get_tree().get_node_count_in_group(groupToAddTo)
		if groupCount >= maximumLimitInGroup:
			if shouldShowDebugInfo: Debug.printDebug(str("maximumLimitInGroup: ", maximumLimitInGroup, " >= nodes in ", groupToAddTo, ": ", groupCount), self)
			return null

	if not sceneToSpawn:
		Debug.printWarning("No sceneToSpawn", self)
		return

	# Load & position

	var sceneResource   := load(sceneToSpawn.resource_path)
	var newSpawn: Node2D = sceneResource.instantiate()

	newSpawn.position = Tools.getRandomPositionInArea(self)

	# Add the new node to the parent

	var parent: Node

	if not parentOverride:
		parent = self
	else:
		parent = parentOverride
		# Transform the child coordinates to the global space.
		newSpawn.global_position = self.to_global(newSpawn.position)

	# Let the game-specific subclasses of [PopulateArea], if any, customize the new copies.

	if validateNewNode(newSpawn, parent):

		if not groupToAddTo.is_empty():
			newSpawn.add_to_group(groupToAddTo, true)

		parent.add_child(newSpawn)
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
