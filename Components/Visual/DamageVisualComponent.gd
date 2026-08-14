## Display visual effects when a [DamageReceivingComponent] emits [signal DamageReceivingComponent.didReceiveDamage]
## NOTE: This includes damage values even if the damage is absorbed by a [ShieldedHealthComponent] etc.
## TIP: Use [HealthVisualComponent] to monitor a "Health" [Stat] via [HealthComponent] and include healing effects.
## Requirements: [DamageReceivingComponent]

class_name DamageVisualComponent
extends Component


#region Parameters

## The node to display effects on, such as an [AnimatedSprite2D]
## If omitted, the first [AnimatedSprite2D] or [Sprite2D] sibling is used, if any, otherwise the parent entity is used.
@export var nodeToAnimate:	CanvasItem

@export var blinkCount:		int    = 3	 ## The number of times to "blink" (hide then show) the [member nodeToAnimate]

@export var blinkDuration:	float  = 0.05 ## The speed of the "blinking" animation (repeatedly hide and show).

@export var shouldEmitBubble: bool = true ## Shows a [TextBubble] representing the amount of damage received.
@export var bubbleOffset:     Vector2 = Vector2(0, -16) ## The position relative to the entity from which bubbles are bobbled.
@export var detachedBubbles:  bool ## If `true` & [member shouldEmitBubble], text bubbles will not move together with the target entity's sprite.

#endregion


#region Dependencies
@onready var damageReceivingComponent: DamageReceivingComponent = coComponents.DamageReceivingComponent
#endregion


#region Events

func _ready() -> void:
	if not nodeToAnimate: nodeToAnimate = entity.findFirstChildOfAnyTypes([AnimatedSprite2D, Sprite2D])
	if debugMode: printDebug(str("nodeToAnimate: ", nodeToAnimate))

	damageReceivingComponent.didReceiveDamage.connect(self.onDamageReceivingComponent_didReceiveDamage)


func onDamageReceivingComponent_didReceiveDamage(_damageComponent: DamageComponent, amount: int, _attackerFactions: int) -> void:
	if amount >= 1:
		if amount > 0:		 animate(amount)
		if shouldEmitBubble: emitBubble(amount)

#endregion


#region Effects

## @experimental
@warning_ignore("unused_parameter")
func animate(damageAmount: int) -> void:
	if blinkCount > 0:
		Animations.blink(nodeToAnimate, self.blinkCount, self.blinkDuration, true) # initialVisibility, to avoid ending up invisible after the animation finishes


func emitBubble(damageAmount: int) -> void:
	# Emit the bubble from the entity so it isn't affected by effects on `nodeToAnimate`
	var bubble: TextBubble = TextBubble.create(
		str("-" if damageAmount > 0 else "", damageAmount),
		entity if not detachedBubbles else entity.get_parent(),
		self.bubbleOffset)
	if detachedBubbles: bubble.global_position = entity.to_global(self.bubbleOffset) # Apply offset separately for detached bubbles to preserve transforms etc.
	bubble.label.label_settings.font_color = Color.ORANGE

#endregion
