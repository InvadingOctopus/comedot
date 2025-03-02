## Moves the parent entity to chase after another [Node2D] by manipulating the entity's [member OverheadPhysicsComponent.inputDirection].
## Speed, acceleration and friction are determined by the [OverheadPhysicsComponent] and its [OverheadMovementParameters].
## NOTE: Set [member CharacterBodyComponent.shouldResetVelocityIfZeroMotion] to `false`
## TIP:  For more complex pathfinding based on Godot's Navigation nodes, use [NavigationComponent]
## Requirements: BEFORE [OverheadPhysicsComponent]

class_name ChaseComponent
extends CharacterBodyDependentComponentBase


#region Parameters

## If not specified and [member shouldChasePlayerIfUnspecified], then the first [PlayerEntity] from [member GameState.players] will be chased.
@export var nodeToChase: Node2D

## If `true` amd [member nodeToChase] is `null`, the first [PlayerEntity] from [member GameState.players] will be chased.
@export var shouldChasePlayerIfUnspecified: bool = true

@export var isEnabled: bool = true

#endregion


#region State
var recentChaseDirection: Vector2
#endregion


#region Dependencies
@onready var overheadPhysicsComponent: OverheadPhysicsComponent = coComponents.OverheadPhysicsComponent # TBD: Static or dynamic?

func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent, OverheadPhysicsComponent] # Cannot easily join with `super.getRequiredComponents()` :(
#endregion


func _ready() -> void:
	if not characterBodyComponent.shouldResetVelocityIfZeroMotion:
		printLog("characterBodyComponent.shouldResetVelocityIfZeroMotion = false")
		characterBodyComponent.shouldResetVelocityIfZeroMotion = false

	if not nodeToChase and shouldChasePlayerIfUnspecified:
		nodeToChase = GameState.players.front()


func _physics_process(_delta: float) -> void:
	# THANKS: GDQuest@YouTube https://www.youtube.com/watch?v=GwCiGixlqiU

	# Check for presence of self and target to account for destroyed entities.
	if not isEnabled or not self.body or not nodeToChase: return

	self.recentChaseDirection = parentEntity.global_position.direction_to(nodeToChase.global_position).normalized()
	overheadPhysicsComponent.inputDirection = self.recentChaseDirection

	# characterBodyComponent.queueMoveAndSlide() # Unneeded; will be called by OverheadPhysicsComponent
	if debugMode: showDebugInfo()


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList[str("\n— ", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.chaseVector = self.recentChaseDirection
