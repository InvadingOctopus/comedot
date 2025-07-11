## Presents a mouse-controlled cursor and other UI for the player to choose a target for an [Action].
## The [Action] may be a special skill or magic spell etc. such as "Fireball", which may be targeted anywhere,
## or it may be an explicit command like "Talk" or "Examine" which requires the target to be an [Entity] with an [ActionTargetableComponent].
## @experimental

class_name ActionTargetingMouseComponent
extends ActionTargetingCursorComponentBase


func _ready() -> void:
	super._ready()
	cursor.global_position = parentEntity.get_global_mouse_position()


func _process(_delta: float) -> void:
	if not isEnabled or not isChoosing: return
	cursor.global_position = parentEntity.get_global_mouse_position()


func _input(event: InputEvent) -> void:
	if event is not InputEventMouseButton: return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): # TBD: Use "just pressed"?
		chooseTargetsUnderCursor()
