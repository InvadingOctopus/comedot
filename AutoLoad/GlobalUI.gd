## AutoLoad
## A scene containing graphics, UI or overlays which are displayed on top of the game content at all times.
## Used for displaying paused-mode overlays, performing transition effects between scenes such as fade-in and fade-out.
## The [member process_mode] is set to [enum ProcessMode.PROCESS_MODE_ALWAYS] which ignores the [meember SceneTree.paused] flag in order to perform transition animations while the actual gameplay is paused.
## For persistent audio, see GlobalSonic.md

#class_name GlobalUI
extends Node


#region State
var pauseOverlay: PauseOverlay
#endregion


#region Signals
signal didShowPauseOverlay
signal didHidePauseOverlay
#endregion


#region Dependencies
const pauseOverlayScene := preload("res://UI/PauseOverlay.tscn")

@onready var navigationContainer:UINavigationContainer = %NavigationContainer ## For top-level UI
@onready var foregroundOverlay	:CanvasLayer = %ForegroundOverlay
@onready var animationPlayer	:AnimationPlayer = %AnimationPlayer
@onready var pauseButton		:Button = %PauseButton
@onready var labelsList			:TemporaryLabelList = %LabelsList
#endregion


func _enter_tree() -> void:
	Debug.printAutoLoadLog("_enter_tree()")


func setWindowSize(width: int, height: int, showLabel: bool = true) -> void:
	var viewport: Viewport = self.get_viewport()
	var window:		Window = viewport.get_window()
	var newSize:   Vector2 = (Vector2i(width, height))

	# NOTE: BUG: WORKAROUND: It seems `size` has to be set twice to properly resize and position the window,
	# at least on macOS with non-Retina displays.

	window.size	= newSize
	window.move_to_center()
	window.size	= newSize
	
	Settings.windowWidth  = width
	Settings.windowHeight = height

	if showLabel and GlobalUI: # GODOT BUG? Cannot check for `GlobalUI` validity in case this is called before the other AutoLoads have loaded :(
		GlobalUI.createTemporaryLabel(str("Window Size: ", width, " x ", height))


func showPauseVisuals(isPaused: bool) -> void:
	if isPaused: self.fadeIn()
	else: self.fadeOut()

	pauseButton.updateState()
	pauseButton.visible = isPaused
	
	if isPaused:
		
		if not self.pauseOverlay:
			self.pauseOverlay = pauseOverlayScene.instantiate() # NOTE: Create only here; not in property getter
		
		if pauseOverlay.get_parent() != foregroundOverlay: 
			foregroundOverlay.add_child(pauseOverlay)
			pauseOverlay.owner = foregroundOverlay # Necessary for persistence to a [PackedScene] for save/load.
		foregroundOverlay.move_child(pauseOverlay, -1)  # Put it above the fullscreen overlay effect.
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
	animationPlayer.play(Animations.overlayFadeIn)
	await animationPlayer.animation_finished


## Fades out the global overlay, which may be a solid black rectangle, effectively fading IN the actual game content.
func fadeOut() -> void:
	# Playing the fade-in animation backwards allows for smoother-looking blending from the current values,
	# in case the fade-out happens during the previous fade-in.
	# TODO: CHECK: Is the visibility still set correctly afterwards?
	animationPlayer.play_backwards(Animations.overlayFadeIn)
	#animationPlayer.play(Animations.overlayFadeOut)
	await animationPlayer.animation_finished

#endregion
