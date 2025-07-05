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

## Denies collection if the [Stat] is at its maximum limit.
## IMPORTANT: The [CollectorComponent]'s physics [member CollisionObject2D.collision_layer] must match [CollectibleStatComponent]'s [member CollisionObject2D.collision_mask] to trigger the [signal Area2D.onAreaExited] signal and ensure correct behavior.
@export var shouldDenyIfStatMax: bool = true

@export_group("Text Bubble")

## Spawns a visual [TextBubble] saying the Stat's name and change in value that floats up from the Entity.
## NOTE: The bubble is emitted from COLLECTIBLE item, NOT the Collector Entity. To display [Stat]-related bubbles from the player entity or other characters, use [StatsVisualComponent].
@export var shouldEmitBubble:		bool = true
@export var shouldEmitBubbleIfMax:	bool = true
@export var shouldColorBubble:		bool = true
@export var shouldAppendStatName:	bool = true

#endregion


#region State
## Used to recheck collision with a [CollectorComponent] that was denied collection while [member shouldDenyIfStatMax]
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


## Prevents collection if `shouldDenyIfStatMax` and the Stat is already at its [member Stat.max].
func checkCollectionConditions(collectorEntity: Entity, collectorComponent: CollectorComponent) -> bool:
	if not super.checkCollectionConditions(collectorEntity, collectorComponent): return false
	# Is it pointless to pick up the Stat?
	if shouldDenyIfStatMax and stat.value >= stat.max:
		if debugMode: printDebug(str("shouldDenyIfStatMax: stat.value ", stat.value, " >= stat.max ", stat.max))
		previouslyDeniedCollector = collectorComponent # Remember the collector in case it is still in contact after the Stat decreases.
		if shouldEmitBubbleIfMax:
			var bubble: GameplayResourceBubble = GameplayResourceBubble.create(stat, " MAX", collectorEntity)
			bubble.modulate = Color.LIGHT_GRAY # Make it faint because a max stat isn't a particularly notable event
			Animations.blink(bubble)
		return false
	else:
		return true


## Returns: The randomized stat modifier value.
func onCollectible_didCollect(collectibleComponent: CollectibleComponent, collectorEntity: Entity) -> int:
	var randomizedModifier: int = getRandomModifier()

	if debugMode:
		printLog(str("onCollectible_didCollect() collectibleComponent: ", collectibleComponent, ", collectorEntity: ", collectorEntity.logName, ", randomizedModifier: ", randomizedModifier))

	stat.value += randomizedModifier

	# Create a visual indicator. # NOTE: Spawn it on the entity's parent because the entity will be destroyed after collection. To emit bubbles from the COLLECTOR, use [StatsVisualComponent]
	# TODO: Make it customizable
	if shouldEmitBubble:
		GameplayResourceBubble.createForStatChange(stat, parentEntity.get_parent(), Vector2(parentEntity.position.x, parentEntity.position.y - 16), shouldAppendStatName, shouldColorBubble) \
			.z_index = 100 # FIXED: Need to restore this for some reason, otherwise the bubble may be obscured by even the lowest Z index nodes.

	return randomizedModifier


#region Rechecks

func connectSignals() -> void:
	Tools.connectSignal(stat.changed, self.onstat_changed)


func onstat_changed() -> void:
	# Monitor changes to allow collection when the Stat decreases from its max WHILE still in collision contact; otherwise we would have to "walk out" and collide again to pick it up.
	if shouldDenyIfStatMax and previouslyDeniedCollector and stat.value < stat.max:
		# NOTE: PERFORMANCE: No need to recheck collisions, because previouslyDeniedCollector is removed in onAreaExited()
		previouslyDeniedCollector.handleCollection(self) # This is a little jank, controlling the Collector from the Collectible :')


## Removes the [member previouslyDeniedCollector] to avoid re-collection if the [Stat] goes below its maximum value while the [CollectorComponent] is outside contact.
## IMPORTANT: The [CollectorComponent]'s physics [member CollisionObject2D.collision_layer] must match [CollectibleStatComponent]'s [member CollisionObject2D.collision_mask] to trigger the [signal Area2D.onAreaExited] signal and ensure correct behavior.
func onAreaExited(area: Area2D) -> void:
	# PERFORMANCE: Remove the `previouslyDeniedCollector` on leaving contact, so we don't have to recheck collisions each time the Stat decreases.
	# NOTE: Removals should NOT depend on `isEnabled`
	if not previouslyDeniedCollector: return
	
	var collectorComponent: CollectorComponent = area.get_node(^".") as CollectorComponent # HACK: Find better way to cast?
	if debugMode: printDebug(str("onAreaExited(): ", area, ", CollectorComponent: ", collectorComponent, ", previouslyDeniedCollector: ", previouslyDeniedCollector))
	if previouslyDeniedCollector == collectorComponent: previouslyDeniedCollector = null

#endregion
