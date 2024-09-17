## A door or teleporter.

class_name PortalInteractionComponent
extends InteractionComponent


#region Parameters
## The node where the player will exit from after interacting with this portal.
@export var destinationNode: Node2D
#endregion


## Returns the updated [member Ndoe2D.global_position] of the interactor [Entity].
@warning_ignore("unused_parameter")
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> Vector2:
	interactorEntity.global_position = destinationNode.global_position
	return interactorEntity.global_position
