## Displays a UI control and pauses the parent entity.
## This component is not affected by pausing; the [member Node.process_mode] should be [constant Node.PROCESS_MODE_ALWAYS].

class_name ModalInteractionComponent
extends InteractionComponent


#region Parameters
@export var uiToDisplay: ModalUI
#endregion


#region Signals
signal didSomethingHappen ## Placeholder
#endregion


## NOTE: Subclasses MUST call `super.performInteraction(...)`
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> void:
	parentEntity.pause
	pass
