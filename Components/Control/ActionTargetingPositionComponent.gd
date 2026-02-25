## Presents a joystick/mouse-controlled cursor and other UI for the player to choose a target for an [Action].
## The [Action] may be a special skill or magic spell etc. such as "Fireball", which may be targeted anywhere,
## or it may be an explicit command like "Talk" or "Examine" which requires the target to be an [Entity] with an [ActionTargetableComponent].
## TIP: An [InputComponent] may be used to resolve exclusivity between joystick vs. mouse control.
## @experimental

class_name ActionTargetingPositionComponent
extends ActionTargetingCursorComponentBase

# TODO: Implement joystick/keyboard support (and without InputComponent?)


#region Parameters
@export_range(0, 1000, 8) var joystickSpeed:				float = 320
@export_range(0, 1000, 8) var maximumDistanceFromEntity:	float ## The maximum distance for the targeting cursor when controlling with a gamepad joystick.
#endregion


#region Dependencies
@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent) # Optional
#endregion


func _ready() -> void:
	super._ready()
	if is_zero_approx(maximumDistanceFromEntity):
		maximumDistanceFromEntity = cursor.get_viewport_rect().size.y
	# Set the initial position to the mouse pointer, unless an InputComponent suppressed the mouse
	if not inputComponent or not inputComponent.shouldSuppressMouseMotion:
		cursor.global_position = parentEntity.get_global_mouse_position()
	if inputComponent: Tools.connectSignal(inputComponent.didToggleMouseSuppression, self.onInputComponent_didToggleMouseSuppression)


func onInputComponent_didToggleMouseSuppression(shouldSuppressMouse: bool) -> void:
	self.set_process_unhandled_input(not shouldSuppressMouse)


func _process(delta: float) -> void:
	if not isEnabled or not isChoosing: return
	# Fallback to mouse if there is no InputComopnent
	if inputComponent and inputComponent.shouldSuppressMouseMotion:
		cursor.global_position += inputComponent.aimDirection * joystickSpeed * delta
		cursor.global_position += Tools.clampPositionToAnchor(cursor, parentEntity, maximumDistanceFromEntity)
	else:
		cursor.global_position = parentEntity.get_global_mouse_position()


func _unhandled_input(event: InputEvent) -> void:
	# NOTE: CHECK: Cancellations will be handled by `ActionTargetingComponentBase._input()` if this event is unhandled, right?
	if not isEnabled or event is not InputEventMouseButton: return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): # TBD: Check "just pressed"?
		chooseTargetsUnderCursor()
		self.get_viewport().set_input_as_handled()
