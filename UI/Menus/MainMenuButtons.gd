#class_name MainMenu
extends Control


func onStartButton_pressed() -> void:
	startGame()


func startGame() -> void:
	if not Global.mainGameScene:
		Debug.printError("Global.mainGameScene not set!")
		return
		
	var mainGameScene: PackedScene = load(Global.mainGameScene.resource_path)
	Global.transitionToScene(mainGameScene)


func onQuitButton_pressed() -> void:
	quit()


func quit() -> void:
	Debug.printLog("Auf Wiedersehen, Monty!")
	get_tree().quit()
