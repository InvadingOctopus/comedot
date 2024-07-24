## Pushes the entity back when a [DamageReceivingComponent] takes damage.
## WARNING: The knockback may not be applied if [member PlatformerMovementParameters.shouldStopInstantlyOnFloor] or [member PlatformerMovementParameters.shouldStopInstantlyInAir] is `true`.
## Requirements: [CharacterBody2D], [DamageReceivingComponent]

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
@export var shouldShowDebugInfo: bool = false

#endregion


#region State
var damageReceivingComponent: DamageReceivingComponent:
	get: return self.getCoComponent(DamageReceivingComponent)
#endregion


func _ready() -> void:
	connectCoComponents()


func connectCoComponents() -> void:
	damageReceivingComponent.didReceiveDamage.connect(self.onDamageReceivingComponent_didReceiveDamage)


func onDamageReceivingComponent_didReceiveDamage(damageComponent: DamageComponent, _amount: int, _attackerFactions: int) -> void:
	if not isEnabled: return

	# Get the direction of the colliding damage source
	var damageDirection := parentEntity.global_position.direction_to(damageComponent.area.global_position)

	# Should we ensures that the knockback is always noticeable even if the player is moving at a high speed towards the damage source?
	if shouldZeroCurrentVelocity:
		body.velocity = Vector2.ZERO

	# FIXME: BUG: The knockback force is not being applied consistently; 
	# even though the velocity is changed here, the body does not move the expected distance.
	# CAUSE: `PlatformerPhysicsComponent.processAllFriction()` if `PlatformerMovementParameters.shouldStopInstantly…` is true
	
	# Apply force in the opposite direction
	body.velocity += -damageDirection * knockbackForce
	
	# Any more? For example, a jump when taking damage in a platform game.
	body.velocity += additionalVector
	
	if shouldShowDebugInfo: printLog(str("-damageDirection: ", -damageDirection, ", knockbackForce: ", knockbackForce, ", additionalVector: ", additionalVector, ", body.velocity: ", body.velocity))
	
	characterBodyComponent.queueMoveAndSlide()
