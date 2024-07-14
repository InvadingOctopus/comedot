## Set of jump physics parameters for [JumpControlComponent] and [PlatformerPhysicsComponent]

class_name PlatformerJumpParameters
extends Resource

# TODO: Maximum limit for wall jumps


#region Parameters

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
@export_range(0, 10, 0.1, "seconds") var coyoteJumpTimer:	float = 0.15

@export_subgroup("Wall Jump")

@export var allowWallJump:									bool  = true

## NOTE: This should be a NEGATIVE value because a positive Y axis value means downwards.
@export_range(-1000, -10, 5)	var wallJumpVelocity:			float = -300

## The force with which the player bounces away horizontally from the wall during a wall jump.
@export_range(10, 1000, 5)	var wallJumpVelocityX:			float = 150

## The "grace period" for allowing the player to jump just after leaving a wall.
@export_range(0, 10, 0.1, "seconds") var wallJumpTimer:		float = 0.1

#endregion
