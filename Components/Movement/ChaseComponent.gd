class_name ChaseComponent
extends BodyComponent


@export var nodeToFollow: Node2D

@export_range(10.0,   1000.0, 5.0)  var speed: float        = 300.0

@export var applyAcceleration := false
@export_range(10.0,   1000.0, 5.0)  var acceleration: float = 800.0

# TODO: Implement friction slowdown


func _physics_process(delta: float):
	# CREDIT: GDQuest@YouTube https://www.youtube.com/watch?v=GwCiGixlqiU

	# Check for presence of self and target to account for destroyed entities.
	if not self.body or not nodeToFollow: return

	var direction: Vector2 = parentEntity.global_position.direction_to(nodeToFollow.global_position)

	if applyAcceleration:
		self.body.velocity = body.velocity.move_toward(direction * speed, acceleration * delta)
	else:
		self.body.velocity = direction * speed

	parentEntity.callOnceThisFrame(body.move_and_slide)
