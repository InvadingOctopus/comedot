## Provides player control input to an [OverheadPhysicsComponent].
## Requirements: BEFORE [OverheadPhysicsComponent] & [CharacterBodyComponent]

class_name OverheadControlComponent
extends Component


#region Parameters
@export var modifierScale: Vector2 = Vector2(1, 1) ## A modifier to multiply the player input by, where (1, 1) is normal control, and negative values invert an axis.
@export var isEnabled: bool = true
#endregion


#region Dependencies
@onready var overheadPhysicsComponent: OverheadPhysicsComponent = coComponents.OverheadPhysicsComponent # Required

func getRequiredComponents() -> Array[Script]:
	return [OverheadPhysicsComponent]
#endregion


func _physics_process(_delta: float) -> void: # TBD: CHECK: Should this be `_physics_process()` or `_process()`?
	if not isEnabled: return

	overheadPhysicsComponent.inputDirection = Input.get_vector(
		GlobalInput.Actions.moveLeft,
		GlobalInput.Actions.moveRight,
		GlobalInput.Actions.moveUp,
		GlobalInput.Actions.moveDown) * modifierScale # TBD: CHECK: PERFORMANCE


# func _input(event: InputEvent) -> void:
#	if not isEnabled or not event.is_action_type(): return
# 	# TBD: PERFORMANCE: Handle inputs here only when an input occurs?
#	# DESIGN: Use _physics_process() instead of _input() so that components are processed in order of the scene tree.
