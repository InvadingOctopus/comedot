## Creates a node when the parent entity "dies", by monitoring a [HealthComponent].
## The spawned node may be a collectible object such as a gold coin, or a cosmetic node such as a gravestone sprite.

class_name DropOnDeathComponent
extends Component


#region Parameters

@export var nodeToSpawnOnDeath: PackedScene

## Offsets the spawned node's position in relation to the [Entity]'s position in the entity's parent.
@export var positionOffset: Vector2 = Vector2.ZERO

## The node to add the spawned node as a child of.
## If `null`, the parent node of the parent [Entity] will be used]
@export var parentOverrideForSpawnedNode: Node2D

@export var isEnabled: bool = true

#endregion


#region Signals
signal didDrop(node: Node2D)
#endregion


#region State

var healthComponent: HealthComponent:
	get: return self.findCoComponent(HealthComponent)

var parentForSpawnedNode: Node2D:
	get:
		if parentOverrideForSpawnedNode:
			return parentOverrideForSpawnedNode
		else:
			return parentEntity.get_parent()

#endregion


func _ready():
	if not healthComponent:
		printError("Missing HealthComponent")
		return

	healthComponent.healthDidZero.connect(self.onHealthComponent_healthDidZero)


func onHealthComponent_healthDidZero():
	# TBD: No need to spawn a "drop" if the parent entity doesn't "die" (get removed upon zero health) right?
	if not isEnabled or not healthComponent.shouldRemoveParentOnZero: return

	# Translate the parent entity's position to the coordinate space of parent of the spawned node,
	# and add the offset.
	var position: Vector2 = parentForSpawnedNode.to_local(parentEntity.global_position) + positionOffset

	var spawnedNode := Global.addSceneInstance(nodeToSpawnOnDeath, parentForSpawnedNode, position)
	didDrop.emit(spawnedNode)
