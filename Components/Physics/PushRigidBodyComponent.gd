## Allows a [CharacterBody2D] to push [RigidBody2D]s.
## NOTE: This component should be processed AFTER all other components which call [method CharacterBody2D.move_and_slide]

class_name PushRigidBodyComponent
extends CharacterBodyDependentComponentBase

# CREDIT: KidsCanCode@YouTube https://www.youtube.com/watch?v=SJuScDavstM


#region Parameters
@export_range(10.0, 100.0, 10.0) var pushingForce: float = 100.0
@export var isEnabled: bool = true
#endregion


func _physics_process(_delta: float) -> void:
	if not isEnabled: return
	for collisionIndex in body.get_slide_collision_count():
		var collision: KinematicCollision2D = body.get_slide_collision(collisionIndex)
		var collider:  RigidBody2D = collision.get_collider() as RigidBody2D
		if collider: collider.apply_central_impulse(-collision.get_normal() * pushingForce)
