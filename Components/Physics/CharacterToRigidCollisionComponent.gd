## Allows a [CharacterBody2D] to push [RigidBody2D]s.
## NOTE: This component should be processed AFTER all components which call `CharacterBody2D.move_and_slide()`
class_name CharacterToRigidCollisionComponent
extends CharacterBodyManipulatingComponentBase

# CREDIT: KidsCanCode@YouTube https://www.youtube.com/watch?v=SJuScDavstM


#region Parameters
@export_range(10.0, 100.0, 10.0) var pushingForce: float = 100.0
#endregion


func _physics_process(delta: float):
	for collisionIndex in body.get_slide_collision_count():
		var collision: KinematicCollision2D = body.get_slide_collision(collisionIndex)
		if collision.get_collider() is RigidBody2D:
			collision.get_collider().apply_central_impulse(-collision.get_normal() * pushingForce)
