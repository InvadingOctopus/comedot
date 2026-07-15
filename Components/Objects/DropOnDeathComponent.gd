## Creates a randomly chosen scene instance when the entity "dies", by monitoring a [HealthComponent]
## The spawned node may be a [CollectibleComponent] [Entity] representing objects such as a gold coin, or a basic cosmetic [Sprite2D] such as a gravestone sprite, or even spawn new ghost monsters etc!

class_name DropOnDeathComponent
extends Component


#region Parameters

## A [Dictionary] of scene paths and their "relative weights" used for randomly choosing which scene to spawn.
## EXAMPLE: `{ "res://Common.tscn": 3.0, "res://Rare.tscn": 1.0 }` = 75% chance for Common, 25% for Rare
## NOTE: Entries with weights <= 0 are ignored.
@export var scenesToSpawnOnDeath: Dictionary[String, float]

## Offsets the spawned node's position in relation to the [Entity]'s position in the entity's parent.
@export var positionOffset: Vector2 = Vector2.ZERO

## The node to add the spawned node as a child of.
## If `null`, the parent node of the parent [Entity] will be used.
@export var parentOverrideForSpawnedNode: Node2D

@export var isEnabled: bool = true

#endregion


#region Signals
signal didDrop(node: Node)
#endregion


#region State

@onready var healthComponent: HealthComponent = getCoComponent(HealthComponent, true) # findSubclasses

var parentForSpawnedNode: Node2D:
	get:
		if parentOverrideForSpawnedNode: return parentOverrideForSpawnedNode
		else: return entity.get_parent()

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


## Randomly chooses a scene path from [member scenesToSpawnOnDeath], instantiates a copy of it, and adds it as a child of the specified parent.
## This is a separate method so that custom death-handling components may call it directly without depending on [HealthComponent] signals.
func drop() -> Node:
	# NOTE: Print warnings only in debug mode, because `scenesToSpawnOnDeath` may be empty on purpose during certain gameplay conditions etc.

	if scenesToSpawnOnDeath.is_empty():
		if debugMode: printWarning("drop(): `scenesToSpawnOnDeath` is empty")
		return null

	var scenePath: String = Tools.pickRandomFromWeightsDictionary(scenesToSpawnOnDeath, "") as String
	if  scenePath.is_empty():
		if debugMode: printWarning("drop(): `scenesToSpawnOnDeath` has no positive weights or returned an empty path")
		return null

	# Translate the parent entity's position to the coordinate space of parent of the spawned node,
	# then add the offset.
	var position: Vector2 = parentForSpawnedNode.to_local(entity.global_position) + positionOffset
	var spawnedNode := SceneManager.loadSceneAndAddInstance(scenePath, parentForSpawnedNode, position)
	
	if is_instance_valid(spawnedNode):
		didDrop.emit(spawnedNode)
		return spawnedNode
	else:
		printWarning(str("drop() cannot instantiate scene from `scenesToSpawnOnDeath` path: ", scenePath))
		return null
