## Displays visual effects and indicators when a [HealthComponent]'s health [Stat] value changes, negatively or positvely (damage or healing).
## NOTE: The effects may occur even when the Stat is modified elsewhere WITHOUT any damage happening to this component's parent entity,
## for example if the same "Health" Stat is shared between multiple Entities!
## TIP: To show effects only when ACTUAL DAMAGE is received, use [DamageVisualComponent]
## Requirements: [HealthComponent]
## @experimental

class_name HealthVisualComponent
extends Component

# TODO: Better implementation
# TODO: Reduce code duplication with [DamageVisualComponent]
# TBD:  Change to only showing healing and remaining health? And move damage effects to [DamageVisualComponent] only?


#region Parameters

## The node to display effects on, such as an [AnimatedSprite2D].
## If omitted, the first [AnimatedSprite2D] or [Sprite2D] sibling is used, if any, otherwise the parent entity is used.
@export var nodeToAnimate: CanvasItem

## The number of times to "blink" (hide then show) the entity sprite.
@export var blinkCount: int = 3

## The speed of the "blinking" animation (repeatedly hide and show).
@export var blinkDuration: float = 0.05

## If `true`, adds a red tint to the entity, increasing in intensity as the health decreases.
## @experimental
@export var shouldTint: bool = false:
	set(newValue):
		if newValue != shouldTint:
			shouldTint = newValue
			if self.is_node_ready(): # Avoid crash before _ready()
				if shouldTint and healthComponent: updateTint()
				else: nodeToAnimate.modulate = Color.WHITE

## Shows a [TextBubble] representing the current health value or the difference.
## The bubble is set as a child node of the entity, to avoid being affected by the effects on [nodeToAnimate].
@export var shouldEmitBubble: bool = true

@export var shouldShowRemainingHealth: bool = false ## If `true`, the [TextBubble] shows the REMAINING health instead of the DIFFERENCE.

#endregion


#region Dependencies
var healthComponent: HealthComponent: ## May also accept [ShieldedHealthComponent].
	get:
		if not healthComponent: healthComponent = parentEntity.findFirstComponentSubclass(HealthComponent)
		return healthComponent
#endregion


func _ready() -> void:
	if not nodeToAnimate: nodeToAnimate = parentEntity.findFirstChildOfAnyTypes([AnimatedSprite2D, Sprite2D])
	if debugMode: printDebug(str("nodeToAnimate: ", nodeToAnimate))

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
		Animations.blinkNode(nodeToAnimate, self.blinkCount, self.blinkDuration)

	updateTint() # Always update tint in case we just got healed.


## @experimental
func updateTint()-> void:
	if self.shouldTint and healthComponent:
		var health: Stat  = healthComponent.health
		var red:	float = (1.0 - (health.percentage / 100.0)) * 5.0 # Increase redness as health gets lower
		var targetModulate:  Color = nodeToAnimate.modulate
		targetModulate.r = red
		if debugMode: Debug.printVariables([health.logName, red, targetModulate])
		Animations.tweenProperty(nodeToAnimate, ^"modulate", targetModulate, 0.1)


func emitBubble(difference: int) -> void:
	var text: String = str(healthComponent.health.value) if shouldShowRemainingHealth else str(difference)
	var bubble: TextBubble = TextBubble.create(text, self.parentEntity) # NOTE: Emit the bubble from the ENTITY, so it's not affected by the effects on `nodeToAnimate`.
	bubble.label.label_settings.font_color = Color.GREEN if difference > 0 else Color.ORANGE
