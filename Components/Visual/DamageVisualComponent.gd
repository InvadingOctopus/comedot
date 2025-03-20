## Display visual effecs when a [DamageReceivingComponent] receives damage.
## TIP: To monitor a "Health" [Stat] and display healing effects, use [HealthVisualComponent].
## Requirements: [DamageReceivingComponent], [HealthComponent]
## @experimental

class_name DamageVisualComponent
extends Component


# TODO: Better implementation
# TODO: Reduce code duplication with [HealthVisualComponent]


#region Parameters

## If `true`, adds a red tint to the entity, increasing in intensity as the health decreases.
## @experimental
@export var shouldTint: bool = false:
	set(newValue):
		if newValue != shouldTint:
			shouldTint = newValue
			if shouldTint: updateTint()
			else: self.parentEntity.modulate = Color.WHITE


@export var shouldEmitBubble: bool = true ## Shows a [TextBubble] representing the current health value or the difference.
@export var shouldShowRemainingHealth: bool = false ## If `true`, the [TextBubble] shows the REMAINING health instead of the DIFFERENCE.

#endregion


#region Dependencies
@onready var damageReceivingComponent: DamageReceivingComponent = coComponents.DamageReceivingComponent

var healthComponent: HealthComponent: ## May also accept [ShieldedHealthComponent].
	get:
		# Check for `parentEntity` in case this getter was called by the `shouldTint` setter
		if parentEntity and not healthComponent: healthComponent = parentEntity.findFirstComponentSubclass(HealthComponent)
		return healthComponent
#endregion


func _ready() -> void:
	connectSignals()


func connectSignals() -> void:
	damageReceivingComponent.didReceiveDamage.connect(self.onDamageReceivingComponent_didReceiveDamage)


func onDamageReceivingComponent_didReceiveDamage(_damageComponent: DamageComponent, amount: int, _attackerFactions: int) -> void:
	if amount >= 1:
		animate(amount)
		if shouldEmitBubble: emitBubble(amount)

	updateTint() # Always update tint in case we just got healed.


## @experimental
func updateTint()-> void:
	if self.shouldTint and healthComponent:
		var health: Stat  = healthComponent.health
		var red:	float = (1.0 - (health.percentage / 100.0)) * 5.0 # Increase redness as health gets lower
		var targetModulate:  Color = self.parentEntity.modulate
		targetModulate.r = red
		if debugMode: Debug.printVariables([health.logName, red, targetModulate])
		Animations.tweenProperty(self.parentEntity, ^"modulate", targetModulate, 0.1)


## @experimental
func animate(damageAmount: int) -> void:
	if damageAmount > 0:
		Animations.blinkNode(self.parentEntity, 3)


func emitBubble(damageAmount: int) -> void:
	var text: String
	if self.shouldShowRemainingHealth and healthComponent: text = str(healthComponent.health.value)
	else: str("-," if damageAmount > 0 else "", damageAmount)

	var bubble: TextBubble = TextBubble.create(text, self.parentEntity)
	bubble.label.label_settings.font_color = Color.ORANGE
