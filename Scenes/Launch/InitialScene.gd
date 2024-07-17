## The "master" initial scene launched by Godot. Displays the logo and coordinates transitions between game-specific scenes.

class_name CoordinatorScene
extends Node2D


#region Parameters

## The main game-specific scene to load and display after the logos.
@export var mainGameScene: PackedScene

@export_custom(PROPERTY_HINT_EXPRESSION, "test") var payload: Expression

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
	Global.removeAllChildren(gameScenePlaceholder)

#endregion

func _ready() -> void:
	await startLogoScene()
	startMainScene()


func startLogoScene() -> void:
	willStartLogoScene.emit()
	pass
	didEndLogoScene.emit()


func startMainScene() -> void:
	willStartMainScene.emit()
	displaySubscene(mainGameScene)


