## Presents a mouse-controlled cursor and other UI for the player to choose a target for an [Action].
## The [Action] may be a special skill or magic spell etc. such as "Fireball", which may be targeted anywhere,
## or it may be an explicit command like "Talk" or "Examine" which requires the target to be an [Entity] with an [ActionTargetableComponent].
## @experimental

class_name ActionTargetingMouseComponent
extends ActionTargetingCursorComponentBase


func _ready() -> void:
	super._ready()
	self.global_position = parentEntity.get_global_mouse_position()


func _process(_delta: float) -> void:
	if not isEnabled or not isChoosing: return
	self.global_position = parentEntity.get_global_mouse_position()


func _input(event: InputEvent) -> void:
	if event is not InputEventMouseButton: return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): # TBD: Use "just pressed"?
		chooseTargetsUnderCursor()


func chooseTargetsUnderCursor() -> Array[ActionTargetableComponent]:
	# TODO: Set limits on concurrent targets

	# If there are no eligible targets, the selection should be cancelled
	if self.actionTargetableComponentInContact.is_empty():
		super.cancelTargetSelection()
		return []

	var chosenTargets: Array[ActionTargetableComponent]
	for target in self.actionTargetableComponentInContact:
		self.chooseTarget(target)
		chosenTargets.append(target)
	self.requestDeletion()
	return chosenTargets
