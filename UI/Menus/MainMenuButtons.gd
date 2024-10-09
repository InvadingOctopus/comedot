#class_name MainMenu
extends Control


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
