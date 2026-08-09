## A [StateMachine] subclass that adds optional [Timer] delays between state transitions.
## IMPORTANT: A [Timer] must be provided by the caller and must be [member timer.one_shot]
## USAGE: Call [method TimedStateMachine.transitionToState] with `await` to wait for delay before proceeding,
## or call without `await` then do the rest of the processing in the signal handler for [signal didTransition] etc.

class_name TimedStateMachine
extends StateMachine


#region Parameters
## To avoid the [Timer] error: "Time should be greater than zero" and other jank from being TOO fast.
## According to Godot documentation, it should be 0.05
const minimumDelay: float = 0.05

## A [Dictionary] map of State → {State: Delay}
## where the key is the outgoing state, and the value is another sub-[Dictionary] of [Incoming State: Delay in Seconds] pairs.
## NOTE: If a state is not listed, then [member defaultDelay] is used.
## NOTE: A value of <[constant minimumDelay] means no delay and ignores [member defaultDelay]
## EXAMPLE: `{ &"reloading": { &"readyToFire": 3.0 } }` waits 3 seconds when going from `reloading` → `readyToFire`
## `{ &"walk": { &"jump": 0.5, &"fly": 1.0 } }` = 500 milliseconds from `walk` → `jump` & 1 second before `walk` → `fly`
@export var delaysBetweenStates: Dictionary[StringName, Dictionary]

## The [member Timer.wait_time] that will be used for the [member timer] even when there is no matching mapping for a transition in [member delaysBetweenStates]
## A value of <[constant minimumDelay] means no delay for unlisted transitions.
@export_range(0, 10, 0.001, "or_greater") var defaultDelay: float:
	set(newValue):
		if newValue  < minimumDelay: newValue = 0
		if newValue != defaultDelay: defaultDelay = newValue

#endregion


#region State
## The optional [Timer] used to delay transitions.
## Must be provided and owned by an external script.
## The [member Timer.wait_time] is changed on each [method TimedStateMachine.transitionToState] call according to [member delaysBetweenStates] or [member defaultDelay]
## NOTE: If missing or not inside the current scene, all transitions occur immediately.
## NOTE: If any delay value is set to <[constant minimumDelay] then it's ignored and there is NO delay for that transition.
var timer: Timer

## Returns `true` while [method transitionToState] is awaiting [member timer]
## NOTE: Any other transition requests are rejected during this time.
var isWaitingForTimer: bool
#endregion


#region Signals
## Emitted BEFORE [member timer] starts for a transition if a delay specified.
signal willStartDelay(outgoingState: StringName, incomingState: StringName, delay: float)

## Emitted AFTER [member timer] starts for a transition if a delay specified.
signal didStartDelay(outgoingState: StringName, incomingState: StringName, delay: float)
#endregion


#region Interface

## Returns the delay for [param outgoingState] → [param incomingState] if mapped in the [member delaysBetweenStates] [Dictionary]
## [member defaultDelay] is used if the transition is not listed.
## NOTE: Delay values <[constant minimumDelay] are ignored and clamped to 0
func getDelayBetweenStates(outgoingState: StringName, incomingState: StringName) -> float:
	var fallbackDelay: float = 0.0 if (defaultDelay < minimumDelay) else defaultDelay

	var delaysFromOutgoingState: Dictionary = delaysBetweenStates.get(outgoingState, {}) # Also checks `outgoingState` presence
	if not delaysFromOutgoingState.has(incomingState): return fallbackDelay

	var configuredDelay: Variant = delaysFromOutgoingState[incomingState]
	if typeof(configuredDelay) != TYPE_FLOAT and typeof(configuredDelay) != TYPE_INT:
		Debug.printWarning(str("getDelayBetweenStates(): Delay value variable type is not float or int for &\"", outgoingState,"\" → &\"", incomingState, "\": ", type_string(typeof(configuredDelay))), logName)
		return fallbackDelay

	# TBD: PERFORMANCE: Convert to `float` just in case?
	if  configuredDelay < minimumDelay:
		if debugMode: Debug.printDebug(str("getDelayBetweenStates(): Returning 0 for delay ", configuredDelay, " < minimumDelay ", minimumDelay, " for &\"", outgoingState, "\" → &\"", incomingState, "\""), logName)
		return 0.0

	return configuredDelay


## Overrides [method StateMachine.transitionToState] to add an optional delay before performing the transition.
## If the outgoing → incoming states are not mapped in [member delaysBetweenStates] then [member defaultDelay] is used.
## NOTE: Any delay value <[constant minimumDelay] is ignored and the transition is performed immediately.
## IMPORTANT: TIP: Call with `await` to immediately wait for the delay to finish before proceeding,
## or call without `await` then do the rest of the processing in the signal handler for [signal didTransition] etc.
## NOTE: Transition requests are rejected while [member isWaitingForTimer] is `true`
func transitionToState(nextState: StringName) -> bool:
	# NOTE: Don't log here; the superclass will.
	if nextState == self.currentState: return true

	if isWaitingForTimer:
		if debugMode: Debug.printResourceLog("transitionToState() rejected while isWaitingForTimer", logName)
		didRejectTransition.emit(self.currentState, nextState)
		return false

	var outgoingState:	StringName	= self.currentState # Save in case it gets mutated by any other method/override
	var delay:			float		= getDelayBetweenStates(outgoingState, nextState)

	# Just transition immediately if there's no valid Timer or delay
	if not is_instance_valid(timer) or delay < minimumDelay:
		return super.transitionToState(nextState)

	if not timer.is_inside_tree():
		Debug.printWarning(str("transitionToState(): timer not inside the scene tree; transitioning immediately: ", timer), logName)
		return super.transitionToState(nextState)

	# Don't start a delay for invalid transitions
	# DESIGN: super.transitionToState() validates again after the delay in case conditions changed while awaiting the Timer
	if not isEnabled or not validateTransition(outgoingState, nextState):
		didRejectTransition.emit(outgoingState, nextState)
		return false

	isWaitingForTimer = true  # Don't let signal handlers etc start any more transitions
	timer.wait_time   = delay # Update for any UI handlers etc
	self.willStartDelay.emit(outgoingState, nextState, delay)
	timer.start(delay)
	self.didStartDelay.emit(outgoingState, nextState, delay)

	await timer.timeout # TBD: `await` here or complete the transition in an `onTimer_timeout()` handler?
	isWaitingForTimer = false

	# IMPORTANT: Make sure the `currentState` wasn't changed by any external code during the delay!
	if self.currentState != outgoingState:
		if debugMode: Debug.printWarning(str("transitionToState(): Original outgoing state changed during Timer delay: &\"", outgoingState, "\" → &\"", self.currentState, "\" ・　Rejecting the original transition request to &\"", nextState, "\""))
		didRejectTransition.emit(outgoingState, nextState)
		return false

	# whew, carry on as usual
	return super.transitionToState(nextState)

#endregion
