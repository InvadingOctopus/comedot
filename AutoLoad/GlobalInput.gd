## AutoLoad
## Input event labels and global keyboard shortcuts

# class_name GlobalInput
extends Node


#region Input Actions & Events Constants


## Input event labels.
## See the Input Map in the Godot Project Settings for the default axes, buttons and keys assigned to each action.
## NOTE: This is NOT the same as the [Action] Resource which represent special actions performed by explicit in-game choices.
class Actions:
	# TBD: Rename to "InputAction" or "InputEventName" etc. to disambiguate from Comedot-specific "special/explicit" [Action]s?

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

	# A secondary axis for controlling a camera or aiming gun, cursor etc. Gamepad Right Joystick.
	const aimLeft		:= &"aimLeft"
	const aimRight		:= &"aimRight"
	const aimUp			:= &"aimUp"
	const aimDown		:= &"aimDown"

	const jump			:= &"jump"
	const fire			:= &"fire"
	const interact		:= &"interact"

	## Used for generating and detecting input events for an [Action], a Resource which represents an explicitly-chosen game-specific special ability, such as casting a spell.
	## See [ActionControlComponent] & [ActionButton] etc.
	## NOTE: This string should end in an underscore `_` to separate the prefix from the [member Action.name] which normally begins with a lowercase letter as well.
	## Edit the Godot Project Settings' Input Map to add shortcuts for special [Actions] e.g `specialAction_dash`.
	const specialActionPrefix := &"specialAction_" # TBD: Less ambiguous name? :')

	const back			:= &"back"
	const pause			:= &"pause"
	const screenshot	:= &"screenshot"
	const skipMusic		:= &"skipMusic"
	const quickSave		:= &"quickSave"
	const quickLoad		:= &"quickLoad"

	const windowToggleAlwaysOnTop	:= &"windowToggleAlwaysOnTop"
	const windowResizeTo1080		:= &"windowResizeTo1080" ## 1920 x 1080
	const windowResizeTo720			:= &"windowResizeTo720"  ## 1280 x 720

	const debugWindow	:= &"debugWindow" ## Toggles the Debug Info Window.
	const debugTest		:= &"debugTest"   ## Activates [TestMode]
	const debugBreak	:= &"debugBreak"  ## Causes a debugging breakpoint.

	const uiPrefix		:= &"ui_" ## The prefix that all Godot built-in UI input action names start with.
	const accept		:= &"ui_accept"
	const cancel		:= &"ui_cancel"
	const select		:= &"ui_select" ## ALERT: This is Godot's built-in "UI Select" Input Action, which may NOT necessarily be a gamepad's Select button!

	## List of input actions to be excluded from player customization in [InputActionsList] and other control remapping UI.
	const excludedFromCustomization: Array[StringName] = [
		back, pause,
		windowToggleAlwaysOnTop, windowResizeTo1080, windowResizeTo720,
		debugWindow, debugTest, debugBreak
		]

	static var allActions: Dictionary: ## Returns a list of all the input action `const` property names & values. NOTE: NOT updated during runtime!
		get:
			if not allActions: allActions = Actions.new().get_script().get_script_constant_map()
			return allActions

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


## Global shortcuts including gamepad etc.
func _unhandled_input(event: InputEvent) -> void:
	# TBD: Should we check `event` or [Input]?
	if not event.is_action_type(): return

	var isHandled: bool = false # Keep other scripts from eating our leftovers, e.g. prevent the Escape key for "Pause" also triggering a "Back" event or vice-versa.

	# Game

	if isPauseShortcutAllowed and not SceneManager.ongoingTransitionScene and Input.is_action_just_pressed(Actions.pause): # Prevent pausing during scene transitions
		self.process_mode = Node.PROCESS_MODE_ALWAYS # TBD: HACK: Is this necessary?
		SceneManager.togglePause()
		isHandled = true

	if isHandled: self.get_viewport().set_input_as_handled()


## Global keyboard shortcuts
func _unhandled_key_input(event: InputEvent) -> void:
	# TBD: Should we check `event` or [Input]?
	if not event.is_action_type(): return

	var isHandled: bool = false # Keep other scripts from eating our leftovers, e.g. prevent the Escape key for "Pause" also triggering a "Back" event or vice-versa.

	# NOTE: Mutually-exclusive events should be handled in if/elif/else pairs/sets

	# Debugging, before any other actions are handled.

	if Input.is_action_just_released(Actions.debugBreak):
		Debug.printDebug("Debug Breakpoint Input Received")
		breakpoint # TBD: Use `breakpoint` or `assert(false)`? `assert` also adds a message but only runs in debug builds.
		# assert(false, "Debug Breakpoint Input Received")
		isHandled = true
	elif Input.is_action_just_released(Actions.debugWindow):
		Debug.toggleDebugWindow()
		isHandled = true

	# Window

	if Input.is_action_just_released(Actions.windowToggleAlwaysOnTop):
		var isAlwaysOnTop: bool = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, not isAlwaysOnTop) # `not` because it's a toggle.
		GlobalUI.createTemporaryLabel(str("Window Always on Top: ", not isAlwaysOnTop))
		get_viewport().set_input_as_handled() # TBD: Should we let these shortcuts affect other things?
		isHandled = true

	if Input.is_action_just_released(Actions.windowResizeTo720):
		GlobalUI.setWindowSize(1280, 720)
		get_viewport().set_input_as_handled() # TBD: Should we let these shortcuts affect other things?
		isHandled = true
	elif Input.is_action_just_released(Actions.windowResizeTo1080):
		GlobalUI.setWindowSize(1920, 1080)
		get_viewport().set_input_as_handled() # TBD: Should we let these shortcuts affect other things?
		isHandled = true

	# Save & Load

	if event.is_action_released(GlobalInput.Actions.screenshot):
		Global.screenshot()
		isHandled = true

	if event.is_action_released(GlobalInput.Actions.quickLoad): # TBD: Should Loading take precedence over Saving?
		GameState.loadGame()
		isHandled = true
	elif event.is_action_released(GlobalInput.Actions.quickSave):
		GameState.saveGame()
		isHandled = true

	if isHandled: self.get_viewport().set_input_as_handled()


#region Helper Functions

## Returns a list of the textual representation of keys, buttons or other controls specified for an Input Action, such as "Space" for "jump".
## Trims redundant text such as " (Physical)"
func getInputEventText(action: StringName) -> PackedStringArray:
	var strings: PackedStringArray
	for event: InputEvent in InputMap.action_get_events(action):
		strings.append(event.as_text().trim_suffix(" (Physical)"))
	return strings


## Returns a list of the textual representation of keys, buttons or other controls specified for an Input Action, such as "Space" for "jump".
## Replaces redundant text such as "(Physical)" with "(Keyboard)" using the [constant eventTextReplacements] [Dictionary].
func getInputEventReplacedText(action: StringName) -> PackedStringArray:
	var strings: PackedStringArray
	for event: InputEvent in InputMap.action_get_events(action):
		strings.append(Tools.replaceStrings(event.as_text(), GlobalInput.eventTextReplacements))
	return strings


## Returns: `true` if [method Input.is_action_just_pressed] or [method Input.is_action_just_released].
func hasActionTransitioned(action: StringName) -> bool:
	return Input.is_action_just_pressed(action) \
		or Input.is_action_just_released(action)


## Returns `true` if an [InputEvent] was one of the "UI actions" built into Godot.
## ALERT: Only checks against a limited set of UI actions such as cancel/accept, next/previous, & directions.
## A jank workaround for Godot's lack of built-in API for a common task.
## @experimental
func isInputEventUIAction(event: InputEvent) -> bool:
	# Checking strings like this is very jank but dummy Godot is dummy.
	for eventName: StringName in [
	&"ui_cancel", &"ui_accept", &"ui_select",
	&"ui_focus_next", &"ui_focus_prev",
	&"ui_page_up", &"ui_page_down",
	&"ui_home",	&"ui_end",
	&"ui_left", &"ui_right",
	&"ui_up",   &"ui_down",
	]:
		if event.is_action(eventName): return true
	# else
	return false


## Returns all the player control input actions from [GlobalInput] that match a given [InputEvent].
## A jank workaround for Godot's lack of built-in API for a common task.
## WARNING: PERFORMANCE: May be too slow; avoid calling frequently!
## @experimental
func findActionsFromInputEvent(event: InputEvent) -> Array[StringName]:
	if not event.is_action_type(): return []
	# PERFORMANCE: GRRR: Since dummy Godot does not provide any direct way to get the input actions from an [InputEvent],
	# we have to manually check every possibility... >:(
	var inputActions: Array[StringName]
	for propertyName: String in Actions.allActions:
		if event.is_action(propertyName): inputActions.append(propertyName)
	return inputActions

#endregion
