## Uses a [SpawnTimer] to creates copies of the specified Scene at a specific position on regular intervals.
## IMPORTANT: Enable "Editable Children" and edit the [SpawnTimer] child node to choose which scene to copy and modify spawn parameters.

class_name SpawnPoint
extends Marker2D


#region State
@onready var spawnTimer: SpawnTimer = $SpawnTimer
#region


func onSpawnTimer_willAddSpawn(newSpawn: Node2D, parent: Node2D) -> void:
	newSpawn.position = parent.to_local(self.global_position)
