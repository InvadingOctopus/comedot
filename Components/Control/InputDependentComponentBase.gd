## Abstract base class for components whose functionality is dependent on player inout or AI control provided by an [InputComponent] or one of its subclasses.
## Requirements: BEFORE (above) [InputComponent] or its subclasses, because input events propagate from the BOTTOM of the Scene Tree nodes list UPWARD.

abstract class_name InputDependentComponentBase
extends Component


#region Dependencies
var inputComponent: InputComponent

func getRequiredComponents() -> Array[Script]:
	return [InputComponent]
#endregion


func _enter_tree() -> void:
	# DESIGN: Do common setup in _enter_tree() so subclasses can use _ready() without having to call super._ready()
	super._enter_tree()
	inputComponent = parentEntity.findFirstComponentSubclass(InputComponent) # Include subclasses
	if inputComponent:
		Tools.connectSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput)
		Tools.connectSignal(inputComponent.didUpdateInputActionsList, self.onInputComponent_didUpdateInputActionsList)
	else:
		printWarning(str("Missing InputComponent in ", parentEntity))


#region Abstract Methods

## Astract, optional; To be implemented in subclasses.
func onInputComponent_didUpdateInputActionsList() -> void:
	pass


## Astract; MUST be implemented in subclasses.
abstract func onInputComponent_didProcessInput(event: InputEvent) -> void # TBD: Make optional?

#endregion