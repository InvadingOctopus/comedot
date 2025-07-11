## A unified source of control input for other components to act upon. The source may be a meatspace player or AI agent script or a "demo/attract" recording etc.
## A main advantage of having a shared input state versus checking [method Node._input] directly, is that other components/scripts can modify the shared state. e.g. a [PlatformerPatrolComponent] "injecting" movement into a [PlatformerPhysicsComponent].
## NOTE: Does NOT check mouse motion input.
## ATTENTION: If mouse input events are not reaching this component, check the [member Control.mouse_filter] property of any overlaying nodes,
## and set it to [const Control.MOUSE_FILTER_PASS] or [const Control.MOUSE_FILTER_IGNORE].
## NOTE: To improve performance, small independent components may do their own input polling. Therefore, this [InputComponent] makes most sense when a chain of multiple components depend upon it, such as [TurningControlComponent] + [ThrustControlComponent].
## TIP: Other components/scripts should check the DERIVED properties like [member horizontalInput] instead of directly processing an [InputEvent] on their own.
## TIP: May be subclassed for AI-control or pre-recorded demos or "attract mode" etc.
## Requirements: AFTER (below in the Scene Tree) all components that depend on player/AI control, because input events propagate UPWARD from the BOTTOM of the Scene Tree nodes list.

class_name InputComponent
extends Component


#region Parameters

## Disables all input processing & updates.
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.setProcess()
			if not isEnabled: resetState()

## If `false` then system input events are not processed,
## but this component may still be manually modified and used by other components, such as AI agents or demo scripts.
## [method handleInput] & [method updateInputActionsPressed] may be called manually at any time,
## e.g. to process synthetic [InputEvent]s generated by gameplay code.
## IMPORTANT: Turn this OFF for enemies & NPCs!
@export var isPlayerControlled: bool = true:
	set(newValue):
		if newValue != isPlayerControlled:
			isPlayerControlled = newValue
			self.setProcess()

## Multiplies each of the [param movementDirection]'s axes, i.e. the primary movement control, including the Left Joystick & D-pad.
## TIP: Negative values invert player/AI control. e.g. (-1, 1) will flip the horizontal walking direction.
@export var movementDirectionScale:	Vector2 = Vector2.ONE

## Multiplies each of the [param aimDirection]'s axes, which is usually provided by the Right Joystick.
## TIP: Negative values invert the camera control, e.g. (1, -1) will flip the vertical camera axis.
@export var aimDirectionScale:		Vector2 = Vector2.ONE

@export_group("Joystick vs Mouse")

## If `true`, then any movement of any gamepad joystick sets [member shouldSuppressMouseMotion] if [member movementDirection] is not (0,0).
## This resolves conflicts between components such as [MouseTrackingComponent] vs. [PositionControlComponent],
## allowing the player to move with the Left Joystick (for example) by temporarily ignoring mouse motion.
## Clicking any mouse button reenables mouse-controlled movement/aiming.
@export var shouldJoystickMovementSuppressMouse: bool = false

## If `true`, then any movement of any gamepad joystick sets [member shouldSuppressMouseMotion] if [member aimDirection] is not (0,0).
## This resolves conflicts between components such as [MouseRotationComponent] vs. [TurningControlComponent],
## allowing the player to aim a gun or move a cursor with the Right Joystick (for example) by temporarily ignoring mouse motion.
## Clicking any mouse button reenables mouse-controlled movement/aiming.
@export var shouldJoystickAimingSuppressMouse:   bool = true


@export_group("Event Processing")

## If `true` (default) then only [method Node._unhandled_input] is processed to catch the input events that are NOT consumed by other components/scripts/nodes.
## If `false` then [method Node._input] is processed, to catch ALL events, even if they were already handled by other nodes.
@export var shouldProcessUnhandledInputOnly: bool = true:
	set(newValue):
		if newValue != shouldProcessUnhandledInputOnly:
			shouldProcessUnhandledInputOnly = newValue
			self.setProcess()

## If `true` (default) then an [InputEvent] is ignored if [method InputEvent.is_echo],
## i.e. a repeated event "echo" generated while holding a button or key pressed down.
@export var shouldIgnoreEchoes: bool = true # TBD: Should this default to `true`?

## If `true`, then [InputEvent]s are prevented from bubbling up the Scene Tree if they include any of the input actions processed by this component, such as movement, jumping, shooting etc.
## May improve performance.
## ALERT: This will prevent any OTHER [InputComponent]s from receiving events! Use this when ONLY ONE character should be controlled.
@export var shouldSetEventsAsHandled: bool = false # DESIGN: Let's default to `false` because disabling event propagation should be an explicit decision: we may forget about it and wonder why other scripts aren't receiving input.

## The list of input actions to watch for and include in [member inputActionsPressed].
## Because dummy Godot doesn't let us directly get all the input actions from an [InputEvent],
## we have to manually check every possibility, so here we shorten that list of possible events.
@export var inputActionsToMonitor: PackedStringArray = [
	GlobalInput.Actions.jump,
	GlobalInput.Actions.fire,
	GlobalInput.Actions.interact,
	]

#endregion


#region State
# TBD: @export_storage

## A list of all the input actions from [const inputActionsToMonitor] that are currently pressed.
var inputActionsPressed: PackedStringArray

var previousMovementDirection:	Vector2
var movementDirection:			Vector2: ## The primary movmeent input from the combined horizontal + vertical axes. Includes the Left Joystick & the D-pad.
	set(newValue):
		if newValue != movementDirection:
			# NOTE: Do not count "echoes" (repeated events generated when the same input is pressed and held) as changes in the input!
			if lastInputEvent and not lastInputEvent.is_echo(): previousMovementDirection = movementDirection # Check for `lastInputEvent` in case some other component is directly modifying this property for the first time.
			movementDirection = newValue

var lastNonzeroHorizontalInput:	float  ## The last NON-ZERO [member horizontalInput] received. May be used to determine where a character should be facing etc.
var horizontalInput:			float: ## The primary X axis. Includes the Left Joystick & the D-pad.
	set(newValue):
		if newValue != horizontalInput:
			horizontalInput = newValue
			if not is_zero_approx(horizontalInput):
				if signf(lastNonzeroHorizontalInput) != signf(horizontalInput): # NOTE: Emit signals ONLY IF the direction CHANGES, not when movement STOPS.
					if debugMode: printDebug(str("didChangeHorizontalDirection: ", lastNonzeroHorizontalInput, " → ", horizontalInput))
					didChangeHorizontalDirection.emit()
				lastNonzeroHorizontalInput = horizontalInput

var lastNonzeroVerticalInput:	float  ## The last NON-ZERO [member verticalInput] received. May be used to determine where a character should be facing etc.
var verticalInput:	 			float: ## The primary Y axis. Includes the Left Joystick & the D-pad.
	set(newValue):
		if newValue != verticalInput:
			verticalInput = newValue
			if not is_zero_approx(verticalInput):
				if signf(lastNonzeroVerticalInput) != signf(verticalInput):  # NOTE: Emit signals ONLY IF the direction CHANGES, not when movement STOPS.
					if debugMode: printDebug(str("didChangeVerticalDirection: ",   lastNonzeroVerticalInput, " → ", verticalInput))
					didChangeVerticalDirection.emit()
				lastNonzeroVerticalInput = verticalInput
	
var aimDirection:		Vector2 ## The Right Joystick. May be used as the "look" direction for moving the camera, or for aiming in dual-stick shoot-em-ups etc.
var turnInput:			float ## The horizontal X axis for the Left Joystick ONLY (NOT D-pad). May be identical to [member horizontalInput]. TBD: Include D-Pad?
var thrustInput:		float ## The vertical Y axis for the Left Joystick ONLY (NOT D-pad). May be the INVERSE of [member verticalInput] because Godot's Y axis is negative for UP, but for joystick input UP is POSITIVE. TBD: Include D-Pad?

var lastInputEvent:		InputEvent ## The most recent [InputEvent] received by [method handleInput]. NOTE: Only input "action" events where [method InputEvent.is_action_type] are included.

## If `true`, then the next [method _input] or [method _unhandled_input] is skipped ONCE, and then this flag is reset.
## May be used to temporarily suppress player control, e.g. to implement automatic/scripted movement etc.
var shouldSkipNextEvent:bool = false

## If [member shouldJoystickAimingSuppressMouse], then any movement of any gamepad joystick sets this flag if [member aimDirection] is not (0,0).
## This resolves conflicts between components such as [MouseRotationComponent] vs. [TurningControlComponent],
## allowing the player to aim a gun or move a cursor with the Right Joystick (for example) by temporarily ignoring mouse motion.
## Clicking any mouse button disables this flag.
var shouldSuppressMouseMotion: bool = false:
	set(newValue):
		if newValue != shouldSuppressMouseMotion:
			shouldSuppressMouseMotion = newValue
			didToggleMouseSuppression.emit(shouldSuppressMouseMotion)

#endregion


#region Signals
# TBD: Signals for axis updates?

## Emitted when an [InputEvent] includes one of the [member inputActionsToMonitor] and the list of [member inputActionsPressed] is updated.
## NOTE: BEFORE [signal didProcessInput].
signal didUpdateInputActionsList(event: InputEvent)

## Emitted after an [InputEvent] has been fully processed and all state properties have been updated.
## NOTE: AFTER [signal didUpdateInputActionsList].
## TIP: Other components/scripts should check the DERIVED properties like [member horizontalInput] instead of directly processing an [InputEvent] on their own.
signal didProcessInput(event: InputEvent)

## Emitted when [member horizontalInput] and [member lastNonzeroHorizontalInput] have an OPPOSITE SIGN (positive/negative), signifying a flip between right ↔ left.
## 0 input is ignored, i.e. when movement stops but the direction doesn't change.
## May be used for sprite flipping and other animations etc.
signal didChangeHorizontalDirection

## Emitted when [member verticalInput] and [member lastNonzeroVerticalInput] have an OPPOSITE SIGN (positive/negative), signifying a flip between up ↔ down.
## 0 input is ignored, i.e. when movement stops but the direction doesn't change.
## May be used for sprite flipping and other animations etc.
signal didChangeVerticalDirection

## Emitted when [member shouldSuppressMouseMotion] is changed.
## Components such as [MouseRotationComponent] & [TurningControlComponent] must monitor this signal,
## to allow the player to aim a gun or move a cursor with the Right Joystick (for example) by temporarily ignoring mouse motion.
signal didToggleMouseSuppression(shouldSuppressMouse: bool)

#endregion


#region Initialization

func _ready() -> void:
	# Update the input actions that were pressed/released BEFORE this component is ready.
	processMonitoredInputActions()
	setProcess() # Apply setters because Godot doesn't on initialization


## Enables or disables the per-frame and event process based on flags.
func setProcess() -> void:
	self.set_process(debugMode)
	self.set_process_input(isEnabled and isPlayerControlled and not shouldProcessUnhandledInputOnly)
	self.set_process_unhandled_input(isEnabled and isPlayerControlled and shouldProcessUnhandledInputOnly)

#endregion


#region Update

## Affected by [member isEnabled], [member isPlayerControlled] and [member shouldProcessUnhandledInputOnly].
## May be skipped ONCE by [member shouldSkipNextEvent].
func _input(event: InputEvent) -> void:
	# Checked by property setters: if isEnabled and not shouldProcessUnhandledInputOnly:
	if event is InputEventMouseMotion: return
	if shouldSkipNextEvent:
		shouldSkipNextEvent = false
		return
	if debugMode: printDebug(str("_input(): ", event))
	handleInput(event)


## Affected by [member isEnabled], [member isPlayerControlled] and [member shouldProcessUnhandledInputOnly].
## May be skipped ONCE by [member shouldSkipNextEvent].
func _unhandled_input(event: InputEvent) -> void:
	# Checked by property setters: if isEnabled and shouldProcessUnhandledInputOnly:
	if event is InputEventMouseMotion: return
	if shouldSkipNextEvent:
		shouldSkipNextEvent = false
		return
	if debugMode: printDebug(str("_unhandled_input(): ", event))
	handleInput(event)


## Affected by [member isEnabled] but NOT affected by [member isPlayerControlled], to allow control by AI/code.
## NOTE: NOT affected by [member shouldSkipNextEvent], to allow manual processing of synthetic [InputEvent]s etc.
func handleInput(event: InputEvent) -> void:
	# NOTE: For joystick input, events will be raised TWICE: once each for the X and Y axes.

	if not isEnabled: return

	# If we were suppressing mouse movement to prioritize the secondary joystick
	# and the player clicked ANY mouse button, un-suppress the mouse.
	if self.shouldSuppressMouseMotion and event is InputEventMouseButton and event.is_pressed():
		self.shouldSuppressMouseMotion = false

	# All other events should only be processed if they match a registered input action and are not "echoes"
	if not event.is_action_type() \
	or (self.shouldIgnoreEchoes and event.is_echo()):
		return

	self.lastInputEvent = event

	if processMonitoredInputActions(event) and shouldSetEventsAsHandled:
		self.get_viewport().set_input_as_handled()

	# TBD: CHECK: PERFORMANCE: Use a bunch of `if`s to update state properties only when there is a relevant matching input event?

	# NOTE: Do NOT check is_action_pressed() or is_action_released()
	# because even if 1 directional input is pressed/released, an entire axis must be updated from the state of 2 input actions.
	# Analog joystick fractional input strengths must also be accounted for.

	# Primary Movement

	if event.is_action(GlobalInput.Actions.moveLeft)	\
	or event.is_action(GlobalInput.Actions.moveRight)	\
	or event.is_action(GlobalInput.Actions.moveUp)		\
	or event.is_action(GlobalInput.Actions.moveDown):

		self.movementDirection	= Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown) * movementDirectionScale
		# TBD: Get the individual axes again or just copy from `movementDirection`?
		self.horizontalInput	= Input.get_axis(GlobalInput.Actions.moveLeft,	 GlobalInput.Actions.moveRight) * movementDirectionScale.x
		self.verticalInput		= Input.get_axis(GlobalInput.Actions.moveUp,	 GlobalInput.Actions.moveDown)  * movementDirectionScale.y

		if shouldSetEventsAsHandled: self.get_viewport().set_input_as_handled()

	# Aim/Turn/Thrust

	self.aimDirection	= Input.get_vector(GlobalInput.Actions.aimLeft, GlobalInput.Actions.aimRight, GlobalInput.Actions.aimUp, GlobalInput.Actions.aimDown) * aimDirectionScale
	self.turnInput		= Input.get_axis(GlobalInput.Actions.turnLeft,	   GlobalInput.Actions.turnRight)
	self.thrustInput	= Input.get_axis(GlobalInput.Actions.moveBackward, GlobalInput.Actions.moveForward)

	# Let the Stick rule over Mice?

	if event is InputEventJoypadMotion \
	and ((shouldJoystickMovementSuppressMouse and not self.movementDirection.is_zero_approx())
		or (shouldJoystickAimingSuppressMouse and not self.aimDirection.is_zero_approx())):
			self.shouldSuppressMouseMotion = true
	
	# TODO: self.get_viewport().set_input_as_handled() for the other input actions we handled.

	if debugMode: showDebugInfo()
	didProcessInput.emit(event)


## Updates [member inputActionsPressed].
## Affected by [member isEnabled] but NOT affected by [member isPlayerControlled], to allow control by AI/code.
## Returns `true` if [param event] contains one of the input actions included in [const inputActionsToMonitor].
func processMonitoredInputActions(event: InputEvent = null) -> bool:
	if not isEnabled: return false

	# DESIGN: Do NOT just listen for `event.is_action_pressed()` etc., poll the state of ALL input actions,
	# to make sure that [inputActionsPressed] also includes input actions that were pressed BEFORE this component received its first event.

	# TBD: CHECK: PERFORMANCE: What's faster? Just create a new array each time or modify an existing one?
	var inputActionsPressedNew: PackedStringArray
	var isEventMonitored: bool # Does the received InputEvent include one of the input actions we monitor?

	for inputActionName: StringName in inputActionsToMonitor:
		if Input.is_action_pressed(inputActionName): # Check all input actions, not just the ones in the current event, in case they were pressed before this component was ready
			inputActionsPressedNew.append(inputActionName)

		if event and event.is_action(inputActionName): # Check event because it may be null when doing a manual update
			isEventMonitored = true

	# Did we consume an InputEvent for one of the input actions we monitor?
	if isEventMonitored:
		self.inputActionsPressed = inputActionsPressedNew
		didUpdateInputActionsList.emit(event)
		if debugMode: GlobalSonic.beep(0.1, 440)

	return isEventMonitored

#endregion


#region Modification

## Sets all properties to 0
## NOTE: EXCEPT the "should" flags: [shouldSkipNextEvent], [member shouldSuppressMouseMotion]
func resetState() -> void: 
	inputActionsPressed.clear()
	previousMovementDirection	= Vector2.ZERO
	movementDirection			= Vector2.ZERO
	lastNonzeroHorizontalInput	= 0
	horizontalInput				= 0
	lastNonzeroVerticalInput	= 0
	verticalInput				= 0
	aimDirection				= Vector2.ZERO
	turnInput					= 0
	thrustInput					= 0
	lastInputEvent				= null


## Directly modifies the [member movementDirection], applies scaling, and updates [member horizontalInput] & [member verticalInput] accordingly.
func setMovementDirection(newDirection: Vector2, scaleOverride: Vector2 = self.movementDirectionScale) -> void:
	# TBD: Emit signals?
	self.movementDirection	= newDirection * scaleOverride
	self.horizontalInput	= movementDirection.x
	self.verticalInput		= movementDirection.y

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
		aimDirection		= aimDirection,
		horizontalInput		= horizontalInput,
		verticalInput		= verticalInput,
		turnInput			= turnInput,
		thrustInput			= thrustInput
		})

#endregion
