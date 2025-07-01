## Main Menu Buttons Template/Example

#class_name MainMenu
extends Control


func _input(event: InputEvent) -> void: # Need to Grab all input to prevent pausing, so we can't use _unhandled_input()
	# Reassert unpausability as long as the Main Menu is onscreen, to workaround SceneManager resetting the flag.
	GlobalInput.isPauseShortcutAllowed = false
	if event.is_action(GlobalInput.Actions.pause): self.get_viewport().set_input_as_handled()


func onStartButton_pressed() -> void:
	GameState.startMainScene()


func onQuitButton_longPressed() -> void:
	quit()


func quit() -> void:
	Debug.printLog("Auf Wiedersehen Monty!", "")
	get_tree().quit()
