## Set of jump physics parameters for [JumpControlComponent] and [PlatformerPhysicsComponent]
## IMPORTANT: NOTE: The jump velocities are multiplied by the [member CharacterBody2D.up_direction] and use the vertical axis only,
## so the velocities should be a POSITIVE `y` value for an UPWARDS jump even though Godot's Y axis DECREASES upwards.
## TIP: For "inverted gravity" situations, modify [member CharacterBody2D.up_direction] on the [CharacterBodyComponent].

class_name PlatformerJumpParameters
extends Resource

# TODO: Maximum limit for wall jumps


#region Parameters

@export_group("Jump")

@export_range(0, 10, 1) var maxNumberOfJumps: int = 2

## NOTE: Multiplied by [member CharacterBody2D.up_direction].
@export_range(-1000, 1000, 10, "or_greater", "or_less") var jumpVelocity1stJump: float = 350 

## A shorter maximum velocity for the 1st jump if the player releases the Jump button quickly.
## NOTE: Does NOT apply to mid-air or wall jumps.
## NOTE: Multiplied by [member CharacterBody2D.up_direction].
@export_range(-1000, 1000, 10, "or_greater", "or_less") var jumpVelocity1stJumpShort: float = 150

## The velocity of the 2nd and all subsequent jumps in a single chain (before touching the ground).
## NOTE: Multiplied by [member CharacterBody2D.up_direction].
@export_range(-1000, 1000, 10, "or_greater", "or_less") var jumpVelocity2ndJump: float = 300

## Allows a "grace period" to let the player to jump just after walking off a platform floor.
## This may provide a better feel of control in some games.
## Named after Wile E. Coyote from Road Runner :>
@export var allowCoyoteJump: bool = true

## The "grace period" for allowing the player to jump just after walking off a platform floor.
@export_range(0, 10, 0.05, "seconds") var coyoteJumpTimer: float = 0.15


@export_group("Wall Jump")

@export var allowWallJump: bool = true

## NOTE: Multiplied by [member CharacterBody2D.up_direction].
@export_range(-1000, 1000, 10, "or_greater", "or_less") var wallJumpVelocity: float = 300

## The force with which the player bounces away horizontally from the wall during a wall jump.
@export_range(10, 1000, 10, "or_greater") var wallJumpVelocityX: float = 150

## The "grace period" for allowing the player to jump just after leaving a wall.
@export_range(0, 10, 0.05, "seconds") var wallJumpTimer: float = 0.1

## If `true`, then wall jumps do not count towards [member maxNumberOfJumps], allowing the player to jump between walls indefinitely.
@export var decreaseJumpCountOnWallJump: bool = true

#endregion
