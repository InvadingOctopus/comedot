## Provides player control input to an [OverheadPhysicsComponent].
## Requirements: BEFORE [OverheadPhysicsComponent]

class_name OverheadControlComponent
extends Component


#region Parameters
@export var isEnabled: bool = true
#endregion


#region State
#endregion


#region Dependencies

var overheadPhysicsComponent: OverheadPhysicsComponent:
	get:
		if not overheadPhysicsComponent: overheadPhysicsComponent = self.getCoComponent(OverheadPhysicsComponent)
		return overheadPhysicsComponent

## Returns a list of required component types that this component depends on.
func getRequiredcomponents() -> Array[Script]:
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

