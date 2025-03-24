## Uses a [SpawnTimer] to creates copies of the specified Scene at a random position within an [Area2D] on regular intervals.
## Currently only optimized for rectangular area shapes.
## IMPORTANT: Enable "Editable Children" and edit the [SpawnTimer] child node to choose which scene to copy and modify spawn parameters.

class_name SpawnArea
extends Area2D


#region Parameters

## Use for non-rectangular areas. If `true`, each randomly generated position is tested to ensure that it is inside the shape.
## This may be a slower process than choosing a random position within a simple rectangle.
# @export var shouldVerifyWithinArea := false # TODO: Cannot check if a point is within an area :( [as of 4.3 Dev 3]

#endregion


#region State
@onready var spawnTimer: SpawnTimer = $SpawnTimer
@onready var spawnAreaShapeNode: CollisionShape2D = %SpawnAreaShape
#region


func onSpawnTimer_willAddSpawn(newSpawn: Node2D, parent: Node2D) -> void:
	if parent == self: newSpawn.position = Tools.getRandomPositionInArea(self)
	else: newSpawn.position = parent.to_local(Tools.getRandomPositionInArea(self))
