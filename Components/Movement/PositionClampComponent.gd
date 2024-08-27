## Restricts the global position of the parent [Entity] each frame.
class_name PositionClampComponent
extends Component

# CREDIT: Heartbeast@YouTube https://www.youtube.com/watch?v=zUeLesdL7lE


@export var minimum: Vector2 = Vector2.ZERO
@export var maximum: Vector2 = Vector2(500, 500)


func _process(_delta: float) -> void:
	parentEntity.position.clamp(minimum, maximum)
	print("SCRIPT ONLY WORKING") # DEBUG
