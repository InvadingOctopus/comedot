# meta-default: true

## Description
## Requirements: [Does this component depend on other components? Or does it need the parent Entity to be a specific type of node?]

class_name _CLASS_
extends Component


#region Parameters
@export_range(0, 100, 10) var speed: float = 100 ## Placeholder
@export var isEnabled: bool = true
#endregion


#region State
var property: int ## Placeholder
#endregion


#region Signals
signal didSomethingHappen ## Placeholder
#endregion


#region Dependencies

var coComponent: Component = self.coComponents.Component ## Placeholder # WARNING: "Memoization" (caching the reference) may cause bugs if a new component of the same type is later added to the entity.

## Returns a list of required component types that this component depends on.
func getRequiredComponents() -> Array[Script]:
	return []

#endregion


func _ready() -> void:
	pass # Placeholder: Add any code needed to configure and prepare the component.


func _input(event: InputEvent) -> void:
	if not isEnabled: return
	pass # Placeholder: Handle one-shot input events such as jumping or firing.


func _process(delta: float) -> void: # NOTE: If you need to process movement or collisions, use `_physics_process()`
	if not isEnabled: return
	pass # Placeholder: Perform any per-frame updates.
