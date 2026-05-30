## Clamps the position of the parent entity to within a specified maximum distance/radius (in any direction) of another node.

class_name TetherComponent
extends Component

# TBD: Rename to AnchorComponent?


#region Parameters

@export var anchorNode: Node2D ## The "anchor" to tether the position of this component's parent entity to.
@export_range(0, 2000, 8) var maximumDistance: float = 96 ## The maximum radius the [member anchorNode] can be before this component's parent entity is moved.

@export var shouldRepositionImmediately: bool = true
@export var shouldUseInputComponent:	 bool = false ## If `true` then [member InputComponent.movementDirection] is modified instead of setting the entity's position directly. Effective only if not [member shouldRepositionImmediately].
@export_range(0, 1000, 4) var speed:	float = 96:  ## Effective only if not [member shouldRepositionImmediately].
	set(newValue):
		if newValue != speed:
			speed = newValue
			self.set_process(isEnabled and not is_zero_approx(speed))

@export var isEnabled:	bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process(isEnabled and not is_zero_approx(speed))

#endregion


#region Dependencies
@onready var inputComponent: InputComponent = getCoComponent(InputComponent, true, false) # findSubclasses, not warnIfMissing # Optional; include subclasses to allow AI etc.
#endregion


func _ready() -> void:
	self.set_process(isEnabled and not is_zero_approx(speed)) # Apply setter because Godot doesn't on initialization


func _process(delta: float) -> void:
	var offset: Vector2 = NodeTools.clampPositionToAnchor(entity, anchorNode, maximumDistance)
	if shouldRepositionImmediately:
		entity.global_position += offset
	else:
		if shouldUseInputComponent and inputComponent:
			inputComponent.setMovementDirection(offset.normalized(), Vector2.ONE, false) # Ignore scale to maintain exact visual distance, not shouldNormalize # Also updates related axes
		else:
			entity.global_position = entity.global_position.move_toward(entity.global_position + offset, speed * delta)

	entity.reset_physics_interpolation() # CHECK: Necessary?
