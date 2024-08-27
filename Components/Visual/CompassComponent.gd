## Tracks a node and displays an optional compass to indicate the angle between that node and this component's parent [Entity].
class_name CompassComponent
extends Component


#region Parameters

@export var nodeToTrack: Node2D

## Use a different node for the compass indicator, such as a minimap UI element.
@export var compassIndicatorOverride: Node2D

@export var shouldRotateInstantly := false

@export_range(0.1, 20, 0.1) var rotationSpeed: float = 10.0

@export var shouldDisappearWhenNear := true
@export var proximityDistance: float = 100.0

#endregion


func _process(delta: float) -> void:

	var compass: Node2D

	if compassIndicatorOverride: compass = compassIndicatorOverride
	else: compass = %CompassIndicator

	var targetPosition := nodeToTrack.global_position

	if shouldDisappearWhenNear:
		var distance: float = parentEntity.global_position.distance_to(targetPosition)

		if distance < proximityDistance or is_equal_approx(distance, proximityDistance):
			compass.visible = false
		else:
			compass.visible = true
	else:
		compass.visible = true

	# NOTE: Keep rotating the compass even if it is hidden, to support other features that may use the compass' rotation.

	if shouldRotateInstantly:
		compass.look_at(targetPosition)
	else:
		var parentEntityPosition := parentEntity.global_position
		var rotateFrom := compass.global_rotation
		var rotateTo   := parentEntityPosition.angle_to_point(targetPosition)

		compass.global_rotation = rotate_toward(rotateFrom, rotateTo, rotationSpeed * delta)

