## A prototype for a "master" initial scene that contains other scenes. Displays the logo and coordinates transitions between game-specific scenes.
## @experimental

class_name CoordinatorScene
extends Start


#region Parameters
#endregion


#region State
@onready var gameScenePlaceholder: Node2D = %GameScenePlaceholder
#endregion


#region Signals
signal willStartLogoScene
signal didEndLogoScene
signal willStartMainScene
#endregion


#region Sub-Scene Functions

## Returns: The new scene instance.
func displaySubscene(scene: PackedScene) -> Node2D:
	clearScenePlaceholder()

	var newSceneInstance := scene.instantiate()
	gameScenePlaceholder.add_child(newSceneInstance)
	return newSceneInstance


func clearScenePlaceholder() -> void:
	Tools.removeAllChildren(gameScenePlaceholder)

#endregion


#region Launch Sequence

func _ready() -> void:
	super._ready()

	@warning_ignore("redundant_await")
	await startLogoScene() # TBD: await or not?
	startMainScene()


## @experimental
func startLogoScene() -> void:
	willStartLogoScene.emit()
	const logoScene := preload("res://Scenes/Launch/Logo/IOLogoScene.tscn")
	displaySubscene(logoScene)
	# TODO: await logoScene.didFinish
	didEndLogoScene.emit()


func startMainScene() -> void:
	var mainGameScene: PackedScene = load(mainGameScenePath)
	if not mainGameScene:
		Debug.printWarning("Cannot load mainGameScenePath: " + mainGameScenePath)
		return

	willStartMainScene.emit()
	displaySubscene(mainGameScene)

#endregion
