## Set of jump physics parameters for [JumpComponent] and [PlatformerPhysicsComponent]
## IMPORTANT: NOTE: The jump velocities are multiplied by the [member CharacterBody2D.up_direction] and use the vertical axis only,
## so the velocities should be a POSITIVE `y` value for an UPWARDS jump even though Godot's Y axis DECREASES upwards.
## TIP: To modify the various time durations, enable "Editable Children" for [JumpComponent] and edit the [Timers] nodes.
## TIP: For "inverted gravity" situations, modify [member CharacterBody2D.up_direction] on the [CharacterBodyComponent].

class_name PlatformerJumpParameters
extends Resource

# TODO: Maximum limit for wall jumps


#region Parameters

@export_group("Jumps")

## If > 1 then jumping are allowed in mid-air AFTER jumping from the ground/floor.
## If > 2 then multiple jumps are allowed in mid-air.
## If 0, then jumping is disabled.
@export_range(0, 10, 1) var maxNumberOfJumps: int = 2

## Allows a "input buffer period" to let the player press Jump a few milliseconds BEFORE landing on the ground/floor.
## If the character lands within the buffer window, the jump executes immediately on landing.
## This compensates for visual/reaction timing and may provide a better feel of control in some games.
## NOTE: This is the inverse of [member allowCoyoteJump]: "coyote" = late jump after leaving ground, buffer = early jump before touching ground.
## TIP: To set the duration [Timer], modify [member JumpComponent.inputBufferTimer]
@export var allowInputBuffer:	bool = true

## If `true`, then the player can jump in mid-air while falling WITHOUT initiating a jump from the ground/floor first.
## i.e. the "air" also counts as a "floor" state.
## NOTE: NOT related to [member allowCoyoteJump] or [member JumpComponent.coyoteJumpTimer]
@export var allowFallJump:		bool = false

## Allows a "grace period" to let the player to jump just after walking off a platform floor.
## This may provide a better feel of control in some games.
## Named after Wile E. Coyote from Road Runner :>
## NOTE: NOT related to [member allowFallJump]
## TIP: To set the duration [Timer], modify [member JumpComponent.coyoteJumpTimer]
@export var allowCoyoteJump:	bool = true


@export_group("Velocities")

## The "height" of the first jump initiated from the ground/floor (or air if [member allowFallJump])
## NOTE: Multiplied by [member CharacterBody2D.up_direction]
@export_range(-1000, 1000, 4, "or_greater", "or_less") var jumpVelocity1stJump:		 float = 360

## A shorter maximum velocity for the 1st jump if the player releases the Jump button quickly.
## NOTE: Does NOT apply to wall jumps or the 2nd or later mid-air jumps.
## NOTE: Multiplied by [member CharacterBody2D.up_direction]
@export_range(-1000, 1000, 4, "or_greater", "or_less") var jumpVelocity1stJumpShort: float = 160

## The velocity of the second and all subsequent jumps in a single "chain" (before landing again and touching the ground/floor).
## NOTE: Multiplied by [member CharacterBody2D.up_direction]
@export_range(-1000, 1000, 4, "or_greater", "or_less") var jumpVelocity2ndJump:		 float = 280


@export_group("Wall Jump")

## Allow jumping off/away from a wall?
## TIP: To set the duration [Timer], modify [member JumpComponent.wallJumpTimer]
@export var allowWallJump: bool = true

## If `true`, then wall jumps do not count towards [member maxNumberOfJumps], allowing the player to jump between walls indefinitely.
@export var decreaseJumpCountOnWallJump: bool = true

## NOTE: Multiplied by [member CharacterBody2D.up_direction].
@export_range(-1000, 1000, 8, "or_greater", "or_less") var wallJumpVelocity: float = 320

## The force with which the player bounces away horizontally from the wall during a wall jump.
@export_range(8, 1000, 8, "or_greater") var wallJumpVelocityX: float = 160

#endregion
