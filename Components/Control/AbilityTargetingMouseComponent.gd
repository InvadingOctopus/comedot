## Presents a mouse-controlled cursor and other UI for the player to choose a target for an [Ability].
## The [Ability] may be a special skill or magic spell etc. such as "Fireball", which may be targeted anywhere,
## or it may be an explicit command like "Talk" or "Examine" which requires the target to be an [Entity] with an [AbilityTargetableComponent].
## @experimental

class_name AbilityTargetingMouseComponent
extends AbilityTargetingCursorComponentBase


func _ready() -> void:
	super._ready()
	cursor.global_position = entity.get_global_mouse_position()


func _process(_delta: float) -> void:
	if not isEnabled or not isChoosing: return
	cursor.global_position = entity.get_global_mouse_position()


func _unhandled_input(event: InputEvent) -> void:
	# NOTE: CHECK: Cancellations will be handled by `AbilityTargetingComponentBase._input()` if this event is unhandled, right?
	if not isEnabled or event is not InputEventMouseButton: return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): # TBD: Use "just pressed"?
		chooseTargetsUnderCursor()
		self.get_viewport().set_input_as_handled()
