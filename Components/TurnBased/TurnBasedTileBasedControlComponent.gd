## Uses a [TileBasedPositionComponent] to move a turn-based entity when it's ready to take a turn.
## TIP: For random monster/NPC movement use [RandomInputComponent]
## Requirements: [TurnBasedEntity], [TileBasedPositionComponent]. BEFORE [InputComponent]

class_name TurnBasedTileBasedControlComponent
extends TurnBasedComponent

# TODO: Allow diagonal movement
# TODO: Check for collisions?
# TODO: Better name :')


#region Parameters

## If `true` (default) then this component starts [method TurnBasedCoordinator.startTurn] when a valid [InputComponent] move is received or held.
## TIP: Useful in "Roguelikes" where the world "ticks" and NPCs/monsters move only when the player moves.
@export var shouldStartTurnOnMove:	bool = true

## If `true` (default) then the entity keeps moving as long as the input direction is pressed. If `false` then the input must be released before moving again.
## TIP: Useful in "Roguelikes"
@export var shouldRepeatOnHeldInput:bool = true

#endregion


#region State

func setIsEnabled(newValue: bool) -> void:
	if newValue != isEnabled:
		super.setIsEnabled(newValue)
		if self.is_node_ready():
			Tools.toggleSignal(inputComponent.didUpdateMovementDirection, self.onInputComponent_didUpdateMovementDirection, self.isEnabled)
			if not isEnabled: # These signals should not be reconnected when the component is re-enabled, only after a move if `shouldRepeatOnHeldInput`
				Tools.disconnectSignal(TurnBasedCoordinator.isReadyToStartTurn,		self.onTurnBasedCoordinator_isReadyToStartTurn)
				Tools.disconnectSignal(tileBasedPositionComponent.didArriveAtNewCell,	self.onTileBasedPositionComponent_didArriveAtNewCell)

## The input vector that will be applied to [member tileBasedPositionComponent.inputVector] in [method processTurnExecute]
var queuedMovementDirection: Vector2i:
	set(newValue):
		printChange(entity.logName + " queuedMovementDirection", queuedMovementDirection, newValue)
		queuedMovementDirection = newValue
		if debugMode: showDebugInfo()

var canAcceptMove:	bool:
	get: return self.isEnabled \
		and TurnBasedCoordinator.canStartTurn \
		and not tileBasedPositionComponent.isMovingToNewCell

var canStartTurn:	bool: 
	get: return self.isEnabled \
		and TurnBasedCoordinator.canStartTurn \
		and not tileBasedPositionComponent.isMovingToNewCell

#endregion


#region Dependencies
@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent # TBD: Static or dynamic?
@onready var inputComponent: InputComponent = getCoComponent(InputComponent, true) # findSubclasses

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent, InputComponent]
#endregion


func _ready() -> void:
	Tools.toggleSignal(inputComponent.didUpdateMovementDirection, self.onInputComponent_didUpdateMovementDirection, self.isEnabled)
	# NOTE: Connect `TurnBasedCoordinator.isReadyToStartTurn` & `tileBasedPositionComponent.didArriveAtNewCell` AFTER movement, i.e. in processTurnExecute()
	if debugMode: showDebugInfo()


#region Input

func onInputComponent_didUpdateMovementDirection(movementDirection: Vector2, _difference: Vector2) -> void:
	if not isEnabled or not canAcceptMove: return
	if validateMove(movementDirection):
		self.queuedMovementDirection = movementDirection # CHECK: No need to explicitly cast float Vector2 to Vector2i, right?

		# Start the turn automatically? i.e. as in Roguelikes
		if shouldStartTurnOnMove and canStartTurn: startTurn()


## Returns `true` if the destination cell (in [member queuedMovementDirection] by default) is valid & vacant according to [method TileBasedPositionComponent.validateCoordinates]
## NOTE: Call [method startTurn] to actually reposition the entity after checking [method validateMove]
## TIP: Subclasses may override this method to add custom validation, such as checking for "action points" etc. before moving.
## IMPORTANT: If overridden, the subclass's method MUST call `super.validateMove()` to include necessary checks.
func validateMove(requestedDirection: Vector2i = self.queuedMovementDirection) -> bool:
	# PERFORMANCE: length_squared() is faster than length() CHECK: Does this cause any false positives?
	return  requestedDirection.length_squared() != 0	\
		and tileBasedPositionComponent.validateCoordinates(tileBasedPositionComponent.currentCoordinates + requestedDirection)

#endregion


#region Turn Cycle

## Calls [method TurnBasedCoordinator.startTurn] and returns the TileMap coordinates that the entity will ATTEMPT to move into.
## IMPORTANT: Caller must call [method validateMove] BEFORE calling this method.
## NOTE: May not succeed if [method TurnBasedCoordinator.startTurn] refuses.
## TIP: Subclasses may override this method to add custom movement, such as deducting "action points" etc. after moving.
func startTurn() -> Vector2i:
	TurnBasedCoordinator.startTurn() # TBD: `awaitForTurnEnd`?
	return tileBasedPositionComponent.currentCoordinates + self.queuedMovementDirection


func processTurnBegin() -> void:
	pass # if debugMode: showDebugInfo()


func processTurnExecute() -> void:
	# if not isEnabled: return # Checked by TurnBasedComponent
	tileBasedPositionComponent.inputVector = Vector2i(self.queuedMovementDirection)
	
	if tileBasedPositionComponent.processInput() and tileBasedPositionComponent.isMovingToNewCell:
		# IMPORTANT: Wait for the move to complete so that the TurnBasedCoordinator doesn't transition to the next turn state!
		# In case the `TileBasedPositionComponent.speed` is slow etc.
		await tileBasedPositionComponent.didArriveAtNewCell

	queuedMovementDirection = Vector2.ZERO # Always clear and let repeatMovement() repoll input if `shouldRepeatOnHeldInput`
	# if debugMode: showDebugInfo()

	# Move again when the current move/turn completes?
	Tools.toggleSignal(TurnBasedCoordinator.isReadyToStartTurn,		self.onTurnBasedCoordinator_isReadyToStartTurn,		self.shouldRepeatOnHeldInput)
	Tools.toggleSignal(tileBasedPositionComponent.didArriveAtNewCell,	self.onTileBasedPositionComponent_didArriveAtNewCell,	self.shouldRepeatOnHeldInput)

#endregion


#region Repeated Movement
# If the input is held, move again & start a new turn immediately after the current move completes. i.e. similar to Roguelikes

func onTurnBasedCoordinator_isReadyToStartTurn() -> void:
	if debugMode: printDebug(str("onTurnBasedCoordinator_isReadyToStartTurn() shouldRepeatOnHeldInput: ", shouldRepeatOnHeldInput))
	if not canAcceptMove: return
	if self.shouldRepeatOnHeldInput: repeatMovement()


func onTileBasedPositionComponent_didArriveAtNewCell(_newDestination: Vector2i) -> void:
	Tools.disconnectSignal(tileBasedPositionComponent.didArriveAtNewCell, self.onTileBasedPositionComponent_didArriveAtNewCell)
	if not canAcceptMove: return
	if self.shouldRepeatOnHeldInput: repeatMovement()


## Reapplies [member inputComponent.movementDirection] to [member queuedMovementDirection] if [member shouldRepeatOnHeldInput],
## and starts a new turn if [member shouldStartTurnOnMove] and [member canStartTurn]
## TIP: May be used to implement "Roguelike" control.
func repeatMovement() -> void:
	if shouldRepeatOnHeldInput and validateMove(inputComponent.movementDirection):
		queuedMovementDirection = inputComponent.movementDirection
		if shouldStartTurnOnMove and canStartTurn: startTurn()

#endregion


func showDebugInfo() -> void:
	# if not debugMode: return # Checked by caller
	Debug.addComponentWatchList(self, {
		vector = queuedMovementDirection,
		})
