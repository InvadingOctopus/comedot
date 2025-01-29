## Moves the entity in a straight line in the direction of the entity's [member Node2D.rotation].
## NOTE: Sets the parent entity's position DIRECTLY; does NOT use "physics" such as [member CharacterBody2D.velocity].

class_name LinearMotionComponent
extends Component


#region Parameters

@export_range(-2000, 2000, 5) var initialSpeed:	float = 150
@export_range(-2000, 2000, 5) var maximumSpeed:	float = 800 ## The limit if [member shouldApplyAcceleration].

@export var shouldApplyAcceleration:			 bool = true
@export_range(-2000, 2000, 5) var acceleration:	float = 800

@export var shouldStopAtMaximumDistance:		 bool = false
@export var shouldDeleteParentAtMaximumDistance: bool = false
@export_range(50, 2000, 5) var maximumDistance: float = 200

@export var isEnabled:							 bool = true

#endregion


#region State
@onready var speed:   float = initialSpeed # NOTE: Must be @onready to actually get the value after the @export!

var distanceTraveled: float = 0
var isMoving:		  bool  = true ## `false` after reaching the [member maximumDistance] if [member shouldStopAtMaximumDistance].
#endregion


#region signals
signal didReachMaximumDistance
#endregion


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

	# Accelerate
	if shouldApplyAcceleration:
		speed += acceleration * delta
		if abs(speed) > abs(maximumSpeed): speed = maximumSpeed

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
	parentEntity.translate(offset) # parentEntity.position += offset
	self.distanceTraveled += offset.length()

	if shouldShowDebugInfo: printDebug(str("offset: ", offset, ", direction: ", direction, ", distanceTraveled: ", distanceTraveled, " of ", maximumDistance))

