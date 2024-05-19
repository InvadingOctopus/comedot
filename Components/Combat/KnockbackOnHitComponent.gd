## Pushes the entity back when a [DamageReceivingComponent] takes damage.
## Requirements: [DamageReceivingComponent], [CharacterBody2D]

class_name KnockbackOnHitComponent
extends Component


#region Parameters
## The relative direction and magnitude of the knockback.
## i.e. a negative X value means knock backwards. Positive X means knock forwards.
@export var knockbackForce: Vector2 = Vector2(-100, -50)
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


func onDamageReceivingComponent_didReceiveDamage(amount: int, attackerFactions: int):
	# Invert the force based on the player's current direction
	# TODO: Better way of handling direction
	var sprite := parentEntity.findFirstChildOfType(AnimatedSprite2D)

	if not sprite.flip_h:
		knockbackForce.x = -knockbackForce.x

	# Apply force

	parentEntity.body.velocity += knockbackForce
	parentEntity.callOnceThisFrame(parentEntity.body.move_and_slide)
