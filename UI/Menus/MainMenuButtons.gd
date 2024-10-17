#class_name MainMenu
extends Control


var didSetInitialFocus: bool = false


func setInitialFocus() -> void:
	if not didSetInitialFocus:
		$StartButton.grab_focus()
		didSetInitialFocus = true


func _input(event: InputEvent) -> void: # TBD: Use `_unhandled_input()`
	if not didSetInitialFocus and event is InputEventAction:
		setInitialFocus()
		self.get_viewport().set_input_as_handled()


func onStartButton_pressed() -> void:
	startGame()


func startGame() -> void:
	if not Settings.mainGameScene:
		Debug.printError("Settings.mainGameScene not set!")
		return
		
	var mainGameScene: PackedScene = load(Settings.mainGameScene.resource_path)
	Global.transitionToScene(mainGameScene)


func onQuitButton_pressed() -> void:
	quit()


func quit() -> void:
	Debug.printLog("Auf Wiedersehen, Monty!")
	get_tree().quit()
