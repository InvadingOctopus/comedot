## AutoLoad
## Input event labels and global keyboard shortcuts

# class_name GlobalInput
extends Node


#region Input Actions & Events Constants

## Input event labels.
## See the Input Map in the Godot Project Settings for the default axes, buttons and keys assigned to each action.
## NOTE: This is NOT the same as the [Action] Resource which represent special actions performed by explicit in-game choices.
class Actions:

	# The primary movement axes in most games. Gamepad Left Joystick, Gamepad D-Pad.
	const moveLeft		:= &"moveLeft"
	const moveRight		:= &"moveRight"
	const moveUp		:= &"moveUp"
	const moveDown		:= &"moveDown"

	# Relative-movement controls in games where a character rotates left/right and "thrusts" forward or "reverses" backward.
	# Also known as "tank controls", and used in games like Asteroids.
	const turnLeft		:= &"turnLeft"  ## Gamepad Right Joystick
	const turnRight		:= &"turnRight" ## Gamepad Right Joystick
	const moveForward	:= &"moveForward"
	const moveBackward	:= &"moveBackward"

	# A secondary axis for controlling a camera or aiming cursor etc. Gamepad Right Joystick.
	# TBD: Should these be named "aim-" instead of "look-"?
	const lookLeft		:= &"lookLeft"
	const lookRight		:= &"lookRight"
	const lookUp		:= &"lookUp"
	const lookDown		:= &"lookDown"

	const jump			:= &"jump"
	const fire			:= &"fire"
	const interact		:= &"interact"

	## Used for generating input events for an [Action], a Resource which represents an explicitly-chosen game-specific special ability, such as casting a spell.
	const specialActionPrefix := &"specialAction" # TBD: Less ambiguous name? :')

	const pause			:= &"pause"
	const screenshot	:= &"screenshot"
	const quickSave		:= &"quickSave"
	const quickLoad		:= &"quickLoad"

	const windowToggleAlwaysOnTop	:= &"windowToggleAlwaysOnTop"
	const windowResizeTo1080		:= &"windowResizeTo1080" ## 1920 x 1080
	const windowResizeTo720			:= &"windowResizeTo720"  ## 1280 x 720

	const debugWindow	:= &"debugWindow" ## Toggles the Debug Info Window.
	const debugTest		:= &"debugTest"   ## Activates [TestMode]
	const debugBreak	:= &"debugBreak"  ## Causes a debugging breakpoint.


## Replacements for certain strings in the text representations of InputEvent control names, such as "Keyboard" instead of "Physical".
const eventTextReplacements: Dictionary[String, String] = {
	"Physical": "Keyboard",
	}

#endregion


#region State
## May be set to `false` to disable the pause/unpause shortcut specific situations, such as during a Game Over screen or network UI.
var isPauseShortcutAllowed: bool = true
#endregion


#region Signals
@warning_ignore("unused_signal")
signal didAddInputEvent(inputAction: StringName, inputEvent: InputEvent) ## Emitted by [InputActionUI]

@warning_ignore("unused_signal")
signal didDeleteInputEvent(inputAction: StringName, inputEvent: InputEvent) ## Emitted by [InputActionEventUI]
#endregion


func _enter_tree() -> void:
	Debug.printAutoLoadLog("_enter_tree()")


## Global keyboard shortcuts
func _input(event: InputEvent) -> void:
	# TBD: Should we check `event` or [Input]?

	if not event.is_action_type(): return

	# Debugging, before any other actions are handled.

	if Input.is_action_just_released(Actions.debugBreak):
		Debug.printDebug("Debug Breakpoint Input Received")
		breakpoint # TBD: Use `breakpoint` or `assert(false)`? `assert` also adds a message but only runs in debug builds.
		# assert(false, "Debug Breakpoint Input Received")
	elif Input.is_action_just_released(Actions.debugWindow):
		Debug.toggleDebugWindow()

	# Game

	if isPauseShortcutAllowed and not SceneManager.ongoingTransitionScene and Input.is_action_just_pressed(Actions.pause): # Prevent pausing during scene transitions
		self.process_mode = Node.PROCESS_MODE_ALWAYS # TBD: HACK: Is this necessary?
		SceneManager.togglePause()

	# Window

	if Input.is_action_just_released(Actions.windowToggleAlwaysOnTop):
		var isAlwaysOnTop := DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, not isAlwaysOnTop) # `not` because it's a toggle.
		GlobalUI.createTemporaryLabel(str("Window Always on Top: ", not isAlwaysOnTop))
		get_viewport().set_input_as_handled() # TBD: Should we let these shortcuts affect other things?

	if Input.is_action_just_released(Actions.windowResizeTo720):
		GlobalUI.setWindowSize(1280, 720)
		get_viewport().set_input_as_handled() # TBD: Should we let these shortcuts affect other things?
		
	elif Input.is_action_just_released(Actions.windowResizeTo1080):
		GlobalUI.setWindowSize(1920, 1080)
		get_viewport().set_input_as_handled() # TBD: Should we let these shortcuts affect other things?

	# Save & Load

	if event.is_action_released(GlobalInput.Actions.screenshot):
		Global.screenshot()

	if event.is_action_released(GlobalInput.Actions.quickLoad):
		GameState.loadGame()
	elif event.is_action_released(GlobalInput.Actions.quickSave):
		GameState.saveGame()


#region Helper Functions

## Returns a list of the textual representation of keys, buttons or other controls specified for an Input Action, such as "Space" for "jump".
## Trims redundant text such as " (Physical)"
func getInputEventText(action: StringName) -> PackedStringArray:
	var strings: PackedStringArray
	for event: InputEvent in InputMap.action_get_events(action):
		strings.append(event.as_text().trim_suffix(" (Physical)"))
	return strings


## Returns a list of the textual representation of keys, buttons or other controls specified for an Input Action, such as "Space" for "jump".
## Replaces redundant text such as "(Physical)" with "(Keyboard)" using the [const eventTextReplacements] [Dictionary].
func getInputEventReplacedText(action: StringName) -> PackedStringArray:
	var strings: PackedStringArray
	for event: InputEvent in InputMap.action_get_events(action):
		strings.append(Tools.replaceStrings(event.as_text(), GlobalInput.eventTextReplacements))
	return strings


## Returns: `true` if [method Input.is_action_just_pressed] or [method Input.is_action_just_released].
func hasActionTransitioned(action: StringName) -> bool:
	return Input.is_action_just_pressed(action) \
		or Input.is_action_just_released(action)

#endregion
