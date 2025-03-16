## Set of movement physics parameters for [AsteroidsControlComponent].

class_name AsteroidsMovementParameters
extends Resource

#region Parameters

@export_group("Movement")

@export_range(50, 1000, 5) var thrust:			float = 300

@export var shouldApplyAcceleration:			bool  = true
@export_range(50, 2000, 5) var acceleration:	float = 800

## Completely disables slowdown from friction by reapplying the velocity from the previous frame.
## Use for scenarios like slippery surfaces such as ice.
@export var shouldMaintainPreviousVelocity:		bool  = false

@export var shouldMaintainMinimumVelocity:		bool  = false
@export_range(10, 1000, 50) var minimumSpeed:	float = 100

@export_group("Rotation")

@export_range(0, 20, 0.1) var turningSpeed:		float = 5

@export_group("Friction")

## Slow the velocity down each frame.
@export var shouldApplyFriction:				bool  = true
@export_range(10, 2000, 10) var friction:		float = 1000

#endregion
