## Takes player/AI input from an [InputComponent] to modify the [Entity]'s position on a [TileMapLayer] via a [TileBasedPositionComponent]
## TIP: For random monster/NPC movement use [RandomInputComponent]
## Requirements: [TileBasedPositionComponent], [InputComponent]

class_name TileBasedControlComponent
extends Component

# TODO: Allow movement on input `is_just_released`


#region Parameters

## If `false` (default) then pressing 2 inputs such as Up+Right will result in NO movement.
@export var shouldAllowDiagonals:	bool = false

## If `true` then the entity keeps moving as long as the input direction is pressed.
## If `false` then the input must be released before moving again.
## NOTE: Changing direction diagonally e.g. from Up into Up+Right counts as new input.
@export var shouldRepeatOnHeldInput:bool = true:
	set(newValue):
		if newValue != shouldRepeatOnHeldInput:
			shouldRepeatOnHeldInput = newValue

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			if self.is_node_ready(): toggleSignals()
			# TBD: Resync & poll InputComponent when re-enabled? or require a new press?
			if not isEnabled: recentInputVector = Vector2.ZERO

#endregion


#region State

var recentInputVector: Vector2i:
	set(newValue):
		if newValue != recentInputVector:
			if debugMode: Debug.printChange("recentInputVector", recentInputVector, newValue, self.debugModeTrace) # logAsTrace
			recentInputVector = newValue
			hasInput = recentInputVector.length_squared() != 0 # PERFORMANCE: length_squared() is faster than length() CHECK: Does this cause any false positives?
			Tools.toggleSignal(tileBasedPositionComponent.didArriveAtNewCell, self.onTileBasedPositionComponent_didArriveAtNewCell, self.hasInput and self.isEnabled)

var hasInput:	bool = recentInputVector.length_squared() != 0 # DESIGN: "has" instead of "have" so we can write "if someComponent.hasSomething" :)

var canMove:	bool:
	get: return hasInput and is_zero_approx(stepTimer.time_left) and not tileBasedPositionComponent.isMovingToNewCell

@onready var stepTimer: Timer = self.get_node(^".") as Timer

#endregion


#region Dependencies
@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent
@onready var inputComponent:			 InputComponent = getCoComponent(InputComponent, true) # findSubclasses

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent, InputComponent]
#endregion


func _ready() -> void:
	# Check if an input already pressed before this component was ready
	# TBD: inputComponent.resyncAllInputs()?
	if not inputComponent.movementDirection.is_zero_approx():
		self.onInputComponent_didProcessInput(null)

	# Apply setters because Godot doesn't on _ready()
	toggleSignals()
	self.set_process(self.debugMode)


#region Input

func toggleSignals() -> void:
	if inputComponent: # Just in case a subclass like [TileBasedRandomMovementComponent] doesn't need [InputComponent]
		Tools.toggleSignal(inputComponent.didProcessInput,				self.onInputComponent_didProcessInput,					self.isEnabled)
	Tools.toggleSignal(tileBasedPositionComponent.didArriveAtNewCell,	self.onTileBasedPositionComponent_didArriveAtNewCell,	self.isEnabled and self.hasInput)
	# TRIED: Tools.toggleSignal(inputComponent.didUpdateMovementDirection,self.onInputComponent_didUpdateMovementDirection,		self.isEnabled) # Can't use because this cannot detect press/release


func onInputComponent_didProcessInput(event: InputEvent) -> void:
	# TRIED: Cannot use `inputComponent.didUpdateMovementDirection` because we need to detect press↔release transitions
	if not isEnabled: return

	# TODO: Add a little delay before processing input so the player has time to input diagonal movement instead of moving on the first orthogonal keypress.
	# TBD: PERFORMANCE: Check for presses & releases only, or accept analog input too?
	# TBD: PERFORMANCE: Use GlobalInput.hasActionTransitioned()?

	# Manually stop echoes in case `inputComponent.shouldIgnoreEchoes` is `false`
	if not shouldRepeatOnHeldInput and event and event.is_echo(): return

	# NOTE: InputComponent emits "dummy" InputEventAction.new() events after clearing state on disable/pause.
	# DESIGN: Held input is not resumed after unpause/re-enable & requires a new movement press, as that would be the more intuitive behavior, # TBD: right?
	if inputComponent.movementDirection.is_zero_approx():
		self.recentInputVector = Vector2.ZERO
		return

	# Move only on the relevant input, to avoid movement when other input like jump/fire/etc. is pressed
	# Include button/key releases too
	# Allow null events for the inital sync on _ready()
	if event == null \
	or event.is_action(GlobalInput.Actions.moveLeft)  \
	or event.is_action(GlobalInput.Actions.moveRight) \
	or event.is_action(GlobalInput.Actions.moveUp)    \
	or event.is_action(GlobalInput.Actions.moveDown): 
	
		if shouldAllowDiagonals:
			self.recentInputVector = Vector2i(int(signf(inputComponent.movementDirection.x)), int(signf(inputComponent.movementDirection.y)))
		else:
			# NOTE: If diagonals are not allowed, fractional axis values will get zeroed when converted to Vector2i integers,
			# so a normalized diagonal input from Input.get_vector() such as Up+Right = (0.707,-0.707) will become (0,0)
			# TBD: Fix <1 analog joystick input?
			self.recentInputVector = inputComponent.movementDirection # NOTE: No need to explicitly cast float Vector2 to Vector2i because we want truncation

		if hasInput and (shouldRepeatOnHeldInput or event == null or event.is_pressed()): # Non-repeated movement on input press only
			move() # checks all conditions

#endregion


#region Movement

## Tells the [TileBasedPositionComponent] to move to the [member recentInputVector] if conditions pass, such as [member hasInput] and cooldown etc.
## Uses a [Timer] to add a delay between each step.
## NOTE: Does NOT check [member isEnabled]
func move() -> void:
	if not self.hasInput \
	or not is_zero_approx(stepTimer.time_left) \
	or tileBasedPositionComponent.isMovingToNewCell \
	or not tileBasedPositionComponent.tileMap:
		return

	tileBasedPositionComponent.inputVector = self.recentInputVector
	if tileBasedPositionComponent.processInput():
		stepTimer.start() # NOTE: Start the cooldown only if the new destination is accepted, to avoid input lag after blocked moves or slow tile animations.


## [Timer] started by [method move]
func onTimeout() -> void:
	if shouldRepeatOnHeldInput: move() # checks all conditions


## Called if [member shouldRepeatOnHeldInput]
func onTileBasedPositionComponent_didArriveAtNewCell(_newDestination: Vector2i) -> void:
	if shouldRepeatOnHeldInput: move() # checks all conditions

#endregion


#region Debugging

func _process(_delta: float) -> void:
	if debugMode: showDebugInfo()


func showDebugInfo() -> void:
	# if not debugMode: return # Checked by caller
	Debug.addComponentWatchList(self, {
		recentInputVector	= recentInputVector,
		stepTimer			= stepTimer.time_left })

#endregion
