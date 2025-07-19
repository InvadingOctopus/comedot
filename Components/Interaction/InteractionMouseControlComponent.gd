## A subclass of [InteractionControlComponent] that allows performing an interaction with the mouse.
## IMPORTANT: Requires the [member CollisionObject2D.input_pickable] flag on [InteractionComponent]'s [Area2D],
## and the `physics/common/enable_object_picking` Godot project setting.
## @experimental

class_name InteractionMouseControlComponent
extends InteractionControlComponent

# TBD: Should this just be part of [InteractionControlComponent] or [InteractionComponent]?

# PERFORMANCE: Code duplication from InteractionControlComponent to improve performance by reducing calls.
# This may improve responsiveness in mouse position event handling.


#region Area Events

func onArea_entered(area: Area2D) -> void:
	if not isEnabled: return
	var interactionComponent: InteractionComponent = area.get_node(^".") as InteractionComponent # HACK: Find better way to cast self?
	if not interactionComponent: return

	printDebug(self.logName + " onArea_entered: " + str(interactionComponent))

	self.interactionsInRange.append(interactionComponent)
	connectAreaSignals(area, interactionComponent)
	updateIndicator()
	didEnterInteractionArea.emit(interactionComponent.parentEntity, interactionComponent)


func onArea_exited(area: Area2D) -> void:
	# NOTE: Exits should not check isEnabled to ensure cleanups are always performed.
	var interactionComponent: InteractionComponent = area.get_node(^".") as InteractionComponent # HACK: Find better way to cast self?
	if not interactionComponent: return

	printDebug(self.logName + " onArea_exited: " + str(interactionComponent))

	self.interactionsInRange.erase(interactionComponent)
	disconnectAreaSignals(area)
	updateIndicator()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	didExitInteractionArea.emit(interactionComponent.parentEntity, interactionComponent)


func connectAreaSignals(area: Area2D, interactionComponent: InteractionComponent) -> void:
	Tools.connectSignal(area.mouse_entered, self.onInteractionComponent_mouseEntered.bind(interactionComponent))
	Tools.connectSignal(area.mouse_exited,  self.onInteractionComponent_mouseExited.bind(interactionComponent))
	Tools.connectSignal(area.input_event,   self.onInteractionComponent_inputEvent.bind(interactionComponent))


func disconnectAreaSignals(area: Area2D) -> void:
	Tools.disconnectSignal(area.mouse_entered, self.onInteractionComponent_mouseEntered)
	Tools.disconnectSignal(area.mouse_exited,  self.onInteractionComponent_mouseExited)
	Tools.disconnectSignal(area.input_event,   self.onInteractionComponent_inputEvent)


func disconnectAllAreaSignals() -> void:
	for interactionComponent in interactionsInRange:
		self.disconnectAreaSignals(interactionComponent.selfAsArea)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_UNPARENTED: disconnectAllAreaSignals()

#endregion


#region Mouse Events

func onInteractionComponent_mouseEntered(interactionComponent: InteractionComponent) -> void:
	if not self.isEnabled: return
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	if debugMode: interactionComponent.emitDebugBubble("MOUSE IN", self.randomDebugColor, false, self.debugMode)


func onInteractionComponent_inputEvent(_viewport: Node, event: InputEvent, _shape_idx: int, interactionComponent: InteractionComponent) -> void:
	if not self.isEnabled: return
	if event is not InputEventMouseButton or not interactionComponent.isEnabled: return
	# DESIGN: Interact only on mouse button RELEASE.
	# TODO: Animate on mouse button press.
	if event.is_released():
		self.interact(interactionComponent)


func onInteractionComponent_mouseExited(interactionComponent: InteractionComponent) -> void:
	# NOTE: Exits should not depend on isEnabled
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if debugMode: interactionComponent.emitDebugBubble("MOUSE OUT", self.randomDebugColor, false, self.debugMode)

#endregion


