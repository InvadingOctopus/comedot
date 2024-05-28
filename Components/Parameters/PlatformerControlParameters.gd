## Set of movement physics parameters for [PlatformerControlComponent] and [JumpControlComponent]

class_name PlatformerControlParameters
extends Resource


#region Parameters

@export_subgroup("Movement on Floor")

@export_range(50,  1000, 5) var speedOnFloor:			float = 100

## If `false`, then [member speed] is applied directly.
@export var shouldApplyAccelerationOnFloor:				bool  = true
@export_range(50,  1000, 5) var accelerationOnFloor:	float = 800

@export var shouldApplyFrictionOnFloor:					bool  = true
@export_range(100, 2000, 5) var frictionOnFloor:		float = 1000


@export_subgroup("Movement in Air")

@export var shouldAllowMovementInputInAir:				bool  = true

@export_range(0,   1000, 5) var speedInAir:				float = 100.0

## If `false`, then [member speed] is applied directly.
@export var shouldApplyAccelerationInAir:				bool  = true
@export_range(50,  1000, 5) var accelerationInAir:		float = 400.0

@export var shouldApplyFrictionInAir:					bool  = true ## Applies horizontal friction when not on a floor (not gravity).
@export_range(0,   2000, 5) var frictionInAir:			float = 200.0 ## Applies horizontal friction when not on a floor (not gravity).


@export_subgroup("Jump")

@export_range(0, 5, 1) var maxNumberOfJumps: int = 2

@export_range(-1000, -100, 5) var jumpVelocity1stJump:		float = -350.0 ## NOTE: This should be a NEGATIVE value because a positive Y axis value means downwards.
@export_range(-1000, -100, 5) var jumpVelocity1stJumpShort:	float = -175.0 ## NOTE: This should be a NEGATIVE value because a positive Y axis value means downwards.
@export_range(-1000, -100, 5) var jumpVelocity2ndJump:		float = -300.0 ## NOTE: This should be a NEGATIVE value because a positive Y axis value means downwards.

#endregion
