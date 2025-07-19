## A subclass of [InteractionComponent] that contains a [Stat] which is "consumed" with each interaction, limiting the number of interactions. 
## May be used for objects such as trees or rocks that may be "mined" by the player,
## where the [member payload] may be a [NodePayload] that produces another Entity with a [CollectibleStatComponent] for the player to collect game-specific resources.

class_name MineableComponent
extends InteractionComponent


#region Parameters

## The number of times that this Component may be interacted with.
## Represents the [Stat] which will be "mined" from this Component, such as "Wood" from a "TreeEntity" or "Stone" from a "RockEntity".
## The [member Stat.value] is reduced by a random "cost" between [member minimumContentDeduction] and [member maximumContentDeduction] on each interaction.
## When the cost is greater than the [member Stat.value], interaction is not allowed.
## NOTE: This is not the [Stat] that will be "produced" by this Component's [Payload]; it's only the count of times this Component may be interacted with. See [member collectibleValue].
@export var contents: Stat

@export_range(0, 100, 1, "or_greater") var minimumContentDeduction: int = 1 ## The lower bound of the random amount to deduct from [member contents] whenever the object is mined. Affects [member collectibleValue].
@export_range(1, 100, 1, "or_greater") var maximumContentDeduction: int = 1 ## The upper bound of the random amount to deduct from [member contents] whenever the object is mined. Affects [member collectibleValue].

## If `true`, then a random cost between [member minimumContentDeduction] and [member maximumContentDeduction] which is higher than the [member Stat.value] of [member contents] will still allow the "mining" interaction to succeed,
## and the [contents] would be 0.
## NOTE: [member collectibleValue] will be set to the amount actually REMAINING in [member contents], NOT the randomized cost.
@export var allowCostHigherThanContents: bool = true

## If `true`, then the parent [Entity] is removed when [member contents] reaches <= 0.
@export var shouldRemoveEntityOnDepletion: bool = true

#endregion


#region State
## The value of the [CollectibleStatComponent] in the [Entity] created by the [payload], if it is a [NodePayload].
## Equal to the cost that was deducted from [member contents], which will be between [member minimumContentDeduction] and [member maximumContentDeduction].
var collectibleValue: int
#endregion


#region Signals
signal willRemoveEntity
#endregion


func _ready() -> void:
	super._ready()

	if not contents: printWarning("No contents Stat provided")
	if debugMode: printDebug(str("_ready() contents: ", contents.logName))
	self.didPerformInteraction.connect(self.onDidPerformInteraction)


## @experimental
func createMineablePayload() -> NodePayload:
	var mineablePayload: NodePayload = NodePayload.new()
	# TODO:
	return mineablePayload


func checkInteractionConditions(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	if debugMode: printDebug(str("checkInteractionConditions() interactorEntity: ", interactorEntity, "interactionControlComponent: ", interactionControlComponent))
	if not isEnabled: return false
	# TODO: Check Payload validation
	return deductCost()


func deductCost() -> bool:
	if not isEnabled: return false

	var randomCost: int = randi_range(minimumContentDeduction, maximumContentDeduction)
	if debugMode: printDebug(str("deductCost() ", self.contents.value, " - ", randomCost))

	if self.contents.value   >= randomCost:
		self.contents.value  -= randomCost
		## Remember the value to add to CollectibleStatComponent of the Entity created by the `payload`
		self.collectibleValue = randomCost
		return true	

	elif self.contents.value  < randomCost and allowCostHigherThanContents:
		## If the cost was greater than our contents, the collectible's value should be equal to our last remaining contents.
		self.collectibleValue = self.contents.value
		self.contents.value = 0
		if debugMode: printDebug(str("allowCostHigherThanContents collectibleValue: ", collectibleValue))
		return true

	else:
		return false



func onDidPerformInteraction(result: Variant) -> void:
	if not isEnabled and result: return
	if debugMode: printDebug(str("onDidPerformInteraction() result: ", result, ", collectibleValue: ", collectibleValue))
	
	# TBD: Apply collectibleValue even if 0?

	if result is Entity:
		var collectibleStatComponent: CollectibleStatComponent = result.getComponent(CollectibleStatComponent)
		if collectibleStatComponent:
			collectibleStatComponent.statModifierMinimum = self.collectibleValue
			collectibleStatComponent.statModifierMaximum = self.collectibleValue
			self.collectibleValue = 0 # Reset the value to avoid subsequent reuse
		else:
			printDebug("Entity created by Payload missing CollectibleStatComponent")
	else:
		printDebug("Result is not an Entity")

	if shouldRemoveEntityOnDepletion and contents.value <= 0 and contents.previousValue > 0:
		printDebug("shouldRemoveEntityOnDepletion")
		self.willRemoveEntity.emit()
		self.requestDeletionOfParentEntity()
