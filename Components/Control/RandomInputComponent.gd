## A subclass of [InputComponent] that generates random input events on a [Timer] interval or other signals.
## TIP: EXAMPLE USAGE: A demo/"attract mode", random monster/NPC movement etc.
## TIP: The [method performRandomAction] may be connected to signals such as [signal TurnBasedCoordinator.isReadyToStartTurn] etc.
## NOTE: If random input should be generated on external signals only, this component's [Timer] should be disabled.

class_name RandomInputComponent
extends InputComponent


#region Parameters

const movementDirectionKey	:= &"randomMovementDirections"
const aimDirectionKey		:= &"randomAimDirections"

## A [Dictionary] of possible [InputEventAction] [StringName]s (see [class GlobalInput.Actions]) and their "weights" that will be randomly generated from [method performRandomAction]
## NOTE: A key named `&"randomMovementDirections"` will choose from [member randomMovementDirections]
## NOTE: A key named `&"randomAimDirections"` will choose from [member randomAimDirections]
## NOTE: Add an empty `&""` key to include an "idle" or "do nothing" or "skip" option.
@export var randomActions: Dictionary[StringName, float] = {
	&"":						0.5, # The "idle" or "do nothing" option
	movementDirectionKey:		1.0,
	aimDirectionKey:			0.5,
	GlobalInput.Actions.jump:	1.0,
	GlobalInput.Actions.fire:	1.0,
	}

## A list of [Vector2] directions to randomly pick from and apply to [member InputComponent.movementDirection]
## IMPORTANT: To use, add a key named `&"randomMovementDirections"` to [member randomActions]
## NOTE: If this action is chosen but the list is empty, then no action will be performed.
## NOTE: Every direction in this list has an equal chance to being chosen.
## NOTE: [member movementDirectionScale] will be applied to any randomly chosen direction.
@export var randomMovementDirections:	PackedVector2Array = GlobalInput.directions

## A list of [Vector2] directions to randomly pick from and apply to [member InputComponent.aimDirection]
## IMPORTANT: To use, add a key named `&"randomAimDirections"` to [member randomActions]
## NOTE: If this action is chosen but the list is empty, then no action will be performed.
## NOTE: Every direction in this list has an equal chance to being chosen.
## NOTE: [member aimDirectionScale] will be applied to any randomly chosen direction.
@export var randomAimDirections:		PackedVector2Array = GlobalInput.directions

@export_range(0, 1.0, 0.01) var generatedInputStrength: float = 1.0

@export var shouldGenerateGlobalEvents:	bool = false

@export var shouldIgnoreReceivedEvents:	bool = true:
	set(newValue):
		if newValue != shouldIgnoreReceivedEvents:
			shouldIgnoreReceivedEvents = newValue
			setProcessing()

#endregion


#region State
var lastAction:			StringName ## The key that was randomly chosen from [member randomActions] by the last call to [method performRandomAction]
var lastGeneratedEvent:	InputEvent ## NOTE: `null` if any [member randomMovementDirections] or [member randomAimDirections] was chosen.
#endregion


#region Initialization

func _ready() -> void:
	super._ready()
	setProcessing()


## Overrides [method InputComponent.setProcessing]
func setProcessing() -> void:
	self.set_process(debugMode)
	self.set_process_input(			 not shouldIgnoreReceivedEvents and isEnabled and isPlayerControlled and not shouldProcessUnhandledInputOnly)
	self.set_process_unhandled_input(not shouldIgnoreReceivedEvents and isEnabled and isPlayerControlled and shouldProcessUnhandledInputOnly)

#endregion


#region Superclass Overrides

## Trap events just in case set_process_input() was re-enabled.
func _input(event: InputEvent) -> void:
	if not shouldIgnoreReceivedEvents: super._input(event)


## Trap events just in case set_process_unhandled_input() was re-enabled.
func _unhandled_input(event: InputEvent) -> void:
	if not shouldIgnoreReceivedEvents: super._unhandled_input(event)

#endregion


#region Random Input

## Picks and emits a random input action from [member randomActions]
## May include [member randomMovementDirections] and [member randomAimDirections]
## TIP: This method may be connected to signals such as [signal TurnBasedCoordinator.isReadyToStartTurn] or [signal TurnBasedEntity.willExecuteTurn] etc. (remember to disable this component's [Timer] if it's not required)
func performRandomAction() -> InputEvent:
	lastGeneratedEvent  = null # Clear any previous references

	if not isEnabled:
		lastAction = &""
		return null

	lastAction = pickRandomAction()

	if lastAction.is_empty():
		if debugMode: printDebug("performRandomAction() empty lastAction: clearing all input state")
		clearAllInputs()
		return null

	# DESIGN: If the random movement/aim direction list is chosen but empty, it's considered a no-op
	# to allow for dynamic modification of the direction arrays etc.

	# Movement Direction?
	elif lastAction == movementDirectionKey:
		if not randomMovementDirections.is_empty():
			setMovementInputs(Tools.pickRandom(randomMovementDirections))
		elif debugMode: printWarning("performRandomAction(): randomMovementDirections chosen but empty")
		lastAction = movementDirectionKey

	# Aim Direction?
	elif lastAction == aimDirectionKey:
		if not randomAimDirections.is_empty():
			aimDirection = Tools.pickRandom(randomAimDirections) * aimDirectionScale
		elif debugMode: printWarning("performRandomAction(): randomAimDirections chosen but empty")
		lastAction = aimDirectionKey

	# An action?
	else:
		lastGeneratedEvent = generateEvent(lastAction, shouldGenerateGlobalEvents, true, generatedInputStrength)
		if shouldGenerateGlobalEvents and shouldIgnoreReceivedEvents and isPlayerControlled and lastGeneratedEvent:
			# NOTE: If all these flags are true, then RandomInputComponent's _input()/_unhandled_input() will not handle its own generated event!
			# because if shouldGenerateGlobalEvents & isPlayerControlled then InputComponent.generateEvent() does not handle the event locally; it assumes global events will reach _input()/_unhandled_input()
			# So we should handle it ourselves right here :)
			handleEvent(lastGeneratedEvent)

	if debugMode: printDebug(str("performRandomAction() lastAction: ", lastAction, ", lastGeneratedEvent: ", lastGeneratedEvent))
	return lastGeneratedEvent


## Calls [method Tools.pickRandomFromWeightsDictionary] to return a key from [member randomActions]
func pickRandomAction() -> StringName:
	if debugMode:
		var randomAction: StringName = Tools.pickRandomFromWeightsDictionary(randomActions, &"") as StringName
		printDebug("pickRandomAction(): " + randomAction)
		return randomAction
	else:
		return Tools.pickRandomFromWeightsDictionary(randomActions, &"") as StringName


func onTimeout() -> void:
	performRandomAction()

#endregion
