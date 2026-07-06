## Uses a [SpawnTimer] to creates copies of the specified Scene at a random position within an [Area2D] on regular intervals.
## Currently only optimized for rectangular area shapes.
## IMPORTANT: Enable "Editable Children" and edit the [SpawnTimer] child node to choose which scene to copy and modify spawn parameters.

class_name SpawnArea
extends Area2D


#region Parameters
## Use for non-rectangular areas. If `true`, each randomly generated position is tested to ensure that it is inside the shape.
## This may be a slower process than choosing a random position within a simple rectangle.
## @experimental
# @export var shouldVerifyWithinArea: bool = false # TODO: Cannot check if a point is within an area :( [as of 4.3 Dev 3]
#endregion


#region State
@onready var spawnTimer: SpawnTimer = $SpawnTimer
@onready var spawnAreaShape: CollisionShape2D = $SpawnAreaShape
#region


func onSpawnTimer_willAddSpawn(newSpawn: Node, parent: Node) -> void:
	# If spawning directly inside this Area2D just get a random position in local coordinates
	if parent == self: newSpawn.position = AreaTools.getRandomPositionInAreaBounds(self)

	# If the parent is a different Node2D, convert a random position inside this Area2D to that other node's local space
	elif is_instance_of(parent, Node2D): newSpawn.position = parent.to_local(self.to_global(AreaTools.getRandomPositionInAreaBounds(self)))

	# If the parent is a plain Node (e.g. for grouping) or Control, just place the spawn at a random position in this Area2D's coordinate space (and hope for the best?)
	else: newSpawn.position = self.to_global(AreaTools.getRandomPositionInAreaBounds(self))
