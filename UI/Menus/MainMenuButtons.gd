## Main Menu Buttons Template/Example

#class_name MainMenu
extends Control

func _enter_tree() -> void:
	GlobalInput.isPauseShortcutAllowed = false # Doesn't make sense to pause during the Main Menu


func onStartButton_pressed() -> void:
	GameState.startMainScene()


func onQuitButton_longPressed() -> void:
	quit()


func quit() -> void:
	Debug.printLog("Auf Wiedersehen Monty!", "")
	get_tree().quit()
