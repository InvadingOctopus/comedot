## Set of movement physics parameters for [OverheadControlComponent].

class_name OverheadMovementParameters
extends Resource


#region Parameters

@export_group("Movement")

@export_range(0, 1000, 4) var speed:		float = 320

@export var shouldApplyAcceleration:		bool  = true
@export_range(0, 2000, 4) var acceleration:	float = 800

## Completely disables slowdown from friction by reapplying the velocity from the previous frame.
## Use for scenarios like slippery surfaces such as ice.
@export var shouldMaintainPreviousVelocity:	bool  = false

@export var shouldMaintainMinimumVelocity:	bool  = false
@export_range(8, 1000, 4) var minimumSpeed:	float = 96

@export_group("Friction")

## Gradually slows the velocity down each frame. If `false` then the movement stops abruptly when there is no input,
## unless [member shouldMaintainPreviousVelocity] or [member shouldMaintainMinimumVelocity] is `true`.
@export var shouldApplyFriction:			bool  = true
@export_range(8, 2000, 4) var friction:		float = 1000

#endregion
