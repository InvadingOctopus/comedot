## A basic "state machine" implemented as a list of [StringName]s representing any kind of state in any subsystem,
## where each state also contains a list of other states it is allowed to transition to,
## effectively creating a transition graph or flow chart.

class_name StateMachine
extends Resource

#region Parameters

## A [Dictionary] where each [StringName] key is the name of a state,
## and each state is associated with a [PackedStringArray] list of other state names that it can transition to.
@export var states:			Dictionary[StringName, PackedStringArray]

@export var initialState:	StringName = states.keys().front() if not states.is_empty() else &"" # CHECK: This kind of assignment doesn't work currently in Godot

@export var debugMode:		bool

#endregion


#region State

## The current state.
## Modifying this property may call [method validateTransition] & [method overrideTransition] to approve changes.
@export_storage var currentState: StringName:
	set(newValue):
		if newValue != currentState:
			if debugMode: Debug.printChange("currentState", currentState,  newValue, true) # logAsTrace

			# NOTE: emit_changed() in case UI/Godot Editor/debug views are observing this Resource

			# Always allow resetting to an empty state
			if newValue.is_empty():
				currentState = newValue
				emit_changed()

			# Allow initializing an empty state to any available state
			elif currentState.is_empty():
				if validateState(newValue):
					currentState = newValue
					emit_changed()
				else:
					Debug.printWarning("currentState: Invalid initialization → missing state: &\"" + newValue + "\"", logName)

			# Allow valid transitions
			elif shouldSkipNextValidationForStateSetter or validateTransition(currentState, newValue):
				currentState = newValue
				emit_changed()

			shouldSkipNextValidationForStateSetter = false

## Skips the call to [method validateTransition] when modifying [member currentState]
## PERFORMANCE: Used by [method transitionToState] to avoid a second redundant call.
## ALERT: FOR INTERNAL USE ONLY!
var shouldSkipNextValidationForStateSetter: bool = false

var logName: String:
	get: return str(self.get_script().get_global_name(), " ", self, " ", self.name)

#endregion


#region Signals
signal willTransition(outgoingState:	 StringName, incomingState:	StringName)
signal didTransition(previousState:		 StringName, newState:		StringName)
signal didRejectTransition(sourceState:	 StringName, rejectedState:	StringName)
#endregion



#region Interface

## Resets [member currentState] to [member initialState] if any, otherwise to the first state from [member states]
## If there is no valid state available, [member currentState] is cleared to an empty string. 
func resetState() -> void:
	shouldSkipNextValidationForStateSetter = true ## TBD: Should resets bypass transition validation?
	if validateState(initialState): currentState = initialState
	elif not states.is_empty():		currentState = states.keys().front()
	else:							currentState = &"" # TBD: Log warning?
	shouldSkipNextValidationForStateSetter = false # Just in case


## Returns `true` if [param state] is not an empty [StringName] and is listed in the [member states] [Dictionary]
func validateState(state: StringName) -> bool:
	return not state.is_empty() and states.has(state)


func getNextStates(sourceState: StringName = self.currentState) -> PackedStringArray:
	if sourceState.is_empty():		return []
	elif states.has(sourceState):	return states[sourceState]
	else:
		Debug.printWarning("getNextStates() from invalid state: &\"" + sourceState + "\"", logName)
		return []


## Checks to ensure [param sourceState] → [param requestedState] is a valid transition,
## then calls [method overrideTransition] which may be implemented by subclasses to add further conditions.
func validateTransition(sourceState: StringName, requestedState: StringName) -> bool:
	if debugMode: printLog("validateTransition(): " + sourceState + " → " + requestedState)

	if sourceState == requestedState: return true

	if not states.has(sourceState):
		Debug.printWarning("validateTransition() Missing source state: &\"" + sourceState + "\" → &\"" + requestedState + "\"", logName)
		return false

	if not states.has(requestedState): 
		Debug.printWarning("validateTransition(): &\"" + sourceState + "\" → Missing next state: &\"" + requestedState + "\"", logName)
		return false
	
	if not getNextStates(sourceState).has(requestedState): 
		Debug.printWarning("validateTransition(): &\"" + sourceState + "\" → Requested state not in allowed transitions: &\"" + requestedState + "\"", logName)
		return false

	if overrideTransition(sourceState, requestedState):
		return true
	else:
		printLog("validateTransition() rejected by overrideTransition(): &\"" + sourceState + "\" → &\"" + requestedState + "\"") # Game-specific rejections don't warrant an automatic warning
		return false


func transitionToState(nextState: StringName) -> bool:
	if debugMode: printLog("transitionToState(): &\"" + self.currentState + "\" → &\"" + nextState + "\"")

	if nextState == self.currentState: return true # If we're already in the requested state, we already succeeded!

	if not validateTransition(self.currentState, nextState):
		didRejectTransition.emit(self.currentState, nextState)
		return false

	var previousState: StringName = self.currentState # JIC: Capture `currentState` in case `willTransition` handlers modify it
	willTransition.emit(previousState, nextState)
	# TBD: Add a veto/rejection hook here for signal handlers?
	
	shouldSkipNextValidationForStateSetter = true  # PERFORMANCE: `currentState` property setter calls validateTransition() too, so skip this redundant call!
	self.currentState = nextState
	shouldSkipNextValidationForStateSetter = false # JIC: `currentState` setter resets it, but let's do it again to be sure :')
	
	didTransition.emit(previousState, self.currentState)
	return true

#endregion


#region Abstract Hooks

## May be implemented in subclasses to add extra dynamic conditions between state transitions or reject transitions.
func overrideTransition(sourceState: StringName, requestedState: StringName) -> bool:
	if debugMode: printLog("overrideTransition(): &\"" + sourceState + "\" → &\"" + requestedState + "\"")
	return true

#endregion


#region Debugging
func printLog(message: String) -> void:
	if debugMode: Debug.printResourceLog(message, self.logName)
#endregion
