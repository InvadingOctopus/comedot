## Displays debugging information about the entity and other sibling components.

class_name DebugComponent
extends BodyComponent


func _physics_process(delta: float):
	%PositionLabel.text = str("@:", parentEntity.position, "\n@G:", parentEntity.global_position)
	%VelocityLabel.text = str("V:", body.velocity)
	
