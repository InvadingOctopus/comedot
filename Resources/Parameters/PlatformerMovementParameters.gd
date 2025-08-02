## Set of movement physics parameters for [PlatformerPhysicsComponent], [JumpComponent] and [ClimbComponent]

class_name PlatformerMovementParameters
extends Resource


#region Parameters

@export_group("Movement on Floor")

@export_range(0, 1000, 4) var speedOnFloor:			float = 96

## If `false`, then [member speed] is applied directly.
@export var shouldApplyAccelerationOnFloor:			bool  = true
@export_range(0, 4800, 4) var accelerationOnFloor:	float = 800

## Should the horizontal velocity reset to 0 as soon as there is no input?
## WARNING: If this is `true` then velocity changes from other components such as [KnockbackOnHitComponent] may be cancelled.
@export var shouldStopInstantlyOnFloor:				bool  = false

## Should the horizontal velocity gradually slow down when there is no input?
@export var shouldApplyFrictionOnFloor:				bool  = true
@export_range(5, 4800, 4) var frictionOnFloor:		float = 1000


@export_group("Movement in Air")

## 1.0 is normal gravity as defined in Project Settings/Physics/2D
@export_range(-10, 10, 0.05) var gravityScale:		float = 1

## Allow changes in the horizontal velocity while in air?
@export var shouldAllowMovementInputInAir:			bool  = true

@export_range(0, 1000, 4) var speedInAir:			float = 96

## If `false`, then [member speed] is applied directly.
@export var shouldApplyAccelerationInAir:			bool  = true
@export_range(0, 1000, 4) var accelerationInAir:	float = 400

## Should the horizontal velocity reset to 0 as soon as there is no input?
## WARNING: If this is `true` while [member shouldAllowMovementInputInAir] is `false` then there will be NO horizontal movement in air; only straight vertical jumps.
## WARNING: If this is `true` then velocity changes from other components such as [KnockbackOnHitComponent] may be cancelled.
@export var shouldStopInstantlyInAir:				bool  = false

## Should the horizontal velocity gradually slow down when there is no input?
@export var shouldApplyFrictionInAir:				bool  = true ## Applies horizontal friction when not on a floor (not gravity).
@export_range(0, 4800, 4) var frictionInAir:		float = 200 ## Applies horizontal friction when not on a floor (not gravity).


@export_group("Climbing")

@export_range(0, 2000, 4) var climbUpSpeed:		float = 96 ## NOTE: Should be POSITIVE, as it is multiplied by the [member CharacterBody2D.up_direction].y (which is -1 for UP) to allow for inverted gravity etc.
@export_range(0, 2000, 4) var climbDownSpeed:	float = 160 ## NOTE: Multiplied by the INVERSE of [member CharacterBody2D.up_direction].y (which is -1 for UP)

#endregion
