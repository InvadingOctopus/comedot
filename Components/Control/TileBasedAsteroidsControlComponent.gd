## A subclass of [TileBasedControlComponentBase] with Asteroids-like movement for spaceships or "tank" controls etc.
## Moves and rotates an [Entity] on a [TileMapLayer] grid via the [TileBasedPositionComponent]
## [member InputComponent.turnInput] rotates the entity by 45° through each of the 8 compass directions.
## [member InputComponent.thrustInput] moves the entity forward or backward in the current direction.
## ALERT: "Turn" inputs do not include "Move Left/Right"/D-pad inputs by default, and "Thrust" inputs may be different from "Move Up/Down"/D-pad inputs.
## Requirements: [TileBasedPositionComponent], [InputComponent]
## @experimental

class_name TileBasedAsteroidsControlComponent
extends TileBasedControlComponentBase

# TBD: Add `@tool` for updating rotation in the Editor?


#region Parameters

const degreesPerDirection: int = Tools.degreesPerCompassDirection

## The number of [TileMapLayer] grid cells to move on each forward/back input.
## A negative value flips the forward/backward axis.
@export_range(-10, 10, 1, "or_greater", "or_less") var cellsPerMove: int = 1

## The [enum Tools.CompassDirection] direction the [Entity] is facing in.
## East/Right is 0° with each 45° step going clockwise through the 8 compass directions.
## [constant Tools.CompassDirection.none] defaults to the direction nearest to the entity's [member Node2D.rotation_degrees]
## effectively snapping the entity to a 45° direction.
@export var direction: Tools.CompassDirection = Tools.CompassDirection.east:
	set(newValue):
		if  newValue == Tools.CompassDirection.none and entity: # Get the current `rotation_degrees` before comparing for change
			newValue  = NodeTools.getDirectionFromRotationDegrees(entity.rotation_degrees) if entity else Tools.CompassDirection.east
			# TODO: PERFORMANCE: `entity.rotation_degrees` will be set to its current value again below :')
		if  newValue != direction:
			direction = newValue
		# DESIGN: Even if there is no change in `direction` always update the visual rotation,
		# in case it's the initial assignment, or in case the rotation was modified by something else.
		if entity: entity.rotation_degrees = float(direction) # DESIGN: Snap to a 45° direction if assigning `CompassDirection.none`

#endregion


#region State

var recentThrustDirection:	int
var previousThrustDirection:int
var previousTurnDirection:	int
var recentTurnDirection:	int

# DESIGN: "has" instead of "have" so we can write "if someComponent.hasSomething" :)

var hasThrustInput:	bool:
	get: return recentThrustDirection != 0

var hasTurnInput:	bool:
	get: return recentTurnDirection   != 0

#endregion


#region Dependencies
@onready var inputComponent: InputComponent = getCoComponent(InputComponent, true) # findSubclasses

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent, InputComponent]
#endregion


func _ready() -> void:
	super._ready()
	self.direction = self.direction # Apply setters because Godot doesn't on _ready()

	# Sync with the initial input state
	updateTurnInput()
	updateThrustInput()
	processInput()


#region Input Events

func toggleSignals() -> void:
	super.toggleSignals()
	Tools.toggleSignal(inputComponent.didUpdateTurnInput,   self.onInputComponent_didUpdateTurnInput,   self.isEnabled)
	Tools.toggleSignal(inputComponent.didUpdateThrustInput, self.onInputComponent_didUpdateThrustInput, self.isEnabled)


func resetInput() -> void:
	super.resetInput()
	recentThrustDirection	= 0
	previousThrustDirection	= 0
	previousTurnDirection	= 0
	recentTurnDirection		= 0


func onInputComponent_didUpdateTurnInput(_turnInput: float, _difference: float) -> void:
	if not isEnabled: return
	updateTurnInput()
	processInput()


func onInputComponent_didUpdateThrustInput(_thrustInput: float, _difference: float) -> void:
	if not isEnabled: return
	updateThrustInput()
	processInput()


func processInput() -> void:
	if not isEnabled: return

	var newVector: Vector2i = getThrustVector()

	if newVector == Vector2i.ZERO:
		setMovementVector(Vector2i.ZERO)
	elif shouldRepeatOnHeldInput or recentThrustDirection != previousThrustDirection:
		setMovementVector(newVector)

	previousThrustDirection = recentThrustDirection

#endregion


#region Movement & Direction

func updateTurnInput() -> void:
	self.recentTurnDirection = int(signf(inputComponent.turnInput))

	# Rotate 45° by one compass step on left/right turn input.
	if hasTurnInput and recentTurnDirection != previousTurnDirection:
		rotateDirection(recentTurnDirection)

	# Update previous turn input even if the current is 0 so that 0 -> nonzero can be compared.
	previousTurnDirection = recentTurnDirection


func updateThrustInput() -> void:
	self.recentThrustDirection = int(signf(inputComponent.thrustInput))


func getThrustVector(thrustDirection: int = self.recentThrustDirection) -> Vector2i:
	if thrustDirection == 0 or cellsPerMove == 0:
		return Vector2i.ZERO
	else:
		return Tools.compassDirectionVectors[direction] * cellsPerMove * thrustDirection


func rotateDirection(turnDirectionOverride: int = self.recentTurnDirection) -> void:
	if turnDirectionOverride == 0: return
	self.direction = wrapi(
		int(direction) + (turnDirectionOverride * degreesPerDirection),
		0, 360) as Tools.CompassDirection


func getRepeatedMovementVector() -> Vector2i:
	updateThrustInput()
	return getThrustVector()

#endregion


func showDebugInfo() -> void:
	# if not debugMode: return # Checked by caller
	Debug.addComponentWatchList(self, {
		direction		= direction,
		directionVector	= Tools.compassDirectionVectors[direction],
		movementVector	= gridMovementVector,
		queuedVector	= queuedMovementVector,
		turnDirection	= recentTurnDirection,
		thrustDirection	= recentThrustDirection,
		stepTimer		= stepTimer.time_left,
		})
