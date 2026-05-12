## A subclass of [InteractionControlComponent] that allows performing an interaction with the mouse.
## IMPORTANT: Requires the [member CollisionObject2D.input_pickable] flag on [InteractionComponent]'s [Area2D],
## and the `physics/common/enable_object_picking` Godot project setting.
## IMPORTANT: Controls interaction with specific objects under the mouse cursor via a specific mouse button, the Left Mouse Button by default;
## [InteractionControlComponent] still controls interaction with ALL objects in range via the [member GlobalInput.Actions.interact] input action, the Right Mouse Button by default.
## @experimental

class_name InteractionMouseControlComponent
extends InteractionControlComponent

# TBD: Should this just be part of [InteractionControlComponent] or [InteractionComponent]?
# TRIED: The mouse cursor updates are too complicated and confusing to manage from the interactor's side.

# PERFORMANCE: Code duplication from InteractionControlComponent to improve performance by reducing calls.
# This may improve responsiveness in mouse position event handling.


#region Parameters
## The mouse button to use for interacting with a specific [InteractionComponent] object under the mouse cursor, via the Left Mouse Button by default.
## IMPORTANT: This is DIFFERENT from the [member GlobalInput.Actions.interact] input action, which is handled by [InteractionControlComponent] to interact with ALL objects in range, via the Right Mouse Button by default.
@export var mouseButton: MouseButton = MouseButton.MOUSE_BUTTON_LEFT

## Changes the mouse pointer to a hand when hovering over an interactive object within range.
## @experimental
@export var shouldUpdateCursor: bool = true
#endregion


#region Area Events

## Handles collisions with [InteractionComponent]
func onCollide(collidingNode: Node2D) -> void:
	# PERFORMANCE: Duplicating code from InteractionControlComponent to avoid calling super and recasting
	var interactionComponent: InteractionComponent = collidingNode.get_node(^".") as InteractionComponent # HACK: Find better way to cast self?
	if not interactionComponent: return
	if debugMode: printDebug(str("onCollide(): ", collidingNode, ", interactionComponent: ", interactionComponent.logNameWithEntity, ", isAutomatic: ", interactionComponent.isAutomatic))

	connectAreaSignals(collidingNode as Area2D, interactionComponent)
	updateIndicator()
	didEnterInteractionArea.emit(interactionComponent.entity, interactionComponent)
	# Cursor will be updated by onInteractionComponent_mouseEntered()


## Handles collisions with [InteractionComponent]
func onExit(exitingNode: Node2D) -> void:
	# PERFORMANCE: Duplicating code from InteractionControlComponent to avoid calling super and recasting
	# NOTE: Exits should not check isEnabled to ensure cleanups are always performed.
	var interactionComponent: InteractionComponent = exitingNode.get_node(^".") as InteractionComponent # HACK: Find better way to cast self?
	if not interactionComponent: return
	if debugMode: printDebug(str("onCollide(): ", exitingNode, ", interactionComponent: ", interactionComponent.logNameWithEntity, ", isAutomatic: ", interactionComponent.isAutomatic))

	disconnectAreaSignals(exitingNode as Area2D)
	updateIndicator()
	if shouldUpdateCursor and areasInContact.is_empty(): Input.set_default_cursor_shape(Input.CURSOR_ARROW) # Reset cursor if we walked away from all interactive objects
	didExitInteractionArea.emit(interactionComponent.entity, interactionComponent)


func connectAreaSignals(interactionArea: Area2D, interactionComponent: InteractionComponent) -> void:
	Tools.connectSignal(interactionArea.mouse_entered, self.onInteractionComponent_mouseEntered.bind(interactionComponent))
	Tools.connectSignal(interactionArea.mouse_exited,  self.onInteractionComponent_mouseExited.bind(interactionComponent))
	Tools.connectSignal(interactionArea.input_event,   self.onInteractionComponent_inputEvent.bind(interactionComponent))
	# TBD: PERFORMANCE: BUGRISK: interactionArea.input_pickable = true


func disconnectAreaSignals(interactionArea: Area2D) -> void:
	# CHECK: Do we need to bind the method arguments to disconnect previously bound methods with `.bind(interactionComponent)`?
	# TBD: PERFORMANCE: BUGRISK: interactionArea.input_pickable = false
	var interactionComponent: InteractionComponent = interactionArea.get_node(^".") as InteractionComponent
	Tools.disconnectSignal(interactionArea.mouse_entered, self.onInteractionComponent_mouseEntered.bind(interactionComponent))
	Tools.disconnectSignal(interactionArea.mouse_exited,  self.onInteractionComponent_mouseExited.bind(interactionComponent))
	Tools.disconnectSignal(interactionArea.input_event,   self.onInteractionComponent_inputEvent.bind(interactionComponent))


func disconnectAllAreaSignals() -> void:
	for interactionComponent in areasInContact:
		if not is_instance_of(interactionComponent, InteractionComponent): continue # Just in case
		self.disconnectAreaSignals(interactionComponent.area)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_UNPARENTED: disconnectAllAreaSignals()

#endregion


#region Mouse Events

## @experimental
func onInteractionComponent_mouseEntered(interactionComponent: InteractionComponent) -> void:
	if not self.isEnabled: return
	if debugMode: interactionComponent.emitDebugBubble("MOUSE IN", self.randomDebugColor, false, self.debugMode)
	if shouldUpdateCursor and not areasInContact.is_empty(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func onInteractionComponent_inputEvent(_viewport: Node, event: InputEvent, _shape_idx: int, interactionComponent: InteractionComponent) -> void:
	# IMPORTANT: DESIGN: There are 2 types of mouse interaction buttons:
	# 1: The global "interact" Input Action which defaults to the Right Mouse Button and "E" key etc. and triggers InteractionControlComponent.interactAll() for ALL interactions in range.
	# 2: The Left Button which is only for interacting with a SPECIFIC object under the mouse cursor, implemented here.

	if not self.isEnabled \
	or event is not InputEventMouseButton \
	or event.button_index != self.mouseButton \
	or not interactionComponent.isEnabled:
		return

	if event.pressed:
		self.interact(interactionComponent)
		self.get_viewport().set_input_as_handled()
		# TODO: Animate on mouse button press.


## @experimental
func onInteractionComponent_mouseExited(interactionComponent: InteractionComponent) -> void:
	# NOTE: Exits should not depend on isEnabled
	if debugMode: interactionComponent.emitDebugBubble("MOUSE OUT", self.randomDebugColor, false, self.debugMode)
	if shouldUpdateCursor: Input.set_default_cursor_shape(Input.CURSOR_ARROW)

#endregion
