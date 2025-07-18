## AutoLoad
## A scene containing graphics, UI or overlays which are displayed on top of the game content at all times.
## Used for displaying paused-mode overlays, performing transition effects between scenes such as fade-in and fade-out.
## The [member process_mode] is set to [enum ProcessMode.PROCESS_MODE_ALWAYS] which ignores the [meember SceneTree.paused] flag in order to perform transition animations while the actual gameplay is paused.
## For persistent audio, see GlobalSonic.md

#class_name GlobalUI
extends Node


#region State
var pauseOverlay:		PauseOverlay
var pauseOverlayTween:	Tween
var rectFadeTween:		Tween
var musicLabelTween:	Tween
#endregion


#region Signals

signal didShowPauseOverlay(overlay: CanvasItem)
signal didHidePauseOverlay

# Signal Event Bus
# These signals may be emitted by any object and connected to any object at any time, usually via scripts.

@warning_ignore_start("unused_signal") # IGNORE Godot Warning; these signals are used by other classes.

# TBD: Should these signals be moved to Action itself?
signal actionDidRequestTarget(action: Action, source: Entity) ## Emitted when an [Action] requires a target, so that the UI may prompt the player to choose a target.
signal actionIsChoosingTarget(action: Action, source: Entity) ## Emitted when an [ActionTargetingComponentBase] prompts the player for an [Action] target. This signal may be used by UI such as [ActionButton] to update its visual state until a target is chosen.
signal actionDidCancelTarget(action:  Action, source: Entity) ## Emitted when an [ActionTargetingComponentBase] cancels target selection.
signal actionDidChooseTarget(action:  Action, source: Entity, target: Variant) ## Emitted when an [ActionTargetingComponentBase] chooses a target for an [Action]. This signal may be used by UI such as [ActionButton] to update its visual state.

@warning_ignore_restore("unused_signal")
#endregion


#region Dependencies
const pauseOverlayScene := preload("res://UI/PauseOverlay.tscn")

@onready var foregroundOverlay:		CanvasLayer				= %ForegroundOverlay
@onready var labelsList:			TemporaryLabelList		= %LabelsList
@onready var navigationContainer:	UINavigationContainer	= %NavigationContainer ## For top-level UI
@onready var tintRect:				ColorRect				= %GlobalTintRect

@onready var pauseRect:				ColorRect				= %PauseRects
@onready var pauseOverlayContainer:	UINavigationContainer	= %PauseOverlayContainer

@onready var musicLabelContainer:	Container				= %MusicLabelContainer
@onready var musicLabel:			Label					= %MusicLabel
#endregion


#region Setup

func _enter_tree() -> void:
	Debug.printAutoLoadLog("_enter_tree()")


func _ready() -> void:
	if not OS.has_feature("web"): # BUG: WORKAROUND: Running in a web browser (or at least Safari) doesn't handle window size restoration properly.
		# Do not set the window size if we're starting in fullscreen
		# TBD: How to handle going to windowed mode for the first time? Should the first size be read from Settings?
		var windowMode: int = DisplayServer.window_get_mode()
		if windowMode != DisplayServer.WINDOW_MODE_FULLSCREEN and windowMode != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			GlobalUI.setWindowSize(Settings.windowWidth, Settings.windowHeight, false) # !showLabel to avoid clutter

		setRetinaScaling()

	musicLabelContainer.position.y = musicLabelContainer.get_viewport_rect().end.y
	Tools.connectSignal(GlobalSonic.musicPlayerDidPlay, self.onGlobalSonic_musicPlayerDidPlay)


func setWindowSize(width: int, height: int, showLabel: bool = true) -> void:
	var viewport:	Viewport = self.get_viewport()
	var window:		Window   = viewport.get_window()
	var newSize:	Vector2  = (Vector2i(width, height))

	# NOTE: BUG: WORKAROUND: It seems `size` has to be set twice to properly resize and position the window,
	# at least on macOS with non-Retina displays.

	window.size	= newSize
	window.move_to_center()
	window.size	= newSize
	window.move_to_center()

	Settings.windowWidth  = width
	Settings.windowHeight = height

	if showLabel and GlobalUI: # GODOT BUG? Cannot check for `GlobalUI` validity in case this is called before the other AutoLoads have loaded :(
		GlobalUI.createTemporaryLabel(str("Window Size: ", width, " x ", height))


## Doubles the [member Window.content_scale_factor] & window size on Mac Retina & other HiDPI displays.
## @experimental
func setRetinaScaling() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_HIDPI) \
	or is_equal_approx(DisplayServer.screen_get_scale(), 2.0):
		Debug.printAutoLoadLog(str("DisplayServer screen scale: ", DisplayServer.screen_get_scale()))
		var window: Window = self.get_window()
		window.content_scale_factor = 2.0
		window.size *= 2 # TBD: Double the Viewport size?
		window.move_to_center()

#endregion


#region Pause/Unpause

const pauseAnimationDuration: float = 0.25

func showPauseVisuals(isPaused: bool) -> void:
	# Avoid reanimating an existing state
	if (isPaused and pauseOverlayContainer.visible) \
	or (not isPaused and not pauseOverlayContainer.visible):
		return

	# Let PauseButton.gd handle its update itself

	if isPaused:

		if not pauseOverlay: pauseOverlay = pauseOverlayScene.instantiate() # NOTE: Create only here; not in property getter, to avoid unnecessary creation.

		if pauseOverlay.get_parent() != pauseOverlayContainer: # Is the overlay already there?
			pauseOverlayContainer.add_child(pauseOverlay)
			pauseOverlay.owner = pauseOverlayContainer # Necessary for persistence to a [PackedScene] for save/load.

		pauseOverlayContainer.move_child(pauseOverlay, -1) # Put it in front of any other children
		# Ensure visibility just in case
		pauseOverlay.pauseButton.visible = true
		pauseOverlay.visible = true
		if pauseOverlayTween: pauseOverlayTween.kill()
		pauseOverlayTween = self.create_tween()
		pauseOverlayTween.tween_subtween(Animations.fadeIn(pauseRect, pauseAnimationDuration))
		pauseOverlayTween.parallel().tween_subtween(Animations.fadeIn(pauseOverlayContainer, pauseAnimationDuration))
		didShowPauseOverlay.emit(pauseOverlay)

	elif not isPaused:

		if pauseOverlay: pauseOverlay.pauseButton.visible = false

		if pauseOverlayTween: pauseOverlayTween.kill()
		pauseOverlayTween = self.create_tween()
		pauseOverlayTween.tween_subtween(Animations.fadeOut(pauseOverlayContainer, pauseAnimationDuration))
		pauseOverlayTween.parallel().tween_subtween(Animations.fadeOut(pauseRect, pauseAnimationDuration))
		await pauseOverlayTween.finished

		Tools.removeAllChildren(pauseOverlayContainer)
		pauseOverlayContainer.resetHistory()
		if pauseOverlay:
			pauseOverlay.queue_free() # TBD: queue_free() or save for reuse?
			pauseOverlay = null
		didHidePauseOverlay.emit()

	# Hide any other global UI when paused
	navigationContainer.visible = not pauseOverlayContainer.visible

#endregion


#region Animations

## Fades in the global overlay, which may be a solid black rectangle, effectively fading OUT the actual game content.
func fadeInTintRect() -> Tween:
	if rectFadeTween: rectFadeTween.kill()
	rectFadeTween = Animations.fadeIn(tintRect)
	return rectFadeTween


## Fades out the global overlay, which may be a solid black rectangle, effectively fading IN the actual game content.
func fadeOutTintRect() -> Tween:
	if rectFadeTween: rectFadeTween.kill()
	rectFadeTween = Animations.fadeOut(tintRect)
	return rectFadeTween

#endregion


#region Music

## @experimental
func showMusicLabel(title: String) -> void:
	# TODO: Make this awesome animation a generic shared function! in Animations.gd

	const margin:		float = 4.0
	const showTime:		float = 0.5
	const hideTime:		float = 0.5
	const waitTIme:		float = 2.0
	const hideColor:	Color = Color(1, 0, 1, 1)

	# UNUSED: Let any existing title be animated into the new one ^^
	# musicLabel.text					= ""
	# musicLabelContainer.position.y	= musicLabelContainer.get_viewport_rect().end.y
	musicLabelContainer.modulate	= hideColor # if not musicLabelTween else Color(1, 1, 1, 2) # Flash if skipping music
	musicLabelContainer.visible		= true

	Animations.tweenProperty(musicLabel, ^"text", title, showTime)

	if musicLabelTween: musicLabelTween.kill()

	musicLabelTween = Animations.tweenProperty(musicLabelContainer, ^"position:y", musicLabelContainer.get_viewport_rect().end.y - 16 - margin, showTime) \
		.set_ignore_time_scale()  \
		.set_ease(Tween.EASE_OUT) \
		.set_parallel()
	musicLabelTween.tween_property(musicLabelContainer, ^"modulate", Color(0, 1, 1, 1), showTime) \
		.set_ease(Tween.EASE_OUT)

	await musicLabelTween.finished
	musicLabelTween = Animations.tweenProperty(musicLabelContainer, ^"modulate", musicLabelContainer.modulate, waitTIme) # NOTE: Use a [Tween] to wait instead of a [SceneTreeTimer] so it can be killed/interrupted.
	await musicLabelTween.finished
	# UNUSED: await SceneManager.sceneTree.create_timer(waitTIme).timeout

	if not musicLabelTween or not musicLabelTween.is_running():
		# Animations.tweenProperty(musicLabel, ^"text", "", hideTime) # UNUSED: Let the previous title morph into the next one ^^
		musicLabelTween = Animations.tweenProperty(musicLabelContainer, ^"position:y", musicLabelContainer.get_viewport_rect().end.y, hideTime) \
			.set_ignore_time_scale()  \
			.set_ease(Tween.EASE_OUT) \
			.set_parallel()
		musicLabelTween.tween_property(musicLabelContainer, ^"modulate", hideColor, hideTime) \
			.set_ease(Tween.EASE_OUT)


func onGlobalSonic_musicPlayerDidPlay(fileName: String) -> void:
	showMusicLabel(fileName.get_basename().get_file())

#endregion


#region Miscellaneous

func createTemporaryLabel(text: String) -> Label:
	return labelsList.createTemporaryLabel(text)

#endregion
