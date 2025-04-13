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
@onready var overlayRect:			ColorRect				= %GlobalOverlayRect
@onready var navigationContainer:	UINavigationContainer	= %NavigationContainer ## For top-level UI
@onready var pauseOverlayContainer:	UINavigationContainer	= %PauseOverlayContainer
#endregion


func _enter_tree() -> void:
	Debug.printAutoLoadLog("_enter_tree()")


func _ready() -> void:
	if not OS.has_feature("web"): # BUG: WORKAROUND: Running in a web browser (or at least Safari) doesn't handle window size restoration properly.
		# Do not set the window size if we're starting in fullscreen
		# TBD: How to handle going to windowed mode for the first time? Should the first size be read from Settings?
		var windowMode: int = DisplayServer.window_get_mode()
		if windowMode != DisplayServer.WINDOW_MODE_FULLSCREEN and windowMode != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			GlobalUI.setWindowSize(Settings.windowWidth, Settings.windowHeight, false) # !showLabel to avoid clutter


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
		fadeInOverlayRect()
		if pauseOverlayTween: pauseOverlayTween.kill()
		pauseOverlayTween = Animations.fadeIn(pauseOverlayContainer, 0.2)
		didShowPauseOverlay.emit(pauseOverlay)

	elif not isPaused:

		if pauseOverlay: pauseOverlay.pauseButton.visible = false

		fadeOutOverlayRect()
		if pauseOverlayTween: pauseOverlayTween.kill()
		pauseOverlayTween = Animations.fadeOut(pauseOverlayContainer, 0.2)
		await pauseOverlayTween.finished

		Tools.removeAllChildren(pauseOverlayContainer)
		pauseOverlayContainer.resetHistory()
		if pauseOverlay:
			pauseOverlay.queue_free() # TBD: queue_free() or save for reuse?
			pauseOverlay = null
		didHidePauseOverlay.emit()


func createTemporaryLabel(text: String) -> Label:
	return labelsList.createTemporaryLabel(text)


#region Animations

## Fades in the global overlay, which may be a solid black rectangle, effectively fading OUT the actual game content.
func fadeInOverlayRect() -> Tween:
	if rectFadeTween: rectFadeTween.kill()
	rectFadeTween = Animations.fadeIn(overlayRect)
	return rectFadeTween


## Fades out the global overlay, which may be a solid black rectangle, effectively fading IN the actual game content.
func fadeOutOverlayRect() -> Tween:
	if rectFadeTween: rectFadeTween.kill()
	rectFadeTween = Animations.fadeOut(overlayRect)
	return rectFadeTween

#endregion
