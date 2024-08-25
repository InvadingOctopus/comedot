## A [Control] representing an [Upgrade] for the player to choose.
## If the Upgrade is already "installed" in an Entity's [UpgradesComponent], then the UI will represent a Level Up for the Upgrade, if available.

class_name UpgradeChoiceUI
extends Control


#region Parameters

@export var upgrade: Upgrade:
	set(newValue):
		if newValue != upgrade:
			upgrade = newValue
			connectSignals()

## The [Entity] which will be receiving the [Upgrade].
## If `null`, the first [member GameState.players] Entity will be used.
@export var targetEntity: Entity

@export var shouldShowDebugInfo: bool = false

#endregion


#region State

@onready var costAmountLabel:	Label  = %CostAmountLabel
@onready var costStatLabel:		Label  = %CostStatLabel
@onready var upgradeButton:		Button = %UpgradeButton

## The [UpgradesComponent] to check for the Upgrade's [member Upgrade.requiredUpgrades] and [member Upgrade.mutuallyExclusiveUpgrades].
var targetUpgradesComponent: UpgradesComponent:
	get:
		if not targetUpgradesComponent: targetUpgradesComponent = targetEntity.getComponent(UpgradesComponent)
		return targetUpgradesComponent

## The [StatsComponent] to check for the Upgrade's [member Upgrade.costStat].
var targetStatsComponent: StatsComponent:
	get:
		if not targetStatsComponent: targetStatsComponent = targetEntity.getComponent(StatsComponent)
		return targetStatsComponent

var isUpgradeInstalled: bool:
	get: return targetUpgradesComponent.getUpgrade(upgrade.name) != null # TBD: Match just the name or the exact resource instance?

#endregion


#region Signals
signal didChooseUpgrade(upgrade: Upgrade)
#endregion


#region Dependencies
var player: PlayerEntity:
	get: return GameState.players.front()
#endregion


func _ready() -> void:
	if not targetEntity:
		targetEntity = player
		if not targetEntity: Debug.printWarning("Missing targetEntity", str(self))


func updateUI() -> void:
	updateCostUI()
	updateButton()


## Shows the cost for the Upgrade's current level.
func updateCostUI() -> void:
	# NOTE: DESIGN: Only show the CURRENT level's cost to simplify development. For the next level, use a separate button.
	costStatLabel.text = upgrade.costStat.displayName
	costAmountLabel.text = str(upgrade.getCost(self.getLevelToPurchase()))


func updateButton() -> void:
	# Write the level if there are any levels, or infinite levels are allowed .
	if upgrade.maxLevel > 0 or upgrade.shouldAllowInfiniteLevels: upgradeButton.text = str(upgrade.displayName, " L", self.getLevelToPurchase())
	else: upgradeButton.text = upgrade.displayName

	upgradeButton.disabled = not self.validateChoice()


## If the Upgrade is not in the [member targetUpgradesComponent], the Upgrade's current [member Upgrade.level] is returned.
## If the Upgrade is already installed in the component, the next level is returned.
## If the Upgrade is already at its [member Upgrade.maxLevel], its current level is returned.
func getLevelToPurchase() -> int:
	if not isUpgradeInstalled: return upgrade.level
	else: return upgrade.getNextLevel()


func validateChoice() -> bool:
	return upgrade.validateEntityEligibility(targetEntity) \
	and (not upgrade.isMaxLevel or not isUpgradeInstalled)  # Allow installation at level == maxLevel == 0 if the Upgrade is not already in the UpgradesComponent.
	# TBD: Compare only name or the Upgrade instance itself?


#region Signal Handlers

func connectSignals() -> void:
	# TBD: Disconnect signals if Upgrade is null'ed?
	if not upgrade: return
	upgrade.didLevelUp.connect(self.updateUI)
	upgrade.didLevelDown.connect(self.updateUI)

	# NOTE: Connect to the [UpgradesComponent] for these signals, because the component adds the Upgrade AFTER the Upgrade emits its signal!
	targetUpgradesComponent.didAcquire.connect(self.onUpgradesComponent_didChange) 
	targetUpgradesComponent.didDiscard.connect(self.onUpgradesComponent_didChange)

	var paymentStat: Stat = upgrade.findPaymentStatInStatsComponent(targetStatsComponent)
	if paymentStat: paymentStat.changed.connect(self.updateUI)


func onUpgradesComponent_didChange(upgradeInComponent: Upgrade) -> void:
	# If the UpgradesComponent acquired or discarded any upgrade,
	# update the UI if it was the Upgrade we were monitoring,
	# or if our Upgrade has any required/conflicting Upgrades.
	if upgradeInComponent == self.upgrade \
	or not self.upgrade.requiredUpgrades.is_empty() \
	or not self.upgrade.mutuallyExclusiveUpgrades.is_empty():
		self.updateUI()


func onUpgradeButton_pressed() -> void:
	if shouldShowDebugInfo: Debug.printDebug(str("onUpgradeButton_pressed() ", upgrade.logName), str(self))
	self.didChooseUpgrade.emit(self.upgrade)

#endregion

