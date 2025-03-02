## The Invading Octopus Logo~

class_name LogoSceneIO
extends Start


#region Constants & State

const nextScene: PackedScene = preload("res://Scenes/Launch/GameFrame.tscn") # preload to prevent frame stutter/lag during scene transition or skipping.

var textLines: PackedStringArray = [
	str("LOAD\"", ProjectSettings.get_setting("application/config/name", "Comedot"), "\"").to_upper(),
	"READY © MMXXV",
	"RUN",
	]

var isSkipping: bool
var logoTween:  Tween

#endregion


func _ready() -> void:
	super._ready()
	if Debug.debugBackground: Debug.debugBackground.visible = false # Hide the debug background during the logo
	GlobalInput.isPauseShortcutAllowed = false
	
	var selfAsNode: Node2D = self.get_node(^".") as Node2D
	selfAsNode.global_position = Tools.getCenteredPositionOnViewport(selfAsNode, 320, 180)
	
	animateText()
	animateLogo()


func animateText() -> void:
	for text in textLines:
		var label: Label = GlobalUI.createTemporaryLabel(text)
		label.modulate = Color(1,1,1,0)
		Animations.tweenProperty(label, ^"modulate", Color.WHITE, 0.5)
		if not isSkipping: await get_tree().create_timer(0.5).timeout
		else: break


func animateLogo() -> void:
	self.logoTween = Animations.tweenProperty(self, ^"modulate", Color(0,0,0,0), 3.0)
	await logoTween.finished
	if not isSkipping: await displayNextScene() # If skipping, let the key release trigger the scene transition.


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return

	# Check is_released() before setting `isSkipping`
	# to ensure that both `if`s don't run during the same frame if multiple keys are pressed/released.
	if isSkipping and event.is_released():
		await displayNextScene()

	if not isSkipping and event.is_pressed():
		isSkipping = true
		scatterLogo()


func scatterLogo() -> void:
	for logoNode: RigidBody2D in self.get_tree().get_nodes_in_group("logo"):
		logoNode.linear_velocity = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 100


func displayNextScene() -> void:
	await SceneManager.transitionToScene(nextScene, false) # Don't pauseSceneTree during the transition, so that the cool physics keep physicsing~


func _exit_tree() -> void:
	if Debug.debugBackground: Debug.debugBackground.visible = self.showDebugBackground # Hide the debug background during the logo
	GlobalInput.isPauseShortcutAllowed = true
