## A subclass of [CollectibleComponent] which increments or decrements a [Stat] when collected.

class_name StatCollectibleComponent
extends CollectibleComponent


#region Parameters
@export var stat: Stat

@export var statModifierMinimum: int = 1 ## The minimum amount of change, inclusive. To always apply a fixed amount, set both minimum and maximum to the same number.
@export var statModifierMaximum: int = 1 ## The maximum amount of change, inclusive. To always apply a fixed amount, set both minimum and maximum to the same number.

@export var shouldDisplayIndicator: bool = true
#endregion


func _ready() -> void:
	self.payload = CallablePayload.new()
	(self.payload as CallablePayload).payloadCallable = self.onCollectible_didCollect


## Returns a random integer between [member statModifierMinimum] and [member statModifierMaximum], inclusive.
## WARNING: Calling this function repeatedly may introduce gameplay bugs; Get a random value once and store it to a variable or property.
func getRandomModifier() -> int:
	return randi_range(statModifierMinimum, statModifierMaximum) if statModifierMinimum != statModifierMaximum else statModifierMaximum


## Returns: The randomized stat modifier value.
func onCollectible_didCollect(collectibleComponent: CollectibleComponent, collectorEntity: Entity) -> int:
	var randomizedModifier: int = getRandomModifier()

	if shouldShowDebugInfo:
		printLog(str("onCollectible_didCollect() collectibleComponent: ", collectibleComponent, ", collectorEntity: ", collectorEntity, ", randomizedModifier: ", randomizedModifier))

	stat.value += randomizedModifier

	# Create a visual indicator
	# TODO: Make it customizable

	if shouldDisplayIndicator:
		var symbol: String
		if signi(randomizedModifier) == 1:    symbol = "+"
		elif signi(randomizedModifier) == -1: symbol = "-"

		TextBubble.create(collectorEntity, str(stat.name.capitalize(), symbol, randomizedModifier))
	
	return randomizedModifier
