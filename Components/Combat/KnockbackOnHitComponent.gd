## Pushes the entity back when its [DamageReceivingComponent] takes damage.
## TIP: Use a [VelocityClampComponent] to prevent the entity from "rocketing" away.
## WARNING: The knockback may not be applied if [member PlatformerMovementParameters.shouldStopInstantlyOnFloor] or [member PlatformerMovementParameters.shouldStopInstantlyInAir] is `true`.
## Requirements: [CharacterBodyComponent], [DamageReceivingComponent], AFTER [PlatformerPhysicsComponent]

class_name KnockbackOnHitComponent
extends CharacterBodyManipulatingComponentBase


#region Parameters

## The magnitude of the knockback. A scalar which multiplies the vector of the direction of the colliding [DamageComponent].
@export_range(0, 1000, 5) var knockbackForce: float = 150.0

## Any additional fixed vector to apply.
## For example, a slight jump when receiving damage in a platform game.
@export var additionalVector: Vector2 = Vector2.ZERO

## If `true` then the entity's existing velocity is set to 0 before applying the knockback.
## This ensures that the knockback is always noticeable even if the player is moving at a high speed towards the damage source.
@export var shouldZeroCurrentVelocity: bool = true

@export var isEnabled: bool = true

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
	self.knockback(damageDirection)


## Applies and returns a knockback force from the source of damage.
func knockback(damageDirection: Vector2) -> Vector2:
	if not isEnabled: return Vector2.ZERO

	# Should we ensures that the knockback is always noticeable even if the player is moving at a high speed towards the damage source?
	if shouldZeroCurrentVelocity:
		body.velocity = Vector2.ZERO

	# WARNING: The knockback force may not be applied consistently
	# because of `PlatformerPhysicsComponent.processAllFriction()` if `PlatformerMovementParameters.shouldStopInstantly…` is true.

	# Apply force in the opposite direction + any other vector, such as a upwards jump when taking damage in a platform game.
	var totalForce: Vector2 = (-damageDirection * knockbackForce) + additionalVector
	body.velocity += totalForce

	if shouldShowDebugInfo: printDebug(str("-damageDirection: ", -damageDirection, ", knockbackForce: ", knockbackForce, ", additionalVector: ", additionalVector, ", body.velocity: ", body.velocity))

	characterBodyComponent.queueMoveAndSlide()
	return totalForce
