## Provides player control input to an [OverheadPhysicsComponent].
## Requirements: BEFORE [OverheadPhysicsComponent] & [CharacterBodyComponent]

class_name OverheadControlComponent
extends Component


#region Parameters
@export var isEnabled: bool = true
#endregion


#region State
#endregion


#region Dependencies
@onready var overheadPhysicsComponent: OverheadPhysicsComponent = coComponents.OverheadPhysicsComponent # TBD: Static or dynamic?

func getRequiredComponents() -> Array[Script]:
	return [OverheadPhysicsComponent]
#endregion


# func _input(_event: InputEvent) -> void:
# 	if not isEnabled: return
# 	# TBD: PERFORMANCE: Handle inputs here only when an input occurs?


func _physics_process(_delta: float) -> void: # TBD: CHECK: Should this be `_physics_process()` or `_process()`?
	if not isEnabled: return
	overheadPhysicsComponent.inputDirection = Input.get_vector(
		GlobalInput.Actions.moveLeft,
		GlobalInput.Actions.moveRight,
		GlobalInput.Actions.moveUp,
		GlobalInput.Actions.moveDown)
