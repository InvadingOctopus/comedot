## Pushes the entity back when its [DamageReceivingComponent] takes damage.
## TIP: Use a [VelocityClampComponent] to prevent the entity from "rocketing" away.
## WARNING: The knockback may not be applied if [member PlatformerMovementParameters.shouldStopInstantlyOnFloor] or [member PlatformerMovementParameters.shouldStopInstantlyInAir] is `true`.
## To fix, this component should be BELOW other such components in the entity's scene tree.
## Requirements: BEFORE [CharacterBodyComponent], [DamageReceivingComponent], AFTER [PlatformerPhysicsComponent]

class_name KnockbackOnHitComponent
extends CharacterBodyDependentComponentBase


#region Parameters

## The magnitude of the knockback. A scalar which multiplies the vector of the direction of the colliding [DamageComponent].
@export_range(0, 1000, 5) var knockbackForce: float = 150.0

@export var damageDirectionScale: Vector2 = Vector2(1, 1) ## Applied to the direction of the damage source.

## Any additional fixed vector to apply.
## For example, a slight jump when receiving damage in a platform game.
@export var additionalVector: Vector2 = Vector2.ZERO

## If `true` then the entity's existing velocity is set to 0 before applying the knockback.
## This ensures that the knockback is always noticeable even if the player is moving at a high speed towards the damage source.
@export var shouldZeroCurrentVelocity: bool = true

@export var isEnabled: bool = true

#endregion


#region State

## If `true`, calls [method knockback] to apply the [member recentDamageDirection] during [method physics_process].
## NOTE: This helps avoid negation of the knockback force by other components,
## such as [method PlatformerPhysicsComponent.processAllFriction] if any of the [PlatformerMovementParameters] `.shouldStopInstantly…` flags are true.
var shouldApplyKnockback:  bool

## The direction of the last damage source, to be applied during [method physics_process] if [member shouldApplyKnockback].
var recentDamageDirection: Vector2

#endregion


#region Dependencies
@onready var damageReceivingComponent: DamageReceivingComponent = coComponents.DamageReceivingComponent # TBD: Static or dynamic?

func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent, DamageReceivingComponent] # Cannot easily join with `super.getRequiredComponents()` because Godot goes dumb and treats it as an untyped Array
#endregion


func _ready() -> void:
	connectSignals()


func connectSignals() -> void:
	if damageReceivingComponent:
		damageReceivingComponent.didReceiveDamage.connect(self.onDamageReceivingComponent_didReceiveDamage)


func onDamageReceivingComponent_didReceiveDamage(damageComponent: DamageComponent, _amount: int, _attackerFactions: int) -> void:
	# TODO: Get the POINT OF CONTACT of the collision, not the positions of the entities/bodies/sprites etc.

	if not isEnabled: return

	# Get the direction of the colliding damage source
	# TBD: Should we get the position of the components, or their Area2D, or their parent entities?
	# TBD: Use velocities?

	var damageDirection: Vector2 = self.body.global_position.direction_to(damageComponent.global_position)
	self.recentDamageDirection = damageDirection
	self.shouldApplyKnockback = true


func _physics_process(_delta: float) -> void:
	if shouldApplyKnockback and isEnabled: # Check rarer flag first for performance
		knockback(recentDamageDirection)
		shouldApplyKnockback  = false
		recentDamageDirection = Vector2.ZERO


## Applies and returns a knockback force from the source of damage.
## ALERT: The knockback force may not be applied consistently if other components modify the [member CharacterBody2D.velocity],
## such as [method PlatformerPhysicsComponent.processAllFriction] if any of the [PlatformerMovementParameters] `.shouldStopInstantly…` flags are true.
## TIP: To fix, this [KnockbackOnHitComponent] should be below other such components in the entity's scene tree.
func knockback(damageDirection: Vector2) -> Vector2:
	if not isEnabled: return Vector2.ZERO

	# Should we ensures that the knockback is always noticeable even if the player is moving at a high speed towards the damage source?
	if shouldZeroCurrentVelocity:
		body.velocity = Vector2.ZERO

	# Process the damage direction
	
	# NOTE: In Godot VectorA * VectorB is not the same as a mathematical "cross product" or "dot product";
	# it treats the right-side vector as a pair of scalars, which is what we want here,
	# but for disambiguity, let's spell it out more explicitly:
	# TBD: Performance
	damageDirection.x *= damageDirectionScale.x
	damageDirection.y *= damageDirectionScale.y

	# Apply force in the opposite direction + any other vector, such as a upwards jump when taking damage in a platform game.
	var totalForce: Vector2 = ((-damageDirection) * knockbackForce) + additionalVector
	body.velocity += totalForce

	if debugMode: printDebug(str("damageDirection: ", damageDirection, ", knockbackForce: ", knockbackForce, ", additionalVector: ", additionalVector, ", totalForce:, ", totalForce, ", body.velocity: ", body.velocity))

	characterBodyComponent.queueMoveAndSlide()
	return totalForce
