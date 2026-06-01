# meta-default: true

## Description
## Requirements: [Does this component depend on other components? Or does it need the parent Entity to be a specific type of node?]

class_name _CLASS_
extends Component


#region Parameters
@export_range(0, 100, 10) var speed: float = 100 ## PLACEHOLDER
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process(isEnabled) # PERFORMANCE: Set once instead of every frame
#endregion


#region State
var property: int ## PLACEHOLDER
#endregion


#region Signals
signal didSomethingHappen ## PLACEHOLDER
#endregion


#region Dependencies
# WARNING: "Memoization" (caching the reference) may cause bugs if a component is removed from the entity later.

@onready var coComponent:	 Component		= coComponents.Component ## PLACEHOLDER
@onready var inputComponent: InputComponent	= getCoComponent(InputComponent, true) # findSubclasses

## Returns a list of required component types that this component depends on.
func getRequiredComponents() -> Array[Script]:
	return [InputComponent]

#endregion


func _ready() -> void:
	# PLACEHOLDER: Add any code needed to configure and prepare the component.
	# Apply setters because Godot doesn't on _ready()
	self.set_process(isEnabled)
	# PLACEHOLDER: Remove signals if input is not needed.
	Tools.connectSignal(inputComponent.didUpdateMovementDirection, self.onInputComponent_didUpdateMovementDirection)
	Tools.connectSignal(inputComponent.didUpdateInputActionsList,	self.onInputComponent_didUpdateInputActionsList)


func onInputComponent_didUpdateMovementDirection(movementDirection: Vector2, difference: Vector2) -> void:
	if not isEnabled: return
	pass # PLACEHOLDER: Remove if input is not needed.


func onInputComponent_didUpdateInputActionsList(event: InputEvent) -> void:
	if not isEnabled: return
	pass # PLACEHOLDER: Handle one-shot input events such as jumping or firing.


func _process(delta: float) -> void: # NOTE: If you need to process movement or collisions, use `_physics_process()`
	if not isEnabled: return
	pass # PLACEHOLDER: Perform any per-frame updates.
