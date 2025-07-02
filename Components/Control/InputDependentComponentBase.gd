## Abstract base class for components whose functionality is dependent on player inout or AI control provided by an [InputComponent] or one of its subclasses.
## IMPORTANT: [method _ready] MUST be called via `super._ready()` if overridden in a subclass.
## TIP: Components where input control is optional such as [PlatformerPhysicsComponent], or components that don't have to handle all input signals, do not need to inherit from this class.
## Requirements: BEFORE (above) [InputComponent] or its subclasses, because input events propagate from the BOTTOM of the Scene Tree nodes list UPWARD.

@abstract class_name InputDependentComponentBase
extends Component


#region Dependencies
@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent)

func getRequiredComponents() -> Array[Script]:
	return [InputComponent]
#endregion


## IMPORTANT: MUST be called via super._ready() to setup signals
func _ready() -> void:
	# DESIGN: _enter_tree() cannot be used because components that depend on InputComponent may enter the tree before InputComponent
	if inputComponent:
		Tools.connectSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput)
		Tools.connectSignal(inputComponent.didUpdateInputActionsList, self.onInputComponent_didUpdateInputActionsList)
	else:
		printError(str("Missing InputComponent in ", parentEntity.logFullName)) # If a component inherits this class then it means so a missing dependency is an ERROR!


#region Abstract Methods

## Astract, optional; To be implemented in subclasses.
@warning_ignore("unused_parameter")
func onInputComponent_didUpdateInputActionsList(event: InputEvent) -> void:
	pass


## Astract; MUST be implemented in subclasses.
@abstract func onInputComponent_didProcessInput(event: InputEvent) -> void # TBD: Make optional?

#endregion