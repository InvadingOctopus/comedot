## Displays visual effects and indicators when a [HealthComponent]'s health [Stat] value changes, negatively or positively (damage or healing).
## NOTE: The effects may occur even when the Stat is modified elsewhere WITHOUT any damage happening to this component's parent entity,
## for example if the same "Health" Stat is shared between multiple Entities!
## TIP: Use [DamageVisualComponent] to show effects only on incoming DAMAGE attempts, i.e. on [signal DamageReceivingComponent.didReceiveDamage]
## ALERT: [HealthVisualComponent] is not triggered if a [ShieldedHealthComponent] absorbs damage.
## Requirements: [HealthComponent]

class_name HealthVisualComponent
extends Component


#region Parameters

## The node to display effects on, such as an [AnimatedSprite2D].
## If omitted, the first [AnimatedSprite2D] or [Sprite2D] sibling is used, if any, otherwise the parent entity is used.
@export var nodeToAnimate:	CanvasItem

## If `true`, adds a red tint to the entity, increasing in intensity as the health decreases.
## @experimental
@export var shouldTint:		bool:
	set(newValue):
		if newValue != shouldTint:
			shouldTint = newValue
			if self.is_node_ready(): # Avoid crash before _ready()
				if shouldTint and healthComponent:
					modulateBeforeTint = nodeToAnimate.modulate
					updateTint()
				else:
					if tintTween: tintTween.kill() # Remove any ongoing anymations
					nodeToAnimate.modulate = modulateBeforeTint

## Shows a [GameplayResourceBubble] representing the current health value or the difference.
## The bubble is set as a child node of the entity, to avoid being affected by the effects on [nodeToAnimate].
@export var shouldEmitBubble:	bool	= true
@export var bubbleColorPositive: Color	= Color.GREEN
@export var bubbleColorNegative: Color	= Color.RED
@export var bubbleOffset:		Vector2	= Vector2(0, -16) ## The position relative to the entity from which bubbles are bobbled.
@export var detachedBubbles:	bool ## If `true` & [member shouldEmitBubble], text bubbles will not move together with the target entity's sprite.

## If `true` (default) the [GameplayResourceBubble] shows the REMAINING health instead of the DIFFERENCE.
## WARNING: If `false` then this will show the changes in the health [Stat], which may be the same as the damage amount shown by [DamageVisualComponent], causing duplicate bubbles.
@export var shouldShowRemainingHealth: bool = true

#endregion


#region State
var tintTween:			Tween
var modulateBeforeTint:	Color
#endregion


#region Dependencies
var healthComponent: HealthComponent: ## Includes [ShieldedHealthComponent] etc.
	get:
		if not healthComponent: healthComponent = getCoComponent(HealthComponent, true) # findSubclasses
		return healthComponent
#endregion


#region Events

func _ready() -> void:
	if not nodeToAnimate: nodeToAnimate = entity.findFirstChildOfAnyTypes([AnimatedSprite2D, Sprite2D])
	modulateBeforeTint =  nodeToAnimate.modulate
	if debugMode: printDebug(str("nodeToAnimate: ", nodeToAnimate, ", modulateBeforeTint: ", modulateBeforeTint))

	healthComponent.healthDidDecrease.connect(self.onHealthComponent_healthChanged)
	healthComponent.healthDidIncrease.connect(self.onHealthComponent_healthChanged)
	if shouldTint: updateTint()


func onHealthComponent_healthChanged(difference: int) -> void:
	if shouldEmitBubble:	emitBubble(difference)
	if shouldTint:			updateTint() # Always update tint in case we just got healed.

#endregion


#region Effects

## @experimental
func updateTint()-> void:
	if self.shouldTint and healthComponent:
		if tintTween: tintTween.kill()
		if debugMode: Debug.printVariables([healthComponent.health.logName, modulateBeforeTint.lerp(Color(Color.RED, modulateBeforeTint.a), 1.0 - healthComponent.health.percentNormalized)])
		tintTween = Animations.tweenProperty(nodeToAnimate, ^"modulate", modulateBeforeTint.lerp(Color(Color.RED, modulateBeforeTint.a), 1.0 - healthComponent.health.percentNormalized), 0.1)


func emitBubble(difference: int) -> void:
	# Emit the bubble from the entity so it isn't affected by effects on `nodeToAnimate`
	# not appendDisplayName, not colorBubble
	var bubble: GameplayResourceBubble
	if shouldShowRemainingHealth:
		bubble = GameplayResourceBubble.createForStat(
			healthComponent.health,
			entity if not detachedBubbles else entity.get_parent(),
			self.bubbleOffset,
			false, false)
	else:
		bubble = GameplayResourceBubble.createForStatChange(
			healthComponent.health,
			entity if not detachedBubbles else entity.get_parent(),
			self.bubbleOffset,
			false, false)
	if detachedBubbles: bubble.global_position = entity.to_global(self.bubbleOffset) # Apply offset separately for detached bubbles to preserve transforms etc.
	bubble.ui.label.label_settings.font_color  = self.bubbleColorPositive if difference > 0 else self.bubbleColorNegative

#endregion
