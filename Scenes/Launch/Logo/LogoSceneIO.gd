## The Invading Octopus Logo~

class_name LogoSceneIO
extends Start


func _ready() -> void:
	super._ready()
	animateLogo()


func animateLogo() -> void:
	const gameFrameScene: PackedScene = preload("res://Scenes/Launch/GameFrame.tscn")
	await Animations.tweenProperty(self, ^"modulate", Color(0,0,0,0), 3.0).finished
	Global.transitionToScene(gameFrameScene)
