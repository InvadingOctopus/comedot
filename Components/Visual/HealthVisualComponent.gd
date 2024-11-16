## Adds visual effects and indicators based on the state of a [HealthComponent].
## NOTE: The visuals are played when the [Stat]'s value is changed,
## so the effects may occur even when the Stat is modified elsewhere WITHOUT any damage happening to this component's parent entity,
## for example if sharing the same "Health" Stat on multiple Entities!
## @experimental

class_name HealthVisualComponent
extends Component

# TODO: Better implementation


#region Parameters
@export var shouldTint: bool = false ## If `true`, adds a red tint to the entity, increasing in intensity as the health decreases.
@export var shouldEmitBubble: bool = true ## Shows a [TextBubble] representing the current health value or the difference.
@export var shouldShowRemainingHealth: bool = false ## If `true`, the [TextBubble] shows the REMAINING health instead of the DISTANCE.
#endregion


#region Dependencies
var healthComponent: HealthComponent:
	get:
		if not healthComponent: healthComponent = parentEntity.findFirstComponentSubclass(HealthComponent)
		return healthComponent
#endregion


func _ready() -> void:
	connectSignals()


func connectSignals() -> void:
	healthComponent.healthDidDecrease.connect(self.onHealthComponent_healthChanged)
	healthComponent.healthDidIncrease.connect(self.onHealthComponent_healthChanged)


func onHealthComponent_healthChanged(difference: int) -> void:
	animate(difference)
	if shouldEmitBubble: emitBubble(difference)


## @experimental
func animate(difference: int) -> void:
	if difference < 0:
		Animations.blinkNode(self.parentEntity, 3)

	if shouldTint:
		var health: Stat  = healthComponent.health
		var red:	float = (1.0 - (health.percentage / 100.0)) * 5.0 # Increase redness as health gets lower
		var targetModulate:  Color = self.parentEntity.modulate
		targetModulate.r = red
		Animations.tweenProperty(self.parentEntity, ^"modulate", targetModulate, 0.1)


func emitBubble(difference: int) -> void:
	var text: String = str(healthComponent.health.value) if shouldShowRemainingHealth else str(difference)
	var bubble: TextBubble = TextBubble.create(self.parentEntity, text)
	bubble.label.label_settings.font_color = Color.GREEN if difference > 0 else Color.ORANGE
