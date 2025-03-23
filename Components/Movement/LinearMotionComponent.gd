## Moves the entity in a straight line in the direction of the entity's [member Node2D.rotation]
## NOTE: Sets the parent entity's position DIRECTLY; does NOT use "physics" such as [member CharacterBody2D.velocity].
## Ideal for bullets and similar projectiles to improve performance.

class_name LinearMotionComponent
extends Component


#region Parameters

@export_range(-2000, 2000, 5) var initialSpeed:	float = 150  ## The initial value for [member speed]
@export_range(-2000, 2000, 5) var maximumSpeed:	float = 800  ## The maximum limit if [member shouldApplyModifier] is positive (i.e. acceleration)
@export_range(-2000, 2000, 5) var minimumSpeed:	float = 10   ## The minimum limit if [member shouldApplyModifier] is negative (i.e. friction)

@export var shouldApplyModifier:				 bool = true ## If `true` then the acceleration/friction [member modifier] is applied to [member speed] every frame.
@export_range(-2000, 2000, 5) var modifier:		float = 800  ## The acceleration (if positive) or friction (if negative) added to [member speed] every frame if [member shouldApplyModifier]

@export var shouldStopAtMaximumDistance:		 bool = false
@export var shouldDeleteParentAtMaximumDistance: bool = false
@export_range(50, 2000, 5) var maximumDistance: float = 200

@export var isEnabled:							 bool = true

#endregion


#region State
@export_storage var speed: float = initialSpeed ## Set to [member initialSpeed] on [method _ready]
@export_storage var distanceTraveled: float = 0
var isMoving: bool = true ## Set to `false` after reaching the [member maximumDistance] if [member shouldStopAtMaximumDistance].
#endregion


#region signals
signal didReachMaximumDistance
#endregion


func _ready() -> void:
	self.speed = self.initialSpeed # Can't make @onready because of @export_storage
	
	if shouldStopAtMaximumDistance \
	and distanceTraveled > maximumDistance or is_equal_approx(distanceTraveled, maximumDistance):
		self.isMoving = false


func _physics_process(delta: float) -> void:
	if not isEnabled or not isMoving: return

	# Check the maximum distance limit before moving any further.

	if shouldStopAtMaximumDistance or shouldDeleteParentAtMaximumDistance: # So that the distance comparisson doesn't happen every frame.
		if distanceTraveled > maximumDistance or is_equal_approx(distanceTraveled, maximumDistance):
			# DEBUG: printDebug("distanceTraveled: " + str(distanceTraveled) + " >= maximumDistance: " + str(maximumDistance))
			if shouldStopAtMaximumDistance: self.isMoving = false
			didReachMaximumDistance.emit() # Emit the signal after updating the flag and before we delete the entity!
			if shouldDeleteParentAtMaximumDistance: parentEntity.queue_free()
			return

	# Get the current direction
	var direction: Vector2 = Vector2.RIGHT.rotated(parentEntity.rotation)

	# Acceleration or Friction
	if shouldApplyModifier:
		speed += modifier * delta
		speed = clampf(speed, minimumSpeed, maximumSpeed)

	# Get the upcoming movement
	var offset: Vector2 = direction * (speed * delta)

	# Should we stop at a maximum distance?

	if shouldStopAtMaximumDistance:

		# Check if the upcoming movement will put us past the maximum distance
		var projectedDistance: float = distanceTraveled + offset.length()

		if projectedDistance > maximumDistance or is_equal_approx(projectedDistance, maximumDistance):
			# Then just cross the remaining gap, no more.
			var remainingDistance: float = maximumDistance - distanceTraveled
			# DEBUG: printDebug("projectedDistance: " + str(projectedDistance) + " > maximumDistance: " + str(maximumDistance))
			# DEBUG: printChange("offset", offset, str(direction * remainingDistance))
			offset = direction * remainingDistance

	# Move
	parentEntity.position += offset # TBD: PERFORMANCE: Use translate(offset)?
	parentEntity.reset_physics_interpolation() # CHECK: Is this necessary? Avoid physics "teleportation" glitches
	self.distanceTraveled += offset.length()

	if debugMode: printDebug(str("offset: ", offset, ", direction: ", direction, ", distanceTraveled: ", distanceTraveled, " of ", maximumDistance))

