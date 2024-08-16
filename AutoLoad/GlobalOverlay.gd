## AutoLoad
## A scene containing graphics which are overlaid on top of or underneath the actual game content at all times.
## Used for performing transition effects between scenes such as fade-in and fade-out.
## The [process_mode] is set to `PROCESS_MODE_ALWAYS` which ignores the [SceneTree.paused] flag in order to perform transition animations while the actual gameplay is paused.

#class_name GlobalOverlay
extends Node


#region State
var pauseOverlay: PauseOverlay
#endregion


#region Signals
signal didShowPauseOverlay
signal didHidePauseOverlay
#endregion


#region Dependencies
const pauseOverlayScene := preload("res://Scenes/UI/PauseOverlay.tscn")

@onready var foregroundOverlay	:= %ForegroundOverlay
@onready var animationPlayer	:= %AnimationPlayer
@onready var pauseButton		:= %PauseButton
@onready var labelsList			:= %LabelsList
#endregion


func showPauseVisuals(isPaused: bool) -> void:
	if isPaused: GlobalOverlay.fadeIn()
	else: GlobalOverlay.fadeOut()

	pauseButton.updateState()
	pauseButton.visible = isPaused
	
	if isPaused:
		
		if not self.pauseOverlay:
			self.pauseOverlay = pauseOverlayScene.instantiate() # NOTE: Create only here; not in property getter
		
		foregroundOverlay.add_child(pauseOverlay)
		pauseOverlay.owner = foregroundOverlay # Necessary for persistence to a [PackedScene] for save/load.
		foregroundOverlay.move_child(pauseOverlay, 1)  # Put it above the fullscreen overlay effect.
		pauseOverlay.visible = true # Just in case
		didShowPauseOverlay.emit()

	elif not isPaused and pauseOverlay:
		foregroundOverlay.remove_child(pauseOverlay)
		self.pauseOverlay = null
		didHidePauseOverlay.emit()


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
