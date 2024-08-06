# AutoLoad
## Input event labels and global keyboard shortcuts

extends Node


#region Input Action Constants

class Actions: ## Input event labels

	const moveUp		:= &"moveUp"
	const moveDown		:= &"moveDown"
	const moveLeft		:= &"moveLeft"
	const moveRight		:= &"moveRight"

	const moveForward	:= &"moveForward"
	const moveBackward	:= &"moveBackward"
	const turnLeft		:= &"turnLeft"
	const turnRight		:= &"turnRight"

	const jump			:= &"jump"
	const fire			:= &"fire"
	const interact		:= &"interact"

	const pause			:= &"pause"
	const screenshot	:= &"screenshot"
	const quickSave		:= &"quickSave"
	const quickLoad		:= &"quickLoad"
	
	const debugBreak	:= &"debugBreak"
	const debugWindow	:= &"debugWindow"
	
	const windowResizeTo1080		:= &"windowResizeTo1080"
	const windowResizeTo720			:= &"windowResizeTo720"
	const windowToggleAlwaysOnTop	:= &"windowToggleAlwaysOnTop"

#endregion


## Global keyboard shortcuts
func _input(event: InputEvent) -> void:
	# TBD: Should we check `event` or [Input]?
	
	# Debugging, before any other actions are handled.

	if Input.is_action_just_released(Actions.debugBreak):
		Debug.printDebug("Debug Breakpoint Input Received")
		assert(false, "Debug Breakpoint Input Received")
	elif Input.is_action_just_released(Actions.debugWindow):
		Debug.toggleDebugWindow()

	# Game

	if Input.is_action_just_released(Actions.pause):
		self.process_mode = Node.PROCESS_MODE_ALWAYS # TBD: HACK: Is this okay??
		Global.togglePause()

	# Window

	if Input.is_action_just_released(Actions.windowToggleAlwaysOnTop):
		var isAlwaysOnTop := DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, not isAlwaysOnTop)
		Debug.showTemporaryLabel(&"Window Always on Top", str(not isAlwaysOnTop))
		get_viewport().set_input_as_handled() # TBD: Should we let these shortcuts affect other things?

	if Input.is_action_just_released(Actions.windowResizeTo720):
		DisplayServer.window_set_size(Vector2i(1280, 720))
		Debug.showTemporaryLabel(&"Window Size", "1280 x 720")
		get_viewport().set_input_as_handled() # TBD: Should we let these shortcuts affect other things?
	elif Input.is_action_just_released(Actions.windowResizeTo1080):
		DisplayServer.window_set_size(Vector2i(1920, 1080))
		Debug.showTemporaryLabel(&"Window Size", "1920 x 1080")
		get_viewport().set_input_as_handled() # TBD: Should we let these shortcuts affect other things?

	# Save & Load
	
	if event.is_action_released(GlobalInput.Actions.screenshot):
		Global.screenshot()
	
	if event.is_action_released(GlobalInput.Actions.quickLoad):
		Global.loadGame()
	elif event.is_action_released(GlobalInput.Actions.quickSave):
		Global.saveGame()


#region Helper Functions

## Returns: `true` if [method Input.is_action_just_pressed] or [method Input.is_action_just_released].
func hasActionTransitioned(action: StringName) -> bool:
	return Input.is_action_just_pressed(action) \
		or Input.is_action_just_released(action)
		
#endregion
