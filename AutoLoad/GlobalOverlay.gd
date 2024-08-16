## AutoLoad
## A scene containing graphics which are overlaid on top of or underneath the actual game content at all times.
## Used for performing transition effects between scenes such as fade-in and fade-out.
## The [process_mode] is set to `PROCESS_MODE_ALWAYS` which ignores the [SceneTree.paused] flag in order to perform transition animations while the actual gameplay is paused.

#class_name GlobalOverlay
extends Node


#region Dependencies
@onready var animationPlayer	:= %AnimationPlayer
@onready var pauseSettingsUI	:= %PauseSettingsUI
@onready var labelsList			:= %LabelsList
#endregion


func setPauseSettingsVisibility(visible: bool) -> void:
	pauseSettingsUI.visible = visible


func createTemporaryLabel(text: String) -> Label:
	return labelsList.createTemporaryLabel(text)


#region Animations

## Fades in the global overlay, which may be a solid black rectangle, effectively fading OUT the actual game content.
func fadeIn() -> void:
	animationPlayer.play(Global.Animations.overlayFadeIn)
	await animationPlayer.animation_finished


## Fades out the global overlay, which may be a solid black rectangle, effectively fading IN the actual game content.
func fadeOut() -> void:
	# Playing the fade-in animation backwards allows for smoother-looking blending from the current values,
	# in case the fade-out happens during the previous fade-in.
	# TODO: CHECK: Is the visibility still set correctly afterwards?
	animationPlayer.play_backwards(Global.Animations.overlayFadeIn)
	#animationPlayer.play(Global.Animations.overlayFadeOut)
	await animationPlayer.animation_finished

#endregion
