## Clamps the position of the parent entity to within a specified maximum distance/radius (in any direction) of another node.

class_name TetherComponent
extends Component

# TBD: Rename to AnchorComponent?


#region Parameters

@export var anchorNode: Node2D ## The "anchor" to tether the position of this component's parent entity to.
@export_range(0.0, 2000.0, 8.0) var maximumDistance: float = 96 ## The maximum radius the [member anchorNode] can be before this component's parent entity is moved.

@export var shouldRepositionImmediately: bool = true
@export var shouldUseInputComponent:	 bool = false ## If `true` then [member InputComponent.movementDirection] is modified instead of setting the entity's position directly. Effective only if not [member shouldRepositionImmediately].
@export_range(0, 1000, 5) var speed:	float = 100:  ## Effective only if not [member shouldRepositionImmediately].
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
@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent) # Optional
#endregion


func _ready() -> void:
	self.set_process(isEnabled and not is_zero_approx(speed)) # Apply setter because Godot doesn't on initialization


func _process(delta: float) -> void:
	var offset: Vector2 = Tools.clampPositionToAnchor(parentEntity, anchorNode, maximumDistance)
	if shouldRepositionImmediately:
		parentEntity.global_position += offset
	else:
		if shouldUseInputComponent and inputComponent:
			inputComponent.movementDirection = offset.normalized()
		else:
			parentEntity.global_position = parentEntity.global_position.move_toward(parentEntity.global_position + offset, speed * delta)

	parentEntity.reset_physics_interpolation() # CHECK: Necessary?
