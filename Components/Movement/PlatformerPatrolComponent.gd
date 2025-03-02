## Makes the entity move horizontally back and forth on a "floor" platform.
## Requirements: BEFORE [PlatformerPhysicsComponent], After [CornerCollisionComponent]

class_name PlatformerPatrolComponent
extends CharacterBodyDependentComponentBase

# PLAN:
# * If we are not on the floor, do nothing.
# * Check for floor and walls at the left and right corners and edges.
# * Reverse patrol direction when there is no more room to move in the current direction.


#region Parameters

## Not implemented yet
@export_range(0, 10, 0.1, "seconds") var turningDelay: float # TODO: Implement

@export_range(0, 16, 1, "pixels") var detectionGap: float = 0 ## The distance around the edges of the sprite for detecing the floor and walls.

## The initial movement on the X axis: -1 = left, +1 = right
## If invalid, then [member PlatformerControlComponent.lastInputDirection] will be used.
## NOTE: Overridden by [member randomizeInitialDirection].
@export_enum("Left:-1", "Right:1") var initialDirection: int = +1

## If `false`, move in the current direction of the sprite.
## NOTE: Overrides [member initialDirection].
@export var randomizeInitialDirection: bool = false

@export var isEnabled: bool = true

#endregion


#region State

var isFloorOnLeft:	bool
var isFloorOnRight:	bool
var isWallOnLeft:	bool
var isWallOnRight:	bool

var patrolDirection: float:
	set(newValue):
		# Update and emit signal only if we have a new direction
		if not is_equal_approx(newValue, patrolDirection):
			previousPatrolDirection = patrolDirection
			patrolDirection = newValue
			didTurn.emit()

var previousPatrolDirection: float

var sprite: Sprite2D:
	get:
		if not sprite: sprite = parentEntity.findFirstChildOfType(Sprite2D) # TODO: Check that this also picks up [AnimatedSprite2D]
		return sprite

@onready var cornerCollisionComponent:   CornerCollisionComponent   = coComponents.CornerCollisionComponent   # TBD: Static or dynamic?
@onready var platformerPhysicsComponent: PlatformerPhysicsComponent = coComponents.PlatformerPhysicsComponent # TBD: Static or dynamic?

#endregion


#region Signals
signal didTurn ## Emitted after the entity has turned around at the end of a platform.
#endregion


func getRequiredComponents() -> Array[Script]:
	return [CornerCollisionComponent, PlatformerPhysicsComponent]


func _ready() -> void:
	setInitialDirection()


func setInitialDirection() -> void:
	if randomizeInitialDirection:
		self.patrolDirection = [-1.0, 1.0].pick_random()
	elif self.initialDirection == -1 or self.initialDirection == +1:
		self.patrolDirection = self.initialDirection
	# If initialDirection is invalid, use the PlatformerControlComponent's previous direction, otherwise right.
	elif not is_zero_approx(platformerPhysicsComponent.lastInputDirection):
		self.patrolDirection = platformerPhysicsComponent.lastInputDirection
	else:
		self.patrolDirection = Vector2.RIGHT.x


func _physics_process(delta: float) -> void:
	if (not isEnabled) or (not self.platformerPhysicsComponent): return

	updateCollisionFlags() # TBD: Should the raycasts be updated before or after movement?
	updatePatrolDirection()
	platformerPhysicsComponent.inputDirection = processPatrol(delta)

	#Debug.watchList.patrolDirection = self.patrolDirection
	#Debug.watchList.velocity = body.velocity


func resetCollisionFlags() -> void:
	isFloorOnLeft	= false
	isFloorOnRight	= false
	isWallOnLeft	= false
	isWallOnRight	= false


func updateCollisionFlags() -> void:
	if not cornerCollisionComponent: return
	isFloorOnLeft	= cornerCollisionComponent.areaSWCollisionCount >= 1
	isFloorOnRight	= cornerCollisionComponent.areaSECollisionCount >= 1
	isWallOnLeft	= cornerCollisionComponent.areaNWCollisionCount >= 1 # TODO: Verify
	isWallOnRight	= cornerCollisionComponent.areaNECollisionCount >= 1 # TODO: Verify
	#showDebugInfo()


## Returns: inputDirectionOverride
func processPatrol(_delta: float) -> float:
	if not isEnabled: return 0

	var inputDirectionOverride: float = 0

	# Do nothing if not on floor
	if (not isEnabled) or (not platformerPhysicsComponent.body.is_on_floor()): return 0

	# Aoply the patrol direction
	inputDirectionOverride = patrolDirection

	return inputDirectionOverride


## Switches the patrol direction when the floor ends.
func updatePatrolDirection() -> void:

	var newPatrolDirection: float = patrolDirection # Start as equal for comparison later.

	var isLeftBlocked:  bool = (not isFloorOnLeft)  or isWallOnLeft
	var isRightBlocked: bool = (not isFloorOnRight) or isWallOnRight

	# Scenario 1.0: If there is no floor in ANY direction, or if there are walls on both sides,
	# then stay put.

	if isLeftBlocked and isRightBlocked:
		newPatrolDirection = 0

	elif is_zero_approx(patrolDirection):

		# Scenario 2.0: If we are not patrolling in any direction,
		# Use the previous patrol direction, if any

		if not is_zero_approx(previousPatrolDirection):
			newPatrolDirection = previousPatrolDirection
		else:
			# 2.1: Else check if right is open then check the left.
			if not isRightBlocked:  newPatrolDirection = Vector2.RIGHT.x
			elif not isLeftBlocked: newPatrolDirection = Vector2.LEFT.x

			# TODO: Randomize?

	elif not is_zero_approx(patrolDirection):
		# Scenario 3.0: Does the floor end, or did we hit a wall, in the direction we are currently patrolling?

		var isPatrollingLeft:  bool = patrolDirection < 0
		var isPatrollingRight: bool = patrolDirection > 0

		if isPatrollingLeft and isLeftBlocked:
			newPatrolDirection = Vector2.RIGHT.x
		elif isPatrollingRight and isRightBlocked:
			newPatrolDirection = Vector2.LEFT.x

	# If there is a turning delay, then stop movement,
	# and change the direction after the delay.

	if (not is_zero_approx(turningDelay)) and (not is_equal_approx(newPatrolDirection, patrolDirection)):
		patrolDirection = 0
		# TODO: Implement
		return

	patrolDirection = newPatrolDirection

	# Signal will be emitted by property setter


func showDebugInfo() -> void:
	Debug.watchList.isFloorOnLeft	= isFloorOnLeft
	Debug.watchList.isFloorOnRight	= isFloorOnRight
	Debug.watchList.isWallOnLeft	= isWallOnLeft
	Debug.watchList.isWallOnRight	= isWallOnRight
