## The Pause Button
## NOTE: The [member Node.process_mode] should be [constant Node.ProcessMode.PROCESS_MODE_ALWAYS] so that the button can remain interactive while the gameplay is paused.

extends Button


func _ready() -> void:
	updateState()


func updateState() -> void:
	var isScenePaused: bool = self.get_tree().paused
	self.button_pressed = isScenePaused
	
	
	# TBD: The Great Conundrum: Should the visual of a toggle-able control represent the CURRENT state or the NEXT state that will happen upon using the control?
	# i.e. Should the Pause Button show the "PLAY >" icon when it's PAUSED? or should it show the "PAUSED ||" icon?
	if self.button_pressed:
		self.text = ">"
		self.tooltip_text = "UNPAUSE"
		self.modulate = Color(0.5, 1, 0.5)
	else:
		self.text = "||"
		self.tooltip_text = "PAUSE"
		self.modulate = Color(1, 1, 0.5)


func onToggled(toggled_on: bool) -> void:
	SceneManager.setPause(toggled_on)
	updateState()


