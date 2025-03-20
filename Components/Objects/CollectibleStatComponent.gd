## A subclass of [CollectibleComponent] which increments or decrements a [Stat] when collected.

class_name CollectibleStatComponent
extends CollectibleComponent

# TBD: Inherit CollectibleComponent from AreaCollisionComponent to make rechecks easier?
# TBD: Use StatModifierPayload?

#region Parameters

@export var stat: Stat:
	set(newValue):
		if newValue != stat:
			stat = newValue
			if stat: connectSignals()


@export var statModifierMinimum: int = 1 ## The minimum amount of change, inclusive. To always apply a fixed amount, set both minimum and maximum to the same number.
@export var statModifierMaximum: int = 1 ## The maximum amount of change, inclusive. To always apply a fixed amount, set both minimum and maximum to the same number.

@export var preventCollectionIfStatIsMax: bool = true # TBD: Better name? :')

@export var shouldDisplayIndicator: bool = true

#endregion


#region State
## Used to recheck collision with a [CollectorComponent] that was denied collection while [member preventCollectionIfStatIsMax]
## NOTE: This will recheck only ONE collector: the most recent one!
@export_storage var previouslyDeniedCollector: CollectorComponent
#endregion


func _ready() -> void:
	# Override the Payload
	self.payload = CallablePayload.new()
	(self.payload as CallablePayload).payloadCallable = self.onCollectible_didCollect
	if stat: connectSignals()


## Returns a random integer between [member statModifierMinimum] and [member statModifierMaximum], inclusive.
## WARNING: Calling this function repeatedly may introduce gameplay bugs; Get a random value once and store it to a variable or property.
func getRandomModifier() -> int:
	return randi_range(statModifierMinimum, statModifierMaximum) if statModifierMinimum != statModifierMaximum else statModifierMaximum


## Prevents collection if `preventCollectionIfStatIsMax` and the Stat is already at its [member Stat.max].
func checkCollectionConditions(collectorEntity: Entity, collectorComponent: CollectorComponent) -> bool:
	if not super.checkCollectionConditions(collectorEntity, collectorComponent): return false
	# Is it pointless to pick up the Stat?
	if preventCollectionIfStatIsMax and stat.value >= stat.max: 
		if debugMode: printDebug(str("preventCollectionIfStatIsMax: stat.value ", stat.value, " >= stat.max ", stat.max))
		previouslyDeniedCollector = collectorComponent # Remember the collector in case it is still in contact after the Stat decreases.
		return false
	else:
		return true


## Returns: The randomized stat modifier value.
func onCollectible_didCollect(collectibleComponent: CollectibleComponent, collectorEntity: Entity) -> int:
	var randomizedModifier: int = getRandomModifier()

	if debugMode:
		printLog(str("onCollectible_didCollect() collectibleComponent: ", collectibleComponent, ", collectorEntity: ", collectorEntity.logName, ", randomizedModifier: ", randomizedModifier))

	stat.value += randomizedModifier

	# Create a visual indicator
	# TODO: Make it customizable

	if shouldDisplayIndicator:
		var symbol: String
		if signi(randomizedModifier) == 1:    symbol = "+"
		elif signi(randomizedModifier) == -1: symbol = "-"

		TextBubble.create(str(stat.displayName.capitalize(), symbol, randomizedModifier), collectorEntity)
	
	return randomizedModifier


#region Rechecks

func connectSignals() -> void:
	Tools.connectSignal(stat.changed, self.onstat_changed)


func onstat_changed() -> void:
	# Monitor changes to allow collection when the Stat decreases from its max WHILE still in collision contact; otherwise we would have to "walk out" and collide again to pick it up.
	if preventCollectionIfStatIsMax and previouslyDeniedCollector and stat.value < stat.max:
		# NOTE: PERFORMANCE: No need to recheck collisions, because previouslyDeniedCollector is removed in onAreaExited()
		previouslyDeniedCollector.handleCollection(self) # This is a little jank, controlling the Collector from the Collectible :')


func onAreaExited(area: Area2D) -> void:
	# PERFORMANCE: Remove the `previouslyDeniedCollector` on leaving contact, so we don't have to recheck collisions each time the Stat decreases.
	# NOTE: Removals should NOT depend on `isEnabled`
	if not previouslyDeniedCollector: return

	var collectorComponent: CollectorComponent = area.get_node(^".") as CollectorComponent # HACK: Find better way to cast self?
	if not collectorComponent: return

	if debugMode: printDebug(str("onAreaExited() CollectorComponent: ", collectorComponent, ", previouslyDeniedCollector: ", previouslyDeniedCollector))
	if previouslyDeniedCollector == collectorComponent: previouslyDeniedCollector = null

#endregion

