## An [Area2D] which displays a highlight or other effects when the mouse cursors enters it.
## TIP: Extend this script with a subclass to add more functionality.

class_name MouseHoverArea
extends Area2D


#region Parameters
@export var isEnabled: bool = true: ## Also effects [member Area2D.monitorable] and [member Area2D.monitoring]
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.monitorable = isEnabled
			self.monitoring  = isEnabled
			self.input_pickable = isEnabled
			updateSignals()
#endregion


func _ready() -> void:
	updateSignals()


func updateSignals() -> void:
	if isEnabled: connectMouseSignals()
	else: disconnectMouseSignals()


func connectMouseSignals() -> void:
	if not self.mouse_entered.is_connected(setHover.bind(true)):
		self.mouse_entered.connect(setHover.bind(true))

	if not self.mouse_exited.is_connected(setHover.bind(false)):
		self.mouse_exited.connect(setHover.bind(false))


func disconnectMouseSignals() -> void:
	if self.mouse_entered.is_connected(setHover.bind(true)):
		self.mouse_entered.disconnect(setHover.bind(true))

	if self.mouse_exited.is_connected(setHover.bind(false)):
		self.mouse_exited.disconnect(setHover.bind(false))


func setHover(isHovering: bool = true) -> void:
	self.modulate = Color.YELLOW if isHovering else Color.WHITE
