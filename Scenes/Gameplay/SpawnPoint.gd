## Wraps a [Spawner] to create copies of specified Scenes at a specific position.
## IMPORTANT: Enable "Editable Children" and edit the [Spawner] child node to choose the scene to instantiate and modify spawn parameters.
## TIP: The [Spawner] script may be replaced with [SpawnerRandom] or [SpawnerList] etc.
## TIP: Add a [Timer] & connect [signal Timer.timeout] → [method Spawner.spawn] to create repeated spawns at regular intervals.
## TIP: See [SpawnArea] or [SpawnEdge] to spawn at random positions inside broad regions.

class_name SpawnPoint
extends Marker2D


#region State
@onready var spawner: Spawner = $Spawner
#region


func onSpawner_willAddSpawn(newSpawn: Node2D, parent: Node) -> void:
	# If we're the parent, just spawn at wherever this SpawnPoint is
	if parent == self:
		newSpawn.position = Vector2.ZERO

	# If the parent is a different Node2D, convert our position to that node's space
	elif is_instance_of(parent, Node2D):
		# NOTE: Node2D.to_global() / .to_local() will not work if nodes are in different canvas coordinate spaces,
		# so we use other methods to allow using [CanvasLayer] to keep a [SpawnPoint] fixed at an edge of the screen etc.
		# PERFORMANCE: Inlining NodeTools.convertPosition() to avoid an extra call
		newSpawn.position = parent.make_canvas_position_local(self.get_global_transform_with_canvas() * Vector2.ZERO)

	# If the parent is a plain Node (e.g. for grouping) or Control, just place the spawn at whatever this SpawnPoint's position is (and hope for the best?)
	else:
		newSpawn.position = self.global_position
