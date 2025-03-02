## Sets a maximum and minimum limit for the entity's [member CharacterBody2D.velocity].
## Useful for clamping a character's velocity when there are multiple components affecting movement.
## TIP: May be used to prevent "rocketing" away due to a [GunComponent] with a fast rate of fire, or a [KnockbackComponent] etc.
## Requirements: BEFORE [CharacterBodyComponent], AFTER control components

class_name VelocityClampComponent
extends CharacterBodyDependentComponentBase

# TODO: Fix minimum velocity. Currently can only have positive values and travel right/down.
# TODO: Correct for diagonal movement; should not reach the same max velocity as movement on only 1 axis.


#region Parameters
@export_range(0, 5000, 5) var maximumVelocityX: float = 100 ## Ignored if <= 0
@export_range(0, 5000, 5) var maximumVelocityY: float = 100 ## Ignored if <= 0
@export_range(0, 5000, 5) var minimumVelocityX: float ## Ignored if <= 0. NOTE: Will result in constant movement to the right.
@export_range(0, 5000, 5) var minimumVelocityY: float ## Ignored if <= 0. NOTE: Will result in constant movement downwards.
@export var isEnabled: bool = true
#endregion


func _physics_process(_delta: float) -> void:
	if not isEnabled: return

	# Cache to reduce the number of property checks and function calls

	var velocity: Vector2 = body.velocity
	var absoluteVelocityX: float = absf(velocity.x)
	var absoluteVelocityY: float = absf(velocity.y)
	 # NOTE: Use the signs of the original velocity, because "absoluteVelocity" will already be unsigned!
	var signX: float = signf(velocity.x)
	var signY: float = signf(velocity.y)

	# NOTE: Clamps only apply if > 0

	if maximumVelocityX > 0 and absoluteVelocityX > maximumVelocityX:
		body.velocity.x = maximumVelocityX * signX

	if minimumVelocityX > 0 and absoluteVelocityX < minimumVelocityX:
		body.velocity.x = minimumVelocityX * signX

	if maximumVelocityY > 0 and absoluteVelocityY > maximumVelocityY:
		body.velocity.y = maximumVelocityY * signY

	if minimumVelocityY > 0 and absoluteVelocityY < minimumVelocityY:
		body.velocity.y = minimumVelocityY * signY

	if debugMode: Debug.watchList.velocity = body.velocity
