## Creates a node when the parent entity "dies", by monitoring a [HealthComponent].
## The spawned node may be a collectible object such as a gold coin, or a cosmetic node such as a gravestone sprite.

class_name DropOnDeathComponent
extends Component


#region Parameters

@export var sceneToSpawnOnDeath: PackedScene

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

@onready var healthComponent: HealthComponent = coComponents.HealthComponent # TBD: Static or dynamic?

var parentForSpawnedNode: Node2D:
	get:
		if parentOverrideForSpawnedNode: return parentOverrideForSpawnedNode
		else: return parentEntity.get_parent()

#endregion


func _ready() -> void:
	if not healthComponent:
		printError("Missing HealthComponent")
		return

	healthComponent.healthDidZero.connect(self.onHealthComponent_healthDidZero)


func onHealthComponent_healthDidZero() -> void:
	# TBD: No need to spawn a "drop" if the parent entity doesn't "die" (get removed upon zero health) right?
	if not isEnabled or not healthComponent.shouldRemoveEntityOnZero: return
	drop()


## Creates and returns the [sceneToSpawnOnDeath] ands it as a child of the specified parent.
## This is a separate method so that custom death handling components may call it without depending on [HealthComponent] signals.
func drop() -> Node:
	# Translate the parent entity's position to the coordinate space of parent of the spawned node,
	# and add the offset.
	var position: Vector2 = parentForSpawnedNode.to_local(parentEntity.global_position) + positionOffset

	var spawnedNode := SceneManager.addSceneInstance(sceneToSpawnOnDeath, parentForSpawnedNode, position)
	
	if spawnedNode != null:
		didDrop.emit(spawnedNode)
		return spawnedNode
	else:
		printWarning(str("Cannot instantiate sceneToSpawnOnDeath: ", sceneToSpawnOnDeath))
		return null

