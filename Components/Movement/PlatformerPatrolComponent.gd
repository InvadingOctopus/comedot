## Makes the entity move horizontally back and forth on a "floor" platform.
## Requirements: [PlatformerControlComponent] AFTER this

class_name PlatformerPatrolComponent
extends Component

# PLAN:
# If we are not on the floor, do nothing.
#

#region Parameters
@export var isEnabled: bool = true
@export_range(0, 10, 0.1, "seconds") var turningDelay: float
@export_range(0, 10, 0.1, "pixels")  var floorDetectionGap: float = 0 ## The distance around the edges of the sprite for detecing the floor.
@export var randomizeInitialDirection: bool = false ## If `false`, move in the current direction of the sprite.
#endregion


#region State
@onready var rayCastLeft:  RayCast2D = %RayCastLeft
@onready var rayCastRight: RayCast2D = %RayCastRight

var patrolDirection: float:
	set(newValue):
		if newValue != patrolDirection: previousPatrolDirection = patrolDirection
		patrolDirection = newValue
		didTurn.emit()

var previousPatrolDirection: float

var platformerControlComponent: PlatformerControlComponent
#endregion


#region Signals
signal didTurn ## Emitted after the entity has turned around at the end of a platform.
#endregion


func _ready():
	setRayCastPositions()
	setInitialDirection()


func setRayCastPositions():
	var sprite: Sprite2D = parentEntity.findFirstChildOfType(Sprite2D)
	if not sprite: return

	var spriteRect: Rect2 = sprite.get_rect()
	rayCastLeft.position.x	= spriteRect.position.x - floorDetectionGap
	rayCastRight.position.x	= spriteRect.end.x + floorDetectionGap

	rayCastLeft.position.y	= spriteRect.end.y
	rayCastRight.position.y	= spriteRect.end.y


func setInitialDirection():
	self.patrolDirection = 1 # TODO: PLACESHOLDER


func _physics_process(delta: float):
	if not isEnabled: return

	if not self.platformerControlComponent:
		self.platformerControlComponent = findCoComponent(PlatformerControlComponent)

	updatePatrolDirection()
	platformerControlComponent.inputDirectionOverride = processPatrol(delta)

	#Debug.watchList.patrolDirection	= self.patrolDirection
	#Debug.watchList.velocity		= body.velocity


## Returns: inputDirectionOverride
func processPatrol(delta: float) -> float:
	if not isEnabled: return 0

	var inputDirectionOverride: float = 0

	# Do nothing if not on floor
	if (not isEnabled) or (not platformerControlComponent.body.is_on_floor()): return 0

	# Aoply the patrol direction
	inputDirectionOverride = patrolDirection

	return inputDirectionOverride


## Switches the patrol direction when the floor ends.
func updatePatrolDirection():

	var isFloorOnLeft  := rayCastLeft.is_colliding()
	var isFloorOnRight := rayCastRight.is_colliding()

	#Debug.watchList.isFloorOnLeft  = isFloorOnLeft
	#Debug.watchList.isFloorOnRight = isFloorOnRight

	# Is there no floor in ANY direction?

	if (not isFloorOnLeft) and (not isFloorOnRight):
		patrolDirection = 0
		return

	# Does the floor end in the direction we are currently patrolling?

	var isPatrollingLeft  := patrolDirection < 0
	var isPatrollingRight := patrolDirection > 0

	if isPatrollingLeft and (isFloorOnRight and not isFloorOnLeft):
		patrolDirection = Vector2.RIGHT.x
	elif isPatrollingRight and (isFloorOnLeft and not isFloorOnRight):
		patrolDirection = Vector2.LEFT.x

	# If we are not patrolling in any direction,

	if is_zero_approx(patrolDirection):

		if not is_zero_approx(previousPatrolDirection):
			# Use the previous patrol direction, if any
			patrolDirection = previousPatrolDirection
		else:
			# Else check the floor on the right then on the left
			if isFloorOnRight:
				patrolDirection = Vector2.RIGHT.x
			elif isFloorOnLeft:
				patrolDirection = Vector2.LEFT.x

			# TODO: Randomize
