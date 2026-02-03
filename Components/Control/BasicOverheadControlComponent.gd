## Adjusts the entity's position by the player input on every frame.
## The entity node can be any subtype of [CanvasItem] or [Node2D].
## TIP: A simple standalone alternative to [CharacterBody2D] + [OverheadPhysicsComponent] + [InputComponent].
## Helpful for quick testing/prototyping.

class_name BasicOverheadControlComponent
extends Component

# TBD: Should the name be "SimpleControlComponent" or something?


#region Parameters

# Setters: # Don't bother checking for a change
# PERFORMANCE: Toggle _process() to avoid per-frame updates if not needed

## May be a negative value to invert the player control.
@export_range(-1000, 1000, 10) var speed: float = 100:
	set(newValue):
		isEnabled = newValue
		set_process(isEnabled and not is_zero_approx(speed))

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue 
		set_process(isEnabled and not is_zero_approx(speed))

#endregion


func _ready() -> void:
	set_process(isEnabled and not is_zero_approx(speed)) # Apply setters because Godot doesn't on initialization


func _process(delta: float) -> void: # TBD: Use _physics_process() or _process()?
	parentEntity.position += Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown) * speed * delta
