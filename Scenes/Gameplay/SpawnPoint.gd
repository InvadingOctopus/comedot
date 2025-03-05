## Uses a [SpawnTimer] to creates copies of the specified Scene at a specific position on regular intervals.
## IMPORTANT: Enable "Editable Children" and edit the [SpawnTimer] child node to choose which scene to copy and modify spawn parameters.

class_name SpawnPoint
extends Marker2D


#region State
@onready var spawnTimer: SpawnTimer = $SpawnTimer
#region


func onSpawnTimer_didSpawn(newSpawn: Node2D, _parent: Node2D) -> void:
	newSpawn.position = self.position
