## Allows the player to interact with an [InteractionComponent].
## "Interactions" are similar to "Collectibles"; the difference is that an interaction occurs on a button input instead of automatically on a collision.
## Requirements: The component node must be an [Area2D]

class_name InteractionControlComponent
extends CooldownComponent

# TODO: Update indicator only on collision events.


#region Parameters

@export var interactionIndicator: Node ## A [Node2D] or [Control] to display when this [InteractionControlComponent] is within the range of an [InteractionComponent].

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue
		if selfAsArea:
			selfAsArea.monitorable = isEnabled
			selfAsArea.monitoring  = isEnabled
			updateIndicator()
			
#endregion


#region State

var interactionsInRange: Array[InteractionComponent]

var haveInteracionsInRange: bool:
	get: return self.interactionsInRange.size() >= 1

var selfAsArea: Area2D:
	get:
		if not selfAsArea: selfAsArea = self.get_node(".") as Area2D
		return selfAsArea

#endregion


#region Signals
signal didEnterInteractionArea(entity: Entity, interactionComponent: InteractionComponent)
signal didExitInteractionArea (entity: Entity, interactionComponent: InteractionComponent)
signal willBeginInteraction   (entity: Entity, interactionComponent: InteractionComponent)
#endregion


func _ready() -> void:
	# Set the initial state of the indicator
	if interactionIndicator:
		interactionIndicator.visible = false
		updateIndicator()


func onArea_entered(area: Area2D) -> void:
	var interactionComponent: InteractionComponent = area.get_node(".") as InteractionComponent # HACK: TODO: Find better way to cast
	if not interactionComponent: return

	Debug.printDebug(self.logName + " onArea_entered: " + str(interactionComponent))

	self.interactionsInRange.append(interactionComponent)
	updateIndicator()
	didEnterInteractionArea.emit(interactionComponent.parentEntity, interactionComponent)


func onArea_exited(area: Area2D) -> void:
	var interactionComponent: InteractionComponent = area.get_node(".") as InteractionComponent # HACK: TODO: Find better way to cast
	if not interactionComponent: return

	Debug.printDebug(self.logName + " onArea_exited: " + str(interactionComponent))

	self.interactionsInRange.erase(interactionComponent)
	updateIndicator()
	didExitInteractionArea.emit(interactionComponent.parentEntity, interactionComponent)


func updateIndicator() -> void:
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


# DEBUG: func _process(delta: float) -> void:
	# DEBUG: showDebugInfo()


func showDebugInfo():
	var watchName: StringName  = str(self, ":Timer")
	Debug.watchList[watchName] = self.cooldownTimer.time_left


#region Cooldown

func startCooldown(overrideTime: float = self.cooldown):
	super.startCooldown(overrideTime)
	# Reduce the alpha
	if interactionIndicator: interactionIndicator.modulate.a = 0.1


func finishCooldown():
	super.finishCooldown()
	# Restore the alpha
	if interactionIndicator: interactionIndicator.modulate.a = 1.0

#endregion
