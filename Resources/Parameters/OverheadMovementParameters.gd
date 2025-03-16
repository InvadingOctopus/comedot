## Set of movement physics parameters for [OverheadControlComponent].

class_name OverheadMovementParameters
extends Resource


#region Parameters

@export_group("Movement")

@export_range(0, 1000, 5) var speed:			float = 300.0

@export var shouldApplyAcceleration:			bool  = true
@export_range(0, 2000, 5) var acceleration:		float = 800.0

## Completely disables slowdown from friction by reapplying the velocity from the previous frame.
## Use for scenarios like slippery surfaces such as ice.
@export var shouldMaintainPreviousVelocity:		bool  = false

@export var shouldMaintainMinimumVelocity:		bool  = false
@export_range(10, 1000, 50) var minimumSpeed:	float = 100.0

@export_group("Friction")

## Slow the velocity down each frame.
@export var shouldApplyFriction:				bool  = true
@export_range(10, 2000, 10) var friction:		float = 1000.0

#endregion
