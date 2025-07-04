## Automatically hides the entity or another chosen node when there is no movement input, and re-shows the node when there is movement input.
## Requirements: BEFORE [InputComponent]

class_name HideWhenStationaryComponent
extends Component

# TODO: Add autohide on no MOTION (difference in position)
# TBD: Better name?


#region Parameters
const animationDuration: float = 0.5
@export var nodeToHide:  CanvasItem ## If not specified, the parent entity is used.
@export var shouldHideOnReady: bool = true
@export var isEnabled:		   bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			if self.is_node_ready():
				if isEnabled: hidingTimer.start()
				else:		  hidingTimer.stop()
#endregion


#region State
@onready var hidingTimer: Timer = self.get_node(^".") as Timer
var tween: Tween
#endregion


#region Dependencies
@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent)

func getRequiredComponents() -> Array[Script]:
	return [InputComponent]
#endregion


func _ready() -> void:
	if not nodeToHide: nodeToHide = parentEntity

	if isEnabled:
		if shouldHideOnReady: nodeToHide.visible = false
		else: hidingTimer.start()

	Tools.connectSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput)
	Tools.connectSignal(inputComponent.didToggleMouseSuppression, self.onInputComponent_didToggleMouseSuppression)


#region Input

func onInputComponent_didProcessInput(event: InputEvent) -> void:
	# TODO: Ignore joysticks that don't cause any movement.
	# Stay visible while there is movement input.
	if  (not nodeToHide.visible or not hidingTimer.is_stopped()) \
	and (not inputComponent.movementDirection.is_zero_approx() \
		or not inputComponent.aimDirection.is_zero_approx()
		or (event is InputEventMouseButton and event.is_pressed())):
			show()


func onInputComponent_didToggleMouseSuppression(shouldSuppressMouse: bool) -> void:
	self.set_process_input(isEnabled and not shouldSuppressMouse) # Enable mouse motion event checking


func _input(event: InputEvent) -> void:
	# Did the mouse move?
	if event is InputEventMouseMotion and not nodeToHide.visible or not hidingTimer.is_stopped():
		show()

#endregion


#region Visibility

func show() -> void:
	# TBD: Animate?

	# Halt any ongoing hiding animation
	if not hidingTimer.is_stopped(): hidingTimer.stop()
	if tween: tween.kill()

	# Just modify the alpha of the current modulate to maintain the tint
	nodeToHide.modulate = Color(nodeToHide.modulate, 1.0)
	nodeToHide.visible  = true

	# PERFORMANCE: Start the disappearance countdown immediately, so we don't have to keep rechecking for input
	hidingTimer.start()


func hide() -> void:
	if tween: tween.kill()
	tween = nodeToHide.create_tween()

	# Just modify the alpha of the current modulate to maintain the tint
	tween.tween_property(nodeToHide, "modulate", Color(nodeToHide.modulate, 0), animationDuration)
	tween.tween_property(nodeToHide, "visible",  false, 0)


func onTimeout() -> void:
	if isEnabled: hide()

#endregion
