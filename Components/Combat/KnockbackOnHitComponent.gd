## Pushes the entity back when a [DamageReceivingComponent] takes damage.
## Requirements: [CharacterBody2D], [DamageReceivingComponent]

class_name KnockbackOnHitComponent
extends Component


#region Parameters

## The magnitude of the knockback. A scalar which multiplies the vector of the direction of the colliding [DamageComponent].
@export_range(0, 1000, 5) var knockbackForce: float = 150.0

## If `true` then the entity's existing velocity is set to 0 before applying the knockback.
## This ensures that the knockback is always noticeable even if the player is moving at a high speed towards the damage source.
@export var shouldZeroCurrentVelocity := true

@export var isEnabled := true

#endregion


#region State
var damageReceivingComponent: DamageReceivingComponent:
	get: return self.findCoComponent(DamageReceivingComponent)
#endregion


func _ready():
	connectCoComponents()


func connectCoComponents():
	damageReceivingComponent.didReceiveDamage.connect(self.onDamageReceivingComponent_didReceiveDamage)


func onDamageReceivingComponent_didReceiveDamage(damageComponent: DamageComponent, amount: int, attackerFactions: int):
	if not isEnabled: return

	# Get the direction of the colliding damage source
	var direction := parentEntity.global_position.direction_to(damageComponent.area.global_position)

	# Should we ensures that the knockback is always noticeable even if the player is moving at a high speed towards the damage source?
	if shouldZeroCurrentVelocity:
		parentEntity.body.velocity = Vector2.ZERO

	# Apply force in the opposite direction
	parentEntity.body.velocity += -direction * knockbackForce
	parentEntity.callOnceThisFrame(parentEntity.body.move_and_slide)
