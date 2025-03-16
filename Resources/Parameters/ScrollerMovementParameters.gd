## Set of movement physics parameters for [ScrollerControlComponent].

class_name ScrollerMovementParameters
extends Resource

# NOTE: DESIGN: Using separate values for each axis seems more natural for this component instead of a vector, which may imply a unified motion.
# TBD: TODO: Separate friction values for each axis/direction?

#region Parameters

@export var shouldApplyAcceleration:			bool  = true
@export_range(50, 2000, 5) var acceleration:	float = 800

## Completely disables slowdown from friction by reapplying the velocity from the previous frame.
## Use for scenarios like slippery surfaces such as ice.
@export var shouldMaintainPreviousVelocity:		bool  = false


@export_group("Horizontal Movement")

@export_range(0,     1000, 5) var horizontalSpeed:				float = 300  ## The speed applied when the player presses the left or right controls.
@export_range(-1000, 1000, 5) var horizontalVelocityDefault:	float = 100  ## Apply a constant horizontal thrust when is no player input. Positive = Right, Negative = Left

@export_range(-1000, 1000, 5) var horizontalVelocityMin:		float = 50   ## Keeps the horizontal velocity above or at this value. A positive value will maintain a rightwards movement.
@export_range(-1000, 1000, 5) var horizontalVelocityMax:		float = 300  ## Keeps the horizontal velocity under or at this value. A negative value will maintain a leftwards movement.


@export_group("Vertical Movement")

@export_range(0,     1000, 5) var verticalSpeed:				float = 300  ## The speed applied when the player presses the up or down controls.
@export_range(-1000, 1000, 5) var verticalVelocityDefault:		float = 0	 ## Apply a constant vertical thrust when is no player input. Positive = Down, Negative = Up

@export_range(-1000, 1000, 5) var verticalVelocityMin:			float = -300 ## Keeps the vertical velocity above or at this value. A positive value will maintain a downwards movement.
@export_range(-1000, 1000, 5) var verticalVelocityMax:			float = 300  ## Keeps the vertical velocity under or at this value. A negative value will maintain a upwards movement.


@export_group("Friction")

## Slow the velocity down each frame.
@export var shouldApplyFriction:				bool  = true
@export_range(10, 2000, 5) var friction:		float = 1000

#endregion


#region State
var velocityMin: Vector2 ## TODO: Cache from horizontalVelocityMin & verticalVelocityMin
var velocityMax: Vector2 ## TODO: Cache from horizontalVelocityMax & verticalVelocityMax
#endregion
