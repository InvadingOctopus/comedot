## A door or teleporter.

class_name PortalInteractionComponent
extends InteractionComponent


#region Parameters
## The node where the player will exit from after interacting with this portal.
@export var destinationNode: Node2D
#endregion


func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent):
	interactorEntity.global_position = destinationNode.global_position
