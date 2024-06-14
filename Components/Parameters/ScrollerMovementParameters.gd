## Set of movement physics parameters for [ScrollerControlComponent].

class_name ScrollerMovementParameters
extends Resource

#region Parameters

# TBD: DESIGN: Using separate values for each axis seems more natural for this component instead of a vector, which may imply a unified motion.

@export_subgroup("Movement")

@export_range(50, 1000, 5) var minimumHorizontalSpeed:	float = 50
@export_range(50, 1000, 5) var maximumHorizontalSpeed:	float = 300
@export_range(50, 1000, 5) var horizontalThrust:		float = 100 ## Apply a constant horizontal thrust where is no player input. Positive = Right, Negative = Left

@export_range(50, 1000, 5) var minimumVerticalSpeed:	float = 0
@export_range(50, 1000, 5) var maximumVerticalSpeed:	float = 300
@export_range(50, 1000, 5) var verticalThrust:			float = 0	## Apply a constant vertical thrust where is no player input. Positive = Down, Negative = Up

@export var shouldApplyAcceleration:			bool  = true
@export_range(50, 2000, 5) var acceleration:	float = 800

## Completely disables slowdown from friction by reapplying the velocity from the previous frame.
## Use for scenarios like slippery surfaces such as ice.
@export var shouldMaintainPreviousVelocity:		bool  = false

@export_subgroup("Friction")
## Slow the velocity down each frame.
@export var shouldApplyFriction:				bool  = true
@export_range(10, 2000, 5) var friction:		float = 1000

#endregion
