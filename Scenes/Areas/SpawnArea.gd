## Creates copies of the specified scene at a random position on regular intervals.
## Currently only optimized for rectangular area shapes.

class_name SpawnArea
extends Area2D


#region Parameters

@export var sceneToSpawn: PackedScene

## The parent node to add the new spawns to. If `null`, the spawns will be added as children of this area.
@export var parentOverride: Node2D

## An optional group to add the spawned nodes to.
@export var addToGroup: StringName

## Use for non-rectangular areas. If `true`, each randomly generated position is tested to ensure that it is inside the shape.
## This may be a slower process than choosing a random position within a simple rectangle.
# @export var shouldVerifyWithinArea := false # TODO: Cannot check if a point is within an area :( [as of 4.3 Dev 3]

@export var isEnabled := true

#endregion


#region Signals
signal didSpawn(newSpawn: Node2D, parent: Node2D)
#endregion


@onready var spawnAreaShapeNode: CollisionShape2D = %SpawnAreaShape


func onSpawnTimer_timeout():
	spawn()


func spawn():

	if not isEnabled: return

	if not sceneToSpawn:
		Debug.printError("No sceneToSpawn", str(self))
		return

	var sceneResource   := load(sceneToSpawn.resource_path)
	var newSpawn: Node2D = sceneResource.instantiate()

	newSpawn.position = Global.getRandomPositionInArea(self)

	# Add the new node to the parent

	var parent: Node2D

	if not parentOverride:
		parent = self
	else:
		parent = parentOverride
		# Transform the child coordinates to the global space.
		newSpawn.global_position = self.to_global(newSpawn.position)

	# Let the game-specific subclasses of [PopulateArea], if any, customize the new copies.

	if validateNewNode(newSpawn, parent):

		if not addToGroup.is_empty():
			newSpawn.add_to_group(addToGroup, true)

		parent.add_child(newSpawn)
		newSpawn.owner = parent # INFO: Necessary for persistence to a [PackedScene] for save/load.
		didSpawn.emit(newSpawn, parent)
	else:
		return


## A method for sublasses to override. Prepares newly spawned node with further game-specific logic.
## May suppress the creation of a newly spawned node by checking additional conditions and returning `false`.
func validateNewNode(newSpawn: Node2D, parent: Node2D) -> bool:
	return isEnabled
