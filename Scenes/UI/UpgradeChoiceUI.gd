## A [Control] representing an [Upgrade] for the player to choose.

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


func connectSignals() -> void:
	# TBD: Disconnect signals if Upgrade is null'ed?
	if not upgrade: return
	upgrade.didLevelUp.connect(self.updateUI)
	upgrade.didLevelDown.connect(self.updateUI)
	upgrade.didAcquire.connect(self.updateUI)
	upgrade.didDiscard.connect(self.updateUI)


func updateUI(_entity: Entity = self.targetEntity) -> void: # The Entity argument is needed to match the Upgrade signals signatures.
	updateCostUI()
	updateButton()


## Shows the cost for the Upgrade's current level.
func updateCostUI() -> void:
	# NOTE: DESIGN: Only show the CURRENT level's cost to simplify development. For the next level, use a separate button.
	costStatLabel.text = upgrade.costStat.displayName
	costAmountLabel.text = str(upgrade.getCostForUpgradesComponent(targetUpgradesComponent))


func updateButton() -> void:
	# Write the level if there are any levels, or infinite levels are allowed .
	if upgrade.maxLevel > 0 or upgrade.shouldAllowInfiniteLevels: upgradeButton.text = str(upgrade.displayName, " L", upgrade.level)
	else: upgradeButton.text = upgrade.displayName

	upgradeButton.disabled = not self.validateChoice()


func validateChoice() -> bool:
	return upgrade.validateEntityEligibility(targetEntity) and not upgrade.isMaxLevel # TODO: Allow installation at level 0


func onUpgradeButton_pressed() -> void:
	if shouldShowDebugInfo: Debug.printDebug(str("onUpgradeButton_pressed() ", upgrade.logName), str(self))
	self.didChooseUpgrade.emit(self.upgrade)
