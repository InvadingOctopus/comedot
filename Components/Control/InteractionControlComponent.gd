## Allows the player to interact with an [InteractionComponent].
## "Interactions" are similar to "Collectibles". The difference is that an interaction occurs on a button input instead of automatically on a collision.

class_name InteractionControlComponent
extends CooldownComponent

# TODO: Update indicator only on collision events.


#region Parameters
@export var interactionIndicator: Node ## A [Node2D] or [Control] to display when this [InteractionControlComponent] is within the range of an [InteractionComponent].
@export var isEnabled := true
#endregion


#region Signals
signal didEnterInteractionArea(entity: Entity, interactionComponent: InteractionComponent)
signal didExitInteractionArea (entity: Entity, interactionComponent: InteractionComponent)
signal willBeginInteraction   (entity: Entity, interactionComponent: InteractionComponent)
#endregion


var interactionsInRange: Array[InteractionComponent]

var haveInteracionsInRange: bool:
	get: return self.interactionsInRange.size() >= 1


func onArea_entered(area: Area2D) -> void:
	var interactionComponent: InteractionComponent = area.get_node(".") as InteractionComponent # HACK: TODO: Find better way to cast
	if not interactionComponent: return

	Debug.printDebug(self.logName + " onArea_entered: " + str(interactionComponent))

	self.interactionsInRange.append(interactionComponent)
	didEnterInteractionArea.emit(interactionComponent.parentEntity, interactionComponent)


func onArea_exited(area: Area2D) -> void:
	var interactionComponent: InteractionComponent = area.get_node(".") as InteractionComponent # HACK: TODO: Find better way to cast
	if not interactionComponent: return

	Debug.printDebug(self.logName + " onArea_exited: " + str(interactionComponent))

	self.interactionsInRange.erase(interactionComponent)
	didExitInteractionArea.emit(interactionComponent.parentEntity, interactionComponent)


func _process(delta: float): # TBD: Should this be in the physics loop?
	# TODO: Update indicator only on collision events.
	if interactionIndicator: 
		interactionIndicator.visible = isEnabled and haveInteracionsInRange


func _input(event: InputEvent):
	if not isEnabled or not hasCooldownCompleted or not haveInteracionsInRange: return

	if Input.is_action_just_pressed("interact"): interact()


func interact():
	# NOTE: TBD: If there are multiple interactions within range,
	# should they all be processed withing a single cooldown?
	# Or should the first one start the cooldown, causing the other interactions to fail?

	if not hasCooldownCompleted: return

	for interactionComponent in self.interactionsInRange:
		if interactionComponent.requestToInteract(self.parentEntity, self):
			willBeginInteraction.emit(interactionComponent.parentEntity, interactionComponent)
			interactionComponent.performInteraction(self.parentEntity, self)

	startCooldown()


#region Cooldown

func startCooldown():
	super.startCooldown()
	if interactionIndicator: interactionIndicator.modulate = Color(Color.WHITE, 0.1)


func finishCooldown():
	super.finishCooldown()
	if interactionIndicator: interactionIndicator.modulate = Color.WHITE

#endregion
