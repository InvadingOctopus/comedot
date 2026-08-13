## Displays visual effects and indicators when a [HealthComponent]'s health [Stat] value changes, negatively or positvely (damage or healing).
## NOTE: The effects may occur even when the Stat is modified elsewhere WITHOUT any damage happening to this component's parent entity,
## for example if the same "Health" Stat is shared between multiple Entities!
## TIP: Use [DamageVisualComponent to show effects only when ACTUAL DAMAGE is received, i.e. on [signal DamageReceivingComponent.didReceiveDamage
## ALERT: [HealthVisualComponent] is not triggered if a [ShieldedHealthComponent] absorbs damage.
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
@export var nodeToAnimate:	CanvasItem

## The number of times to "blink" (hide then show) the entity sprite.
@export var blinkCount:		int   = 3

## The speed of the "blinking" animation (repeatedly hide and show).
@export var blinkDuration:	float = 0.05

## If `true`, adds a red tint to the entity, increasing in intensity as the health decreases.
## @experimental
@export var shouldTint:		bool:
	set(newValue):
		if newValue != shouldTint:
			shouldTint = newValue
			if self.is_node_ready(): # Avoid crash before _ready()
				if shouldTint and healthComponent: updateTint()
				else: nodeToAnimate.modulate = Color.WHITE

## Shows a [TextBubble] representing the current health value or the difference.
## The bubble is set as a child node of the entity, to avoid being affected by the effects on [nodeToAnimate].
@export var shouldEmitBubble: bool = true
@export var detachedBubbles:  bool ## If `true` & [member shouldEmitBubble], text bubbles will not move together with the target entity's sprite.

@export var shouldShowRemainingHealth: bool = false ## If `true`, the [TextBubble] shows the REMAINING health instead of the DIFFERENCE.

#endregion


#region Dependencies
var healthComponent: HealthComponent: ## May also accept [ShieldedHealthComponent].
	get:
		if not healthComponent: healthComponent = getCoComponent(HealthComponent, true) # findSubclasses
		return healthComponent
#endregion


func _ready() -> void:
	if not nodeToAnimate: nodeToAnimate = entity.findFirstChildOfAnyTypes([AnimatedSprite2D, Sprite2D])
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
		Animations.blink(nodeToAnimate, self.blinkCount, self.blinkDuration, true) # initialVisibility, to avoid ending up invisible after the animation finishes

	updateTint() # Always update tint in case we just got healed.


## @experimental
func updateTint()-> void:
	if self.shouldTint and healthComponent:
		var health: Stat  = healthComponent.health
		var red:	float = (1.0 - health.percentNormalized) * 5.0 # Increase redness as health gets lower
		var targetModulate:  Color = nodeToAnimate.modulate
		targetModulate.r  = red
		if debugMode: Debug.printVariables([health.logName, red, targetModulate])
		Animations.tweenProperty(nodeToAnimate, ^"modulate", targetModulate, 0.1)


func emitBubble(difference: int) -> void:
	var color: Color = Color(0, 1, 0) if difference > 0 else Color(1, 0.5, 0)
	color.b += [0, +0.1, +0.2, +0.3].pick_random() # Some variation for when there's a lot of bubbles

	# Emit the bubble from the entity so it isn't affected by effects on `nodeToAnimate`
	# not appendDisplayName, not colorBubble because we use our own colors
	if shouldShowRemainingHealth:
		GameplayResourceBubble.createForStat(
			healthComponent.health,
			entity if not detachedBubbles else entity.get_parent(),
			Vector2(0, -16) if not detachedBubbles else entity.global_position,
			false, false) \
				.ui.label.label_settings.font_color = color
	else:
		GameplayResourceBubble.createForStatChange(
			healthComponent.health,
			entity if not detachedBubbles else entity.get_parent(),
			Vector2(0, -16) if not detachedBubbles else entity.global_position,
			false, false) \
				.ui.label.label_settings.font_color = color
