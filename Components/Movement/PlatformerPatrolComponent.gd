## Makes the entity move horizontally back and forth on a "floor" platform.
## Requirements: [CharacterBody2D]

class_name PlatformerPatrolComponent
extends PlatformerControlComponent

# PLAN:
# If we are not on the floor, do nothing.
#

#region Parameters
@export_range(0, 10, 0.1, "seconds") var turningDelay: float
@export var randomizeInitialDirection: bool = false ## If `false`, move in the current direction of the sprite.
#endregion


#region State
#endregion


#region Signals
signal didTurn ## Emitted after the entity has turned around at the end of a platform.
#endregion


func _ready():
	super._ready()
	setInitialDirection()


func setInitialDirection():
	pass


func _physics_process(delta: float):
	inputDirectionOverride = processPatrol(delta)
	super._physics_process(delta)


## Returns: inputDirectionOverride
func processPatrol(delta: float) -> float:
	var inputDirectionOverride: float = 0

	# Do nothing if not on floor
	if (not isEnabled) or (not body.is_on_floor()): return 0

	# Get the current direction.
	var direction: Vector2 = Vector2.from_angle(parentEntity.body.rotation) # TBD: Should this be [global_rotation]?

	# Apply velocity
	inputDirectionOverride = randf_range(-1.0, 1.0)

	Debug.watchList.direction = direction
	Debug.watchList.velocity  = body.velocity

	return inputDirectionOverride
