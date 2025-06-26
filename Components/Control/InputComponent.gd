## Monitors and stores the player's input for other components to act upon.
## ALERT: Does NOT check mouse motion input.
## NOTE: To improve performance, small independent components may do their own input polling. Therefore, this [InputComponent] makes most sense when a chain of multiple components depend upon it, such as [TurningControlComponent] + [ThrustControlComponent].
## TIP: May be subclassed for AI-control or pre-recorded demos or "attract mode" etc.
## Requirements: AFTER (below in the Scene Tree) all components that depend on player/AI control, because input events propagate from the BOTTOM of the Scene Tree nodes list UPWARD.

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

## If `true`, then [InputEvent] are prevented from bubbling up the Scene Tree if they include any of the input actions processed by this component, such as movement, jumping, shooting etc.
@export var shouldSetEventsAsHandled: bool = false # TODO: Start as `false` for now until we have updated/migrated all other control components to use [InputComponent]

## Multiplies each of the [param movementDirection]'s axes, i.e. the primary movement control, including the Left Joystick & D-pad.
## TIP: Negative values invert player/AI control. e.g. (-1, 1) will flip the horizontal walking direction.
@export var movementDirectionScale:	Vector2 = Vector2.ONE

## Multiplies each of the [param lookDirection]'s axes, which is usually provided by the Right Joystick.
## TIP: Negative values invert the camera control, e.g. (1, -1) will flip the vertical camera axis.
@export var lookDirectionScale:		Vector2 = Vector2.ONE

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

## A list of all the input actions from [const inputActionsToMonitor] that are currently pressed.
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

## Emitted when [member movementDirection] and [member previousMovementDirection] have a different SIGN (positive/negative) on the X axis, signifying a change/flip in direction from right ↔ left.
## May be used for sprite flipping and other animations etc.
signal didChangeHorizontalDirection

## Emitted when [member movementDirection] and [member previousMovementDirection] have a different SIGN (positive/negative) on the Y axis, signifying a change/flip in direction from up ↔ down.
## May be used for sprite flipping and other animations etc.
signal didChangeVerticalDirection
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
	
	if updateInputActionsPressed(event) and shouldSetEventsAsHandled: 
		self.get_viewport().set_input_as_handled()

	# TBD: CHECK: PERFORMANCE: Use a bunch of `if`s to update state properties only when there is a relevant matching input event?

	# NOTE: Do NOT check is_action_pressed() or is_action_released()
	# because even if 1 directional input is pressed/released, an entire axis must be updated from the state of 2 input actions.
	# Analog joystick fractional input strengths must also be accounted for.
	if event.is_action(GlobalInput.Actions.moveLeft)	\
	or event.is_action(GlobalInput.Actions.moveRight)	\
	or event.is_action(GlobalInput.Actions.moveUp)		\
	or event.is_action(GlobalInput.Actions.moveDown):

		self.movementDirection	= Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown) * movementDirectionScale
		# TBD: Get the individual axes again or just copy from `movementDirection`?
		self.horizontalInput	= Input.get_axis(GlobalInput.Actions.moveLeft,	 GlobalInput.Actions.moveRight) * movementDirectionScale.x
		self.verticalInput		= Input.get_axis(GlobalInput.Actions.moveUp,	 GlobalInput.Actions.moveDown)  * movementDirectionScale.y

		if signf(previousMovementDirection.x) != signf(movementDirection.x):
			if debugMode: printDebug(str("didChangeHorizontalDirection: ", previousMovementDirection.x, " → ", movementDirection.x))
			didChangeHorizontalDirection.emit()

		if signf(previousMovementDirection.y) != signf(movementDirection.y):
			if debugMode: printDebug(str("didChangeVerticalDirection: ", previousMovementDirection.y, " → ", movementDirection.y))
			didChangeVerticalDirection.emit()

		if shouldSetEventsAsHandled: self.get_viewport().set_input_as_handled()

	self.lookDirection	= Input.get_vector(GlobalInput.Actions.lookLeft, GlobalInput.Actions.lookRight, GlobalInput.Actions.lookUp, GlobalInput.Actions.lookDown) * lookDirectionScale
	self.turnInput		= Input.get_axis(GlobalInput.Actions.turnLeft, 	 GlobalInput.Actions.turnRight)
	self.thrustInput	= Input.get_axis(GlobalInput.Actions.moveBackward, GlobalInput.Actions.moveForward)

	# TODO: self.get_viewport().set_input_as_handled() for the other input actions we handled.

	if debugMode: showDebugInfo()
	didProcessInput.emit(event)


## Updates [member inputActionsPressed]. Affected by [member isEnabled].
## Returns `true` if [param event] contains one of the input actions included in [const inputActionsToMonitor].
func updateInputActionsPressed(event: InputEvent = null) -> bool:
	if not isEnabled: return false

	# DESIGN: Do NOT just listen for `event.is_action_pressed()` etc., poll the state of ALL input actions,
	# to make sure that [inputActionsPressed] also includes input actions that were pressed BEFORE this component received its first event.

	# TBD: CHECK: PERFORMANCE: What's faster? Just create a new array each time or modify an existing one?
	var inputActionsPressedNew: PackedStringArray
	var isEventMonitored: bool # Does the received InputEvent include one of the input actions we monitor?

	for inputActionToMonitor: StringName in inputActionsToMonitor:
		if Input.is_action_pressed(inputActionToMonitor):
			inputActionsPressedNew.append(inputActionToMonitor)

		if event and event.is_action(inputActionToMonitor): isEventMonitored = true

	# Did we consume an InputEvent for one of the input actions we monitor?
	if isEventMonitored:
		self.inputActionsPressed = inputActionsPressedNew
		didUpdateInputActionsList.emit()

	return isEventMonitored

#endregion


#region Debugging

func _process(_delta: float) -> void:
	if debugMode: showDebugInfo()


func showDebugInfo() -> void:
	# if not debugMode: return # Checked by caller
	Debug.addComponentWatchList(self, {
		actionsPressed		= inputActionsPressed,
		previousMovementDirection = previousMovementDirection,
		movementDirection	= movementDirection,
		lookDirection		= lookDirection,
		horizontalInput		= horizontalInput,
		verticalInput		= verticalInput,
		turnInput			= turnInput,
		thrustInput			= thrustInput
		})

#endregion
