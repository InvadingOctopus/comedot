## Set of movement physics parameters for [PlatformerControlComponent] and [JumpControlComponent]

class_name PlatformerMovementParameters
extends Resource

# TBD: Should walking and jumping parameter sets be different Resources? 
# TODO: Maximum limit for wall jumps


#region Parameters

@export_subgroup("Movement on Floor")

@export_range(0, 1000, 5) var speedOnFloor:			float = 100

## If `false`, then [member speed] is applied directly.
@export var shouldApplyAccelerationOnFloor:			bool  = true
@export_range(0, 1000, 5) var accelerationOnFloor:	float = 800

@export var shouldApplyFrictionOnFloor:				bool  = true
@export_range(5, 5000, 5) var frictionOnFloor:		float = 1000


@export_subgroup("Movement in Air")

## 1.0 is normal gravity as defined in Project Settings/Physics/2D
@export_range(-10, 10, 0.05) var gravityScale:		float = 1

@export var shouldAllowMovementInputInAir:			bool  = true

@export_range(0, 1000, 5) var speedInAir:			float = 100

## If `false`, then [member speed] is applied directly.
@export var shouldApplyAccelerationInAir:			bool  = true
@export_range(0, 1000, 5) var accelerationInAir:	float = 400

@export var shouldApplyFrictionInAir:				bool  = true ## Applies horizontal friction when not on a floor (not gravity).
@export_range(0, 5000, 5) var frictionInAir:		float = 200 ## Applies horizontal friction when not on a floor (not gravity).


@export_subgroup("Jump")

@export_range(0, 5, 1) var maxNumberOfJumps:				int = 2

## NOTE: This should be a NEGATIVE value because a positive Y axis value means downwards.
@export_range(-1000, -10, 5) var jumpVelocity1stJump:		float = -350 

## A shorter maximum velocity for the 1st jump if the player releases the Jump button quickly.
## NOTE: This should be a NEGATIVE value because a positive Y axis value means downwards.
@export_range(-1000, -10, 5) var jumpVelocity1stJumpShort:	float = -175

## The velocity of the 2nd and later jumps.
## NOTE: This should be a NEGATIVE value because a positive Y axis value means downwards.
@export_range(-1000, -10, 5) var jumpVelocity2ndJump:		float = -300

## The "grace period" for allowing the player to jump just after walking off a platform floor.
## Set to `0` to disable coyote jumping.
## This may provide a better feel of control in some games.
## Named after Wile E. Coyote from Road Runner :>
@export_range(0, 10, 0.1, "seconds") var coyoteJumpTimer:	float = 0.1

@export var allowWallJump:									bool  = true

## NOTE: This should be a NEGATIVE value because a positive Y axis value means downwards.
@export_range(-1000, -10, 5) var wallJumpVelocity:			float = -300

## The force with which the player bounces away horizontally from the wall during a wall jump.
@export_range(-1000, -10, 5) var wallJumpVelocityX:			float = 150

## The "grace period" for allowing the player to jump just after leaving a wall.
@export_range(0, 10, 0.1, "seconds") var wallJumpTimer:		float = 0.1

#endregion
