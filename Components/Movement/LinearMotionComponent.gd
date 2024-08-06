## Moves the entity in a straight line in the direction of the entity's rotation.

class_name LinearMotionComponent
extends Component


#region Parameters

 ## NOTE: This is not called `inPaused` because that might imply it's not being processed every frame.
@export var isMoving:							bool = true

@export_range(-1000, 1000, 5) var initialSpeed:	float = 150
@export_range(-1000, 1000, 5) var maximumSpeed:	float = 800

@export var applyAcceleration := true
@export_range(-1000, 1000, 5) var acceleration:	float = 800

@export var shouldStopAtMaximumDistance:		 bool = false
@export var shouldDeleteParentAtMaximumDistance: bool = false
@export_range(50, 1000, 5) var maximumDistance: float = 200

#endregion


#region State
var speed:            float = initialSpeed
var distanceTraveled: float = 0
#endregion


#region signals
signal didReachMaximumDistance
#endregion


func _physics_process(delta: float) -> void:
	if not isMoving: return

	# Check the maximum distance limit before moving any further.

	if shouldStopAtMaximumDistance or shouldDeleteParentAtMaximumDistance: # So that the distance comparisson doesn't happen every frame.
		if distanceTraveled > maximumDistance or is_equal_approx(distanceTraveled, maximumDistance):
			# DEBUG: printDebug("distanceTraveled: " + str(distanceTraveled) + " >= maximumDistance: " + str(maximumDistance))
			if shouldStopAtMaximumDistance: self.isMoving = false
			if shouldDeleteParentAtMaximumDistance: parentEntity.queue_free()
			didReachMaximumDistance.emit()
			return

	# Get the current direction
	var direction: Vector2 = Vector2.RIGHT.rotated(parentEntity.rotation)

	# Accelerate

	if applyAcceleration:
		speed += acceleration * delta
		if speed > maximumSpeed: speed = maximumSpeed

	var offset: Vector2 = direction * speed * delta

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

	parentEntity.translate(offset) # parentEntity.position += offset
	self.distanceTraveled += offset.length()

	# DEBUG: printDebug("distanceTraveled: " + str(distanceTraveled) + ", maximumDistance: " + str(maximumDistance))
