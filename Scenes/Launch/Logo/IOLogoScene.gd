## The Invading Octopus Logo~

class_name LogoSceneIO
extends Start


#region Constants & State

const nextScene: PackedScene = preload("res://Scenes/Launch/GameFrame.tscn") # preload to prevent frame stutter/lag during scene transition or skipping.

var textLines: PackedStringArray = [
	"69K RAM SYSTEM, 69420 BYTES FREE",
	str("LOAD\"", ProjectSettings.get_setting("application/config/name", "Comedot"), "\"").to_upper(),
	"© MMXXV",
	"RUN",
	"0 OK, 10:1",
	]

const textColors: Array[Color] = [
	Color.DODGER_BLUE, # C64 Prompt
	Color.WHITE, # Title
	Color.WHITE, # Copyright
	Color.SLATE_GRAY, # RUN
	Color.GREEN, # ZX Spectrum Prompt
	]

var isSkipping: bool
var logoTween:  Tween

#endregion


func _ready() -> void:
	self.set_process_unhandled_input(false) # Ignore input before the animation has started (doesn't seem to make any difference tho :')
	super._ready()

	if Debug.debugBackground: Debug.debugBackground.visible = false # Hide the debug background during the logo
	GlobalInput.isPauseShortcutAllowed = false

	# Center the logo depending on the screen resolution
	var selfAsNode: Node2D	= self.get_node(^".") as Node2D
	var viewPortRect: Rect2 = self.get_viewport_rect() # Get the unscaled Viewport dimensions
	$InvadingOctopuses.global_position += Tools.getCenteredPositionOnViewport(selfAsNode, 320, 180) # Center the logo
	$Floor.position.y		= viewPortRect.end.y # Put the floor on the floor
	$WallRight.position.x	= viewPortRect.end.x # Put the wall at the wall

	animateText()
	animateLogo()
	self.set_process_unhandled_input(true) # Allow skipping


func animateText() -> void:
	for index in textLines.size():
		var label: Label = GlobalUI.createTemporaryLabel(textLines[index])
		if index == 0: # Glitchtext only certain lines
			label.text = "".lpad(textLines[index].length(), "0")
			Animations.tweenProperty(label, ^"text", textLines[index],  0.5)
		label.modulate = Color(textColors[index], 0)
		Animations.tweenProperty(label, ^"modulate", textColors[index], 0.5)

		if not isSkipping: await get_tree().create_timer(0.5).timeout
		else: continue # Display the next line(s) right away


func animateLogo() -> void:
	self.logoTween = Animations.tweenProperty(self, ^"modulate", Color(0,0,0,0), 4.0)
	await logoTween.finished
	if not isSkipping: await displayNextScene() # If skipping, let the key release trigger the scene transition.


func _unhandled_input(event: InputEvent) -> void:
	if  not event is InputEventMouseButton \
	and not event is InputEventKey \
	and not event is InputEventJoypadButton:
		return

	# NOTE: Initiate skip only on a press, but display the next scene when the button/key is released
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
