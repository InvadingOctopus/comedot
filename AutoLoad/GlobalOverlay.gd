## AutoLoad
## A scene containing graphics which are overlaid on top of or underneath the actual game content at all times.
## Used for performing transition effects between scenes such as fade-in and fade-out.
## The [process_mode] is set to `PROCESS_MODE_ALWAYS` which ignored the [SceneTree.paused] flag in order to perform transition animations while the gameplay is paused.

#class_name GlobalOverlay
extends Node


@onready var animationPlayer := %AnimationPlayer
@onready var pauseSettingsUI := %PauseSettingsUI


## Fades in the global overlay, which may be a solid black rectangle, effectively fading OUT the actual game content.
func fadeIn():
	animationPlayer.play(Global.Animations.overlayFadeIn)
	await animationPlayer.animation_finished


## Fades out the global overlay, which may be a solid black rectangle, effectively fading IN the actual game content.
func fadeOut():
	# Playing the fade-in animation backwards allows for smoother-looking blending from the current values,
	# in case the fade-out happens during the previous fade-in.
	# TODO: CHECK: Is the visibility still set correctly afterwards?
	animationPlayer.play_backwards(Global.Animations.overlayFadeIn)
	#animationPlayer.play(Global.Animations.overlayFadeOut)
	await animationPlayer.animation_finished


func setPauseSettingsVisibility(visible: bool):
	pauseSettingsUI.visible = visible
