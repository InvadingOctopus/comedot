## A prototype for a component which displays debugging information about the entity and sibling components.

class_name DebugComponent
extends Component


func _ready():
	parentEntity.getBody()


func _physics_process(delta: float):
	if parentEntity.body:
		%VelocityLabel.text = str(parentEntity.body.velocity)
