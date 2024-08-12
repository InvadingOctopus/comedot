## Moves the parent entity to chase after another [Node2D].

class_name ChaseComponent
extends CharacterBodyManipulatingComponentBase

# TODO: Implement friction slowdown
# TBD:  Manipulate existing Control components?


#region Parameters

@export var nodeToChase:						Node2D

@export_range(10, 1000, 5) var speed:			float = 300

@export var applyAcceleration:					bool  = false
@export_range(10, 1000, 5) var acceleration:	float = 800

@export var isEnabled:							bool = true

#endregion


func _physics_process(delta: float) -> void:
	# CREDIT: GDQuest@YouTube https://www.youtube.com/watch?v=GwCiGixlqiU

	if not isEnabled: return

	# Check for presence of self and target to account for destroyed entities.
	if not self.body or not nodeToChase: return

	var direction: Vector2 = parentEntity.global_position.direction_to(nodeToChase.global_position)

	if applyAcceleration:
		self.body.velocity = body.velocity.move_toward(direction * speed, acceleration * delta)
	else:
		self.body.velocity = direction * speed

	characterBodyComponent.queueMoveAndSlide()
