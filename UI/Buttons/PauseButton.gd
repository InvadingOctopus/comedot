## A Pause/Unpause Button
## NOTE: The [member Node.process_mode] should be [constant Node.ProcessMode.PROCESS_MODE_ALWAYS] so that the button can remain interactive while the gameplay is paused.

# class_name PauseButton # Unnecessary
extends Button


func _ready() -> void:
	updateState()
	SceneManager.didSetPause.connect(self.onSceneManager_didSetPause) # NOTE: Cannot use `NOTIFICATION_PAUSED` because this button should be unpausable.


func onToggled(toggled_on: bool) -> void:
	SceneManager.setPause(toggled_on)
	# updateState() will be called by onSceneManager_didSetPause()


func onSceneManager_didSetPause(_isPaused: bool) -> void:
	updateState()


func updateState() -> void:
	var isScenePaused: bool = SceneManager.sceneTree.paused if SceneManager.sceneTree else true # TBD: Count as paused if no SceneTree?
	self.set_pressed_no_signal(isScenePaused) # NOTE: set_pressed_no_signal() to avoid triggering onToggled()

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
