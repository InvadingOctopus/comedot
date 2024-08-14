## Moves the parent entity to chase after another [Node2D].
## NOTE: characterBodyComponent.shouldResetVelocityIfZeroMotion = false
## Requirements: BEFORE [OverheadPhysicsComponent]


class_name ChaseComponent
extends CharacterBodyManipulatingComponentBase

# TODO: Implement friction slowdown
# TBD:  Manipulate existing Control components?


#region Parameters
@export var nodeToChase: Node2D

@export_range(10, 1000, 5) var speed: float = 300

@export var applyAcceleration: bool = false
@export_range(10, 1000, 5) var acceleration: float = 800

@export var isEnabled: bool = true
#endregion


#region State
var recentChaseDirection: Vector2
#endregion


#region Dependencies
var overheadPhysicsComponent: OverheadPhysicsComponent:
	get:
		if not overheadPhysicsComponent: overheadPhysicsComponent = self.getCoComponent(OverheadPhysicsComponent)
		return overheadPhysicsComponent

func getRequiredComponents() -> Array[Script]:
	return [OverheadPhysicsComponent] + super.getRequiredComponents()
#endregion


func _ready() -> void:
	if not characterBodyComponent.shouldResetVelocityIfZeroMotion:
		printLog("characterBodyComponent.shouldResetVelocityIfZeroMotion = false")
		characterBodyComponent.shouldResetVelocityIfZeroMotion = false


func _physics_process(_delta: float) -> void:
	# THANKS: GDQuest@YouTube https://www.youtube.com/watch?v=GwCiGixlqiU

	# Check for presence of self and target to account for destroyed entities.
	if not isEnabled or not self.body or not nodeToChase: return

	self.recentChaseDirection = parentEntity.global_position.direction_to(nodeToChase.global_position).normalized()
	overheadPhysicsComponent.inputDirection = self.recentChaseDirection
	
	# characterBodyComponent.queueMoveAndSlide() # Unneeded; will be called by OverheadPhysicsComponent
	if shouldShowDebugInfo: showDebugInfo()


func showDebugInfo() -> void:
	if not shouldShowDebugInfo: return
	Debug.watchList[str("\n— ", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.chaseVector = self.recentChaseDirection
