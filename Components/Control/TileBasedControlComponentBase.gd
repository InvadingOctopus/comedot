## An abstract base class for components that takes player/AI/script input and modifies the [Entity]'s position on a [TileMapLayer] via a [TileBasedPositionComponent]
## DESIGN: In tile-based gameplay, every move may have different rules & conditions in different games, such as a Roguelike vs. Chess,
## and tile-based movement cannot rely on Godot's builtin physics for checking the "vacancy" of tiles/cells etc.
## This component contains some of the shared logic that all tile-based movement needs, such as a delay between steps and waiting for the previous move's animation to finish etc.
## TIP: The component's node should be a [Timer] to handle cooldowns.
## Requirements: [TileBasedPositionComponent]

@abstract class_name TileBasedControlComponentBase
extends Component

# TODO: Allow movement on input `is_just_released`

# PLAN:
	# 1. Player or AI generates input event.
	# 2. Is the component able to accept input? (or is the game paused, or is the component disabled, or is the character incapacitated etc)
	# 3. Are we ready to move? (or is there an ongoing animation? or is it not the character's turn yet?)
	# 4. If not, queue the input to execute for the next time we're ready.
	# 5. Validate: Is the requested move valid? (or is the tile/cell blocked in the requested direction?)
	# 6. Start the cooldown timer.
	# 7. After we arrive at the destination, should we move again? i.e. reapply the current input state without waiting for an input event.


#region Parameters

## If `true` (default) then if this component can accept input but the [Entity] is not ready to move,
## e.g. if [TileBasedPositionComponent] has not completed a previous move's animation yet or if a character is incapacitated,
## the input will be queued and re-attempted when the components are ready to move e.g. on [signal TileBasedPositionComponent.didArriveAtNewCell]
@export var shouldQueueIfNotReady:	bool = true

## If `true` then the entity keeps moving as long as the input direction is pressed.
## If `false` then the input must be released before moving again.
## NOTE: Changing direction diagonally e.g. from Up into Up+Right counts as new input.
@export var shouldRepeatOnHeldInput:bool = true

@export var isEnabled: bool = true:
	set = setIsEnabled # Use a separate function for the property setter so that subclasses may override it.

func setIsEnabled(newValue: bool) -> void:
	if newValue != isEnabled:
		isEnabled = newValue
		if self.is_node_ready(): toggleSignals()
		if not isEnabled: resetInput()

#endregion


#region State

## The vector to set [member TileBasedPositionComponent.inputVector] to when we are ready to move.
## This translates any game-specific movement to the actual displacement on the TileMap cell grid,
## i.e. a Chess Knight might have a vector of (1,-2)
## NOTE: Clears [member queuedMovementVector]
## IMPORTANT: Subclasses and other scripts should NOT modify this property directly: Call [method setMovementVector] instead.
var gridMovementVector: Vector2i:
	set(newValue):
		queuedMovementVector = Vector2i.ZERO # NOTE: Always clear queued movement even if `gridMovementVector` doesn't change, i.e. on repeated moves or resets.
		if newValue != gridMovementVector:
			if debugMode: Debug.printChange("gridMovementVector", gridMovementVector, newValue, self.debugModeTrace) # logAsTrace
			gridMovementVector = newValue

var queuedMovementVector: Vector2i

@onready var stepTimer: Timer = self.get_node(^".") as Timer

#endregion


#region Dependencies
# DESIGN: [InputComponent] may be optionally required by subclasses.

@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent]
#endregion


func _ready() -> void:
	# Apply setters because Godot doesn't on _ready()
	toggleSignals()
	self.set_process(self.debugMode)


#region Validation

func canAcceptInput() -> bool:
	return self.isEnabled \
	and (self.shouldQueueIfNotReady or is_zero_approx(stepTimer.time_left))


## May be extended by subclasses.
func hasInput(vector: Vector2i = self.gridMovementVector) -> bool:
	return vector != Vector2i.ZERO # TBD: Check length_squared()? faster than length()
	# TBD: tileBasedPositionComponent.validateCoordinates(tileBasedPositionComponent.currentCoordinates + vector) # TBD: PERFORMANCE: Is this necessary?


func isReadyToMove() -> bool:
	# INTENTIONAL: Not validating TileBasedPositionComponent.tileMap because a missing TileMap should be a crash
	return not tileBasedPositionComponent.isMovingToNewCell \
	and is_zero_approx(stepTimer.time_left)

#endregion


#region Movement

func resetInput() -> void:
	gridMovementVector   = Vector2i.ZERO
	queuedMovementVector = Vector2i.ZERO


## Updates [member gridMovementVector] then calls [method move] if both [method canAcceptInput] and [method isReadyToMove] return `true`,
## otherwise [member queuedMovementVector] is set if [member shouldQueueIfNotReady]
## IMPORTANT: Subclasses should call this method whenever they receive & process input events, instead of modifying [member gridMovementVector] directyly.
func setMovementVector(newVector: Vector2i) -> bool:
	# NOTE: Requests to CLEAR `gridMovementVector` should be carried out regardless of canAcceptInput()

	if newVector == Vector2i.ZERO:
		self.gridMovementVector		= Vector2i.ZERO # Also clears queuedMovementVector
		return false # TBD: Return `true` for clearing input too, or only on successful movement?

	# If it's a non-zero vector, are we able to accept any input?
	if not self.canAcceptInput(): return false

	# Can we move now?
	if isReadyToMove():
		self.gridMovementVector		= newVector
		return move()
	# Should we queue for later?
	elif shouldQueueIfNotReady:
		self.queuedMovementVector	= newVector

	return false


## Sets [member TileBasedPositionComponent.inputVector] to this component's [member gridMovementVector] and calls [method tileBasedPositionComponent.processInput]
## Also starts the [member stepTimer] cooldown to add a delay between each step.
## NOTE: Does NOT check [member isEnabled] or [method isReadyToMove]: The caller must check those flags.
func move() -> bool:
	tileBasedPositionComponent.inputVector = self.gridMovementVector

	# NOTE: Start the cooldown BEFORE moving, to prevent onTileBasedPositionComponent_didArriveAtNewCell() from repeating immediately,
	# because TileBasedPositionComponent.processInput() can return instantly if `TileBasedPositionComponent.shouldMoveInstantly` which can emit `didArriveAtNewCell` synchronously.
	stepTimer.start()

	if  tileBasedPositionComponent.processInput(): # Also performs input validation
		return true
	else:
		stepTimer.stop() # NOTE: Timer.stop() does not emit Timer.timeout
		return false


func applyQueuedOrRepeatedMove() -> bool:
	if queuedMovementVector != Vector2i.ZERO: return setMovementVector(queuedMovementVector)
	elif shouldRepeatOnHeldInput: return setMovementVector(getRepeatedMovementVector()) # Delegate to subclass
	else: return false


## May be overridden by subclasses.
func getRepeatedMovementVector() -> Vector2i:
	return Vector2i.ZERO

#endregion


#region Events

## May be extended by subclasses.
## IMPORTANT: Remember to chain up to `super.toggleSignals()` to connect to [signal TileBasedPositionComponent.didArriveAtNewCell] unless it's not needed by a subclass.
func toggleSignals() -> void:
	# TBD: PERFORMANCE: Disconnect signals if no `queuedMovementVector` and not `shouldRepeatOnHeldInput`?
	Tools.toggleSignal(tileBasedPositionComponent.didArriveAtNewCell, self.onTileBasedPositionComponent_didArriveAtNewCell,	self.isEnabled)


## Called at the end of [Timer] started by [method move]
func onTimeout() -> void:
	if not tileBasedPositionComponent.isMovingToNewCell: applyQueuedOrRepeatedMove()


func onTileBasedPositionComponent_didArriveAtNewCell(_newDestination: Vector2i) -> void:
	if is_zero_approx(stepTimer.time_left): applyQueuedOrRepeatedMove()

#endregion


#region Debugging

func _process(_delta: float) -> void:
	if debugMode: showDebugInfo()


func showDebugInfo() -> void:
	# if not debugMode: return # Checked by caller
	Debug.addComponentWatchList(self, {
		movementVector	= gridMovementVector,
		queuedVector	= queuedMovementVector,
		stepTimer		= stepTimer.time_left })

#endregion
