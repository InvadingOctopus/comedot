## A subclass of [InteractionComponent] that contains a [Stat] which is "consumed" with each interaction, limiting the number of interactions. 
## May be used for objects such as trees or rocks that may be "mined" by the player,
## where the [member payload] may be a [NodePayload] that produces another Entity with a [CollectibleStatComponent] for the player to collect game-specific resources.
## NOTE: To edit the [CooldownTimer], enable "Editable Children"

class_name MineableComponent
extends InteractionWithCooldownComponent


#region Parameters

## The number of times that this Component may be interacted with.
## Represents the [Stat] which will be "mined" from this Component, such as "Wood" from a "TreeEntity" or "Stone" from a "RockEntity".
## The [member Stat.value] is reduced by a random "cost" between [member minimumContentDeduction] and [member maximumContentDeduction] on each interaction.
## When the cost is greater than the [member Stat.value], interaction is not allowed.
## NOTE: This is not the [Stat] that will be "produced" by this Component's [Payload]; it's only the count of times this Component may be interacted with. See [member collectibleValue].
## NOTE: The value is CHECKED BEFORE executing [member payload], but deducted ONLY IF the [member payload] returns a successful result.
@export var contents: Stat

@export_range(0, 100, 1, "or_greater") var minimumContentDeduction: int = 1 ## The lower bound (inclusive) of the random amount to deduct from [member contents] whenever the object is mined. Affects [member collectibleValue].
@export_range(1, 100, 1, "or_greater") var maximumContentDeduction: int = 1 ## The upper bound (inclusive) of the random amount to deduct from [member contents] whenever the object is mined. Affects [member collectibleValue].

## If `true`, then a random cost between [member minimumContentDeduction] and [member maximumContentDeduction] which is higher than the [member Stat.value] of [member contents] will still allow the "mining" interaction to succeed,
## and the [contents] would be 0.
## NOTE: [member collectibleValue] will be set to the amount actually REMAINING in [member contents], NOT the randomized cost.
@export var allowCostHigherThanContents:   bool = true

## If `true`, then the parent [Entity] is removed when [member contents] reaches <= 0.
@export var shouldRemoveEntityOnDepletion: bool = true

#endregion


#region State
## The value of the [CollectibleStatComponent] in the [Entity] created by the [payload], if it is a [NodePayload].
## Equal to the cost that was deducted from [member contents], which will be between [member minimumContentDeduction] and [member maximumContentDeduction].
@export_storage var collectibleValueToSpawn: int

## A temporary wrapper to use common "payment" validation and logic from [StatDependentResourceBase]
var spawnCost: StatCost
#endregion


#region Signals
signal didMine(interactorEntity: Entity, payloadResult: Variant, minedValue: int)
signal willRemoveEntity
#endregion


func _ready() -> void:
	super._ready()

	if contents:
		if debugMode: printDebug(str("_ready() contents: ", contents.logName))
		self.spawnCost			= StatCost.new()
		self.spawnCost.costStat	= self.contents
		self.randomizeSpawnCost() # Sets spawnCost.cost
	else:
		printWarning("No contents Stat provided")

	# UNUSED: Signals set in .tscn Scene
	# Tools.connectSignal(self.willPerformInteraction, self.onWillPerformInteraction)
	# Tools.connectSignal(self.didPerformInteraction,  self.onDidPerformInteraction)


## @experimental
func createMineablePayload() -> NodePayload:
	var mineablePayload: NodePayload = NodePayload.new()
	# TODO:
	return mineablePayload


#region Validation

func checkInteractionConditions(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	if debugMode: printDebug(str("checkInteractionConditions() interactorEntity: ", interactorEntity, "interactionControlComponent: ", interactionControlComponent))
	
	# Make sure we still have some stuff left to mine!
	# and also check the superclass' conditions
	if not self.contents or self.contents.value < 1 \
	or not super.checkInteractionConditions(interactorEntity, interactionControlComponent):
		return false

	# Get the random amount of stuff to mine this turn
	self.randomizeSpawnCost()
	# See if this component has enough gold/wood/etc. to provide a collectible equal to the randomized "cost"
	return self.spawnCost.validateOfferedStat(self.contents)


#endregion


#region Mining

func randomizeSpawnCost() -> int:
	var randomValue: int = randi_range(minimumContentDeduction, maximumContentDeduction)
	
	# If the randomized depletion is greater than our contents,
	# the spawned collectible's value should be equal to our last remaining contents.
	# Example: 3 Gold chosen but only 2 Gold remaining = Spawn a collectible with 2 Gold
	if (self.contents.value - randomValue) < 0 and self.allowCostHigherThanContents:
		randomValue = self.contents.value
	
	self.spawnCost.cost = randomValue
	if debugMode: printDebug(str("randomizeValue() spawnCost.cost: ", spawnCost.cost, ", allowCostHigherThanContents: ", allowCostHigherThanContents))
	return randomValue


func deductSpawnCost() -> bool:
	# TBD: Allow deduction even if not isEnabled?
	# in case a successful Payload may have disabled this MineableComponent for whatever reason?
	if not isEnabled or self.contents.value < 1: return false

	if debugMode: printDebug(str("deductCost() contents: ", self.contents.value, " - ", spawnCost.cost))

	if  self.contents.value >= spawnCost.cost:
		var contentsChange: int = spawnCost.deductCostFromStat(self.contents)
		# Remember the value to add later to CollectibleStatComponent of the Entity created by the `payload`
		self.collectibleValueToSpawn = -contentsChange # IMPORTANT: contentsChange will be NEGATIVE so INVERT it to add a POSITIVE collectible 
		return true	

	# If the cost was greater than our contents, the collectible's value should be equal to our last remaining contents.
	elif self.contents.value < spawnCost.cost and allowCostHigherThanContents:
		self.spawnCost.cost  = self.contents.value
		self.collectibleValueToSpawn = self.contents.value
		self.contents.value  = 0
		if debugMode: printDebug(str("allowCostHigherThanContents collectibleValue: ", spawnCost.cost))
		return true
	# else:
	return false


func onWillPerformInteraction(interactorEntity: Entity) -> void:
	# TBD: PERFORMANCE: Validate again just in case?
	if (self.contents.value - self.spawnCost.cost) < 0:
		printWarning(str("onWillPerformInteraction() interactorEntity: ", interactorEntity, " • contents: ", self.contents.value, " < spawnCost.cost: ", spawnCost.cost))


func onDidPerformInteraction(interactorEntity: Entity, result: Variant) -> void:
	# NOTE: DO NOT check isEnabled here,
	# in case a successful Payload may have disabled this MineableComponent for whatever reason
	if debugMode:
		printDebug(str("onDidPerformInteraction() interactorEntity: ", interactorEntity, ", result: ", result, ", collectibleValueToSpawn: ", collectibleValueToSpawn))
		if not isEnabled: printWarning("not isEnabled! deductSpawnCost() will fail • Ignore if intended by Payload")

	# NOTE: The `result` of the NodePayload will be the entity representing a collectible item, such as a gold nugget chipped off of a gold vein.
	if not Tools.checkResult(result):
		if debugMode: printWarning(str("onDidPerformInteraction() payload result failure: ", result))
		return

	# NOTE: DESIGN: Deduct only if the Payload is successful,
	# EVEN IF the result is NOT an Entity with a CollectibleStatComponent!
	# So that the MineableComponent may be used for other effects.

	# Reduce our contents before "moving" them into the Collectible (e.g. gold nugget or wood logs etc.)
	if not self.deductSpawnCost():
		printWarning(str("onWillPerformInteraction() interactorEntity: ", interactorEntity, " • Could not deduct spawnCost.cost: ", spawnCost.cost, " from ", self.contents.logName, " (value after deduction)"))
		return

	if result is Entity:
		var collectibleStatComponent: CollectibleStatComponent = result.getComponent(CollectibleStatComponent)

		if collectibleStatComponent:
			# TBD: Apply `collectibleValue` even if 0?
			collectibleStatComponent.statModifierMinimum = self.collectibleValueToSpawn
			collectibleStatComponent.statModifierMaximum = self.collectibleValueToSpawn
			self.collectibleValueToSpawn = 0 # Reset the value to avoid subsequent reuse
		else:
			printDebug(str("onWillPerformInteraction(): Entity created by Payload missing CollectibleStatComponent: ", result.logFullName))
	else:
		printDebug("onWillPerformInteraction(): Payload result is not an Entity")

	self.didMine.emit(interactorEntity, result, collectibleValueToSpawn) # NOTE: Emit after deduction, whether there was a CollectibleStatComponent or not

	if shouldRemoveEntityOnDepletion and contents.value <= 0 and contents.previousValue > 0:
		printDebug("onWillPerformInteraction(): shouldRemoveEntityOnDepletion")
		self.willRemoveEntity.emit()
		self.requestDeletionOfEntity()

#endregion
