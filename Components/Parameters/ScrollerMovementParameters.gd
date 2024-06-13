## Set of movement physics parameters for [ScrollerControlComponent].

class_name ScrollerMovementParameters
extends Resource

#region Parameters

@export_subgroup("Movement")
@export_range(50, 1000, 5) var speed:			float = 300
@export_range(50, 1000, 5) var horizontalThrust:float = 100
@export_range(50, 1000, 5) var verticalThrust:	float = 0

@export var shouldApplyAcceleration:			bool  = true
@export_range(50, 2000, 5) var acceleration:	float = 800

## Completely disables slowdown from friction by reapplying the velocity from the previous frame.
## Use for scenarios like slippery surfaces such as ice.
@export var shouldMaintainPreviousVelocity:		bool  = false

@export var shouldMaintainMinimumVelocity:		bool  = false
@export_range(10, 1000, 5) var minimumSpeed:	float = 100

@export_subgroup("Friction")
## Slow the velocity down each frame.
@export var shouldApplyFriction:				bool  = true
@export_range(10, 2000, 5) var friction:		float = 1000

@export var shouldResetVelocityOnCollision:		bool  = true

#endregion
