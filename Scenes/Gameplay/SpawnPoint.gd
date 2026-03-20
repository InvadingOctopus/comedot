## Uses a [SpawnTimer] to creates copies of the specified Scene at a specific position on regular intervals.
## IMPORTANT: Enable "Editable Children" and edit the [SpawnTimer] child node to choose which scene to copy and modify spawn parameters.

class_name SpawnPoint
extends Marker2D


#region State
@onready var spawnTimer: SpawnTimer = $SpawnTimer
#region


func onSpawnTimer_willAddSpawn(newSpawn: Node2D, parent: Node) -> void:
	# If we're the parent, just spawn at wherever this SpawnPoint is
	if parent == self: newSpawn.position = Vector2.ZERO

	# If the parent is a different Node2D, convert our position to that node's space
	elif is_instance_of(parent, Node2D): newSpawn.position = parent.to_local(self.global_position)

	# If the parent is a plain Node (e.g. for grouping) or Control, just place the spawn at whatever this SpawnPoint's position is (and hope for the best?)
	else: newSpawn.position = self.global_position
