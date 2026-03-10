## A subclass of [InteractionComponent] specialized for doors or teleporters etc.
## [member payload] may be used to require a key etc. or be omitted via [member allowNoPayload]

class_name PortalInteractionComponent
extends InteractionComponent


#region Parameters
## The node where the player will exit from after interacting with this portal.
@export var destinationNode: Node2D
#endregion


func requestToInteract(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	return super.requestToInteract(interactorEntity, interactionControlComponent) \
		and is_instance_valid(destinationNode)


func onDidPerformInteraction(interactorEntity: Entity, result: Variant) -> void:
	if Tools.checkResult(result) or (allowNoPayload and not payload):
		interactorEntity.global_position = destinationNode.global_position
