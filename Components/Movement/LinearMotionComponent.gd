## Moves the entity in the direction of the entity's [member Node2D.rotation] or a specified [member directionOverride]
## NOTE: Sets the parent entity's position DIRECTLY; does NOT modify physics velocity via [member CharacterBody2D.velocity]
## TIP: PERFORMANCE: May be ideal for bullets and other projectiles and similar basic movement, even for scrolling backgrounds etc.

class_name LinearMotionComponent
extends Component


#region Parameters

@export var isEnabled:							 bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_physics_process(isEnabled and isMoving)

@export_group("Speed")
@export_range(-2400, 2400) var initialSpeed:	float = 160		## The initial value for [member speed]
@export_range(-2400, 2400) var maxSpeed:		float = 800		## The maximum limit for [member speed]
@export_range(-2400, 2400) var minSpeed:		float = 8		## The minimum limit to maintain [member speed] at.

@export var shouldApplyModifier:				 bool = false	## If `true` then the acceleration/friction [member modifier] is applied to [member speed] every frame.
@export_range(-4800, 4800) var modifier:		float = 800		## The acceleration (if positive) or friction (if negative) applied to [member speed] (scaled by the delta) every frame if [member shouldApplyModifier] # ALERT: Reversed if [member speed] is negative!


@export_group("Direction")
@export var shouldOverrideDirection:			 bool = false	## If `false` (default) then the [Entity]'s [member Node2D.rotation] is used. If `true` then the rotation is ignored and [member directionOverride] is used.
@export var directionOverride:				  Vector2			## The direction to move in if [member shouldOverrideDirection]. NOTE: Normalized when applied.


@export_group("Maximum Distance")
@export var shouldStopAtMaxDistance:			 bool = false
@export var shouldDeleteParentAtMaxDistance:	 bool = false
@export_range(16, 4000) var maxDistance:		float = 200		## The maximum allowed cumulative movement added by this component. NOTE: NOT the flat distance from the entity's "starting" position!

#endregion


#region State

@export_storage var speed:						float = NAN ## The current speed. If `NAN` then it's set to [member initialSpeed] on [method _ready]
@export_storage var distanceTraveled:			float = 0

var parent: Node2D ## A generic [Node2D] reference to allow non-[Entity] parents.

var isMoving: bool = true: ## Set to `false` after reaching the [member maxDistance] if [member shouldStopAtMaxDistance] or [member shouldDeleteParentAtMaxDistance]
	set(newValue):
		isMoving = newValue
		self.set_physics_process(isEnabled and isMoving)

#endregion


#region Signals
# TRIED: A `willReachMaxDistance` signal makes it hard to account for handlers that mutate state.

## Emitted AFTER the entity has reached OR exceeded the `maxDistance`
## NOTE: Emitted only if [member shouldStopAtMaxDistance] or [member shouldDeleteParentAtMaxDistance] is `true`
signal didCrossMaxDistance
#endregion


func onParented() -> void:
	super.onParented()
	self.parent = self.get_parent() # Save the parent to allow non-Entity parents.


func onUnparented() -> void:
	super.onUnparented()
	self.parent = null


func _ready() -> void:
	# Avoid clobbering an existing `speed` loaded from a saved `@export_storage`
	# Use `NAN` as an "initialize me" flag
	if is_nan(speed): speed = initialSpeed # Can't make `@onready` because of `@export_storage`

	# NOTE: Check the maximum distance on ready, in case a bullet etc. was loaded from a save file
	if distanceTraveled > maxDistance or is_equal_approx(distanceTraveled, maxDistance):
		# NOTE: Do not emit signals here, because the `maxDistance` may have been passed a long time ago e.g. when restoring from a saved state.
		# No need to log if restored past `maxDistance`
		if shouldStopAtMaxDistance:
			isMoving = false # Calls set_physics_process()
		if shouldDeleteParentAtMaxDistance:
			isMoving = false # Stop overshooting before the queued free() is executed
			parent.queue_free()
			return
	else:
		self.set_physics_process(isEnabled and isMoving) # PERFORMANCE: Process per-frame only when needed


func _physics_process(delta: float) -> void: # TBD: _physics_process() instead of _process() because movement may interact with physics, right?
	# Check the maximum distance limit before moving any further
	if shouldStopAtMaxDistance or shouldDeleteParentAtMaxDistance: # PERFORMANCE: Use separate `if`s so that the distance comparison doesn't happen every frame.
		if distanceTraveled > maxDistance or is_equal_approx(distanceTraveled, maxDistance):
			if debugMode: printDebug(str("distanceTraveled before movement: ", distanceTraveled, " >= maxDistance: ", maxDistance, ", shouldStopAtMaxDistance: ", shouldStopAtMaxDistance, ", shouldDeleteParentAtMaxDistance: ", shouldDeleteParentAtMaxDistance))
			self.isMoving = false
			self.didCrossMaxDistance.emit() # Emit the signal after updating the flag and before we delete the entity!
			if shouldDeleteParentAtMaxDistance: parent.queue_free()
			return

	# Get the current direction
	var direction: Vector2
	if  shouldOverrideDirection:
		direction = self.directionOverride.normalized()
	else:
		direction = Vector2.from_angle(parent.rotation) # Equivalent to `Vector2.RIGHT.rotated()` # NOTE: Not guaranteed to always be a 1.0 unit vector

	# Acceleration or Friction
	if  shouldApplyModifier:
		speed += modifier * delta
		speed  = clampf(speed, minSpeed, maxSpeed)

	# Store the movement before applying it to the actual position, in order to limit it to the `maxDistance`
	var offset: Vector2 = direction * (speed * delta)

	# Should we stop at a maximum distance?
	var willReachMaxDistanceThisFrame: bool
	if  shouldStopAtMaxDistance or shouldDeleteParentAtMaxDistance:

		# Check if the upcoming movement will put us at or past the maximum distance
		var projectedDistance: float = distanceTraveled + offset.length()

		if  projectedDistance > maxDistance or is_equal_approx(projectedDistance, maxDistance):
			# Then just cross the remaining gap, no more.
			var remainingDistance: float = maxDistance - distanceTraveled # maxf() to prevent against negative distances is not needed, because we already checked the distance at the start of this method

			if debugMode:
				printDebug(str("projectedDistance: ", projectedDistance, " >= maxDistance: ", maxDistance))
				printChange("offset", offset, offset.normalized() * remainingDistance)

			# NOTE: Account for negative `speed`:
			# `offset` already contains the "sign" of `speed`, so (-3, 4) → (-0.6, 0.8)
			offset = offset.normalized() * remainingDistance
			willReachMaxDistanceThisFrame = true

	# Move
	parent.translate(offset) # PERFORMANCE: .translate() may be marginally faster than `+=`
	distanceTraveled += offset.length()

	# DEBUG: if debugMode: printDebug(str("offset: ", offset, ", direction: ", direction, ", distanceTraveled: ", distanceTraveled, " of ", maxDistance))

	# Stop! Hammer Time!
	if willReachMaxDistanceThisFrame:
		if debugMode: printDebug(str("distanceTraveled after movement: ", distanceTraveled, " >= maxDistance: ", maxDistance, ", shouldStopAtMaxDistance: ", shouldStopAtMaxDistance, ", shouldDeleteParentAtMaxDistance: ", shouldDeleteParentAtMaxDistance))
		self.isMoving = false
		self.didCrossMaxDistance.emit() # Emit the signal after updating the flag and before we delete the entity!
		if shouldDeleteParentAtMaxDistance: parent.queue_free()
