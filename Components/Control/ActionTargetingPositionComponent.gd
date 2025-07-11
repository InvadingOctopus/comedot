## Presents a joystick/mouse-controlled cursor and other UI for the player to choose a target for an [Action].
## The [Action] may be a special skill or magic spell etc. such as "Fireball", which may be targeted anywhere,
## or it may be an explicit command like "Talk" or "Examine" which requires the target to be an [Entity] with an [ActionTargetableComponent].
## An [InputComponent] may be used to resolve exclusivity between joystick vs. mouse control.
## @experimental

class_name ActionTargetingPositionComponent
extends ActionTargetingCursorComponentBase


#region Parameters
@export_range(0.0, 1000.0, 10.0) var joystickSpeed:				float = 300
@export_range(0.0, 1000.0, 10.0) var maximumDistanceFromEntity:	float ## The maximum distance for the targeting cursor when controlling with a gamepad joystick.
#endregion


#region Dependencies
@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent) # Optional
#endregion


func _ready() -> void:
	super._ready()
	if is_zero_approx(maximumDistanceFromEntity):
		maximumDistanceFromEntity = cursor.get_viewport_rect().size.y
	if inputComponent:
		if not inputComponent.shouldSuppressMouseMotion:
			cursor.global_position = parentEntity.get_global_mouse_position()
		Tools.connectSignal(inputComponent.didToggleMouseSuppression, self.onInputComponent_didToggleMouseSuppression)


func onInputComponent_didToggleMouseSuppression(shouldSuppressMouse: bool) -> void:
	self.set_process_unhandled_input(not shouldSuppressMouse)


func _process(delta: float) -> void:
	if not isEnabled or not isChoosing: return
	if inputComponent:
		if inputComponent.shouldSuppressMouseMotion:
			cursor.global_position += inputComponent.aimDirection * joystickSpeed * delta
			cursor.global_position += Tools.clampPositionToAnchor(cursor, parentEntity, maximumDistanceFromEntity)
		else:
			cursor.global_position = parentEntity.get_global_mouse_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton: return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): # TBD: Use "just pressed"?
		chooseTargetsUnderCursor()
