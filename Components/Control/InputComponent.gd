## Monitors and stores the player's input for other components to act upon.
## ALERT: Does NOT check mouse motion input.
## NOTE: To improve performance, small independent components may do their own input polling. Therefore, this [InputComponent] makes most sense when a chain of multiple components depend upon it, such as [TurningControlComponent] + [ThrustControlComponent].
## TIP: May be subclassed for AI-control or pre-recorded demos or "attract mode" etc.
## Requirements: Should be BEFORE all components that depend on player/AI control.

class_name InputComponent
extends Component


#region Parameters

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process_input(isEnabled and not shouldProcessUnhandledInputOnly)
			self.set_process_unhandled_input(isEnabled and shouldProcessUnhandledInputOnly)

## If `true` (default) then only [method Node._unhandled_input] is processed to catch the input events that are NOT consumed by other components/scripts/nodes.
## If `false` then [method Node._input] is processed, to catch ALL events, even if they were already handled by other nodes.
@export var shouldProcessUnhandledInputOnly: bool = true:
	set(newValue):
		if newValue != shouldProcessUnhandledInputOnly:
			shouldProcessUnhandledInputOnly = newValue
			self.set_process_input(isEnabled and not shouldProcessUnhandledInputOnly)
			self.set_process_unhandled_input(isEnabled and shouldProcessUnhandledInputOnly)

## The list of input actions to watch for and include in [member inputActionsPressed].
## Because dummy Godot doesn't let us directly get all the input actions from an [InputEvent],
## we have to manually check every possibility, so here we shorten that list of possible events.
const inputActionsToMonitor: PackedStringArray = [
	GlobalInput.Actions.jump,
	GlobalInput.Actions.fire,
	GlobalInput.Actions.interact,
	]

#endregion


#region State

## A list of all the input actions from [member inputActionsToMonitor] that are currently pressed.
var inputActionsPressed: PackedStringArray

var previousMovementDirection:	Vector2
var movementDirection:			Vector2: ## The primary movmeent input from the combined horizontal + vertical axes. Includes the Left Joystick & the D-pad.
	set(newValue):
		if newValue != movementDirection:
			# NOTE: Do not count "echoes" (repeated events generated when the same input is pressed and held) as changes in the input!
			if not lastInputEvent.is_echo(): previousMovementDirection = movementDirection
			movementDirection = newValue

var horizontalInput:	float ## The primary X axis. Includes the Left Joystick & the D-pad.
var verticalInput:		float ## The primary Y axis. Includes the Left Joystick & the D-pad.

var lookDirection:		Vector2 ## The Right Joystick.
var turnInput:			float ## The horizontal X axis for the Left Joystick ONLY (NOT D-pad). May be identical to [member horizontalInput]
var thrustInput:		float ## The vertical Y axis for the Left Joystick ONLY (NOT D-pad). May be the INVERSE of [member verticalInput] because Godot's Y axis is negative for UP, but for joystick input UP is POSITIVE.

var lastInputEvent:		InputEvent ## The most recent [InputEvent] processed. NOTE: Only input "action" events where [method InputEvent.is_action_type] are included.

#endregion


#region Signals
# TBD: Signals for axis updates?
signal didProcessInput(event: InputEvent)
signal didUpdateInputActionsList ## Emitted when the list of [member inputActionsPressed] is updated.
#endregion


func _ready() -> void:
	# Update the input actions that were pressed/released BEFORE this component is ready.
	updateInputActionsPressed()
	# Apply setters because Godot doesn't on initialization
	self.set_process(debugMode)
	self.set_process_input(isEnabled and not shouldProcessUnhandledInputOnly)
	self.set_process_unhandled_input(isEnabled and shouldProcessUnhandledInputOnly)


#region Update

func _input(event: InputEvent) -> void:
	# Checked by property setters: if isEnabled and not shouldProcessUnhandledInputOnly:
	if event is InputEventMouseMotion: return
	if debugMode: printDebug(str("_input(): ", event))
	handleInput(event)


func _unhandled_input(event: InputEvent) -> void:
	# Checked by property setters: if isEnabled and shouldProcessUnhandledInputOnly:
	if event is InputEventMouseMotion: return
	if debugMode: printDebug(str("_unhandled_input(): ", event))
	handleInput(event)


func handleInput(event: InputEvent) -> void:
	# NOTE: For joystick input, events will be raised TWICE: once for both the X and Y axes.

	if not event.is_action_type(): return
	self.lastInputEvent = event
	updateInputActionsPressed(event)

	# TBD: CHECK: PERFORMANCE: Use a bunch of `if`s to update state properties only when there is a relevant matching input event?
	
	# NOTE: Do NOT check is_action_pressed() or is_action_released()
	# because even if 1 directional input is pressed/released, an entire axis must be updated from the state of 2 input actions.
	# Analog joystick fractional input strengths must also be accounted for.
	if event.is_action(GlobalInput.Actions.moveLeft)	\
	or event.is_action(GlobalInput.Actions.moveRight)	\
	or event.is_action(GlobalInput.Actions.moveUp)		\
	or event.is_action(GlobalInput.Actions.moveDown):

		self.movementDirection	= Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
		self.horizontalInput	= Input.get_axis(GlobalInput.Actions.moveLeft,	 GlobalInput.Actions.moveRight)
		self.verticalInput		= Input.get_axis(GlobalInput.Actions.moveUp,	 GlobalInput.Actions.moveDown)

	self.lookDirection			= Input.get_vector(GlobalInput.Actions.lookLeft, GlobalInput.Actions.lookRight, GlobalInput.Actions.lookUp, GlobalInput.Actions.lookDown)
	self.turnInput				= Input.get_axis(GlobalInput.Actions.turnLeft, 	 GlobalInput.Actions.turnRight)
	self.thrustInput			= Input.get_axis(GlobalInput.Actions.moveBackward, GlobalInput.Actions.moveForward)

	didProcessInput.emit(event)
	# TODO: CHECK: Does this work for joystick input?


func updateInputActionsPressed(_event: InputEvent = null) -> void:
	# DESIGN: Do NOT just listen for `event.is_action_pressed()` etc., poll the state of ALL input actions,
	# to make sure that [inputActionsPressed] also includes input actions that were pressed BEFORE this component received its first event.
	
	# TBD: CHECK: PERFORMANCE: What's faster? Just create a new array each time or modify an existing one?	
	var inputActionsPressedNew: PackedStringArray

	for inputActionToMonitor: StringName in inputActionsToMonitor:
		if Input.is_action_pressed(inputActionToMonitor):
			inputActionsPressedNew.append(inputActionToMonitor)

	if self.inputActionsPressed != inputActionsPressedNew: # TODO: VERIFY: Can 2 different arrays be compared with `==`?
		didUpdateInputActionsList.emit()

	self.inputActionsPressed = inputActionsPressedNew 

#endregion


#region Debugging

func _process(_delta: float) -> void:
	showDebugInfo()


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList[str("\n —", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.actionsPressed		= inputActionsPressed
	Debug.watchList.previousMovementDirection	= previousMovementDirection
	Debug.watchList.movementDirection	= movementDirection
	Debug.watchList.lookDirection		= lookDirection
	Debug.watchList.horizontalInput		= horizontalInput
	Debug.watchList.verticalInput		= verticalInput
	Debug.watchList.turnInput			= turnInput
	Debug.watchList.thrustInput			= thrustInput

#endregion
