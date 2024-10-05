## The Invading Octopus Logo~

class_name LogoSceneIO
extends Start


#region Constants & State
const nextScene: PackedScene = preload("res://Scenes/Launch/GameFrame.tscn") # preload to prevent frame stutter/lag during scene transition or skipping.
var isSkipping: bool
var tween: Tween
#endregion


func _ready() -> void:
	super._ready()
	animateLogo()


func animateLogo() -> void:
	self.tween = Animations.tweenProperty(self, ^"modulate", Color(0,0,0,0), 3.0)
	await tween.finished
	if not isSkipping: displayNextScene() # If skipping, let the key release trigger the scene transition.


func _input(event: InputEvent) -> void:
	
	# Check is_released() before setting `isSkipping`
	# to ensure that both `if`s don't run during the same frame if multiple keys are pressed/released.
	if isSkipping and event.is_released():
		displayNextScene()
	
	if not isSkipping and event.is_pressed():
		isSkipping = true
		scatterLogo()


func scatterLogo() -> void:
	for logoNode: RigidBody2D in self.get_tree().get_nodes_in_group("logo"):
		logoNode.linear_velocity = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 100


func displayNextScene() -> void:
	Global.transitionToScene(nextScene, false) # Don't pauseSceneTree during the transition, so that the cool physics keep physicsing~
