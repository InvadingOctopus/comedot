## A [Control] representing an [Upgrade] for the player to choose.

class_name UpgradeChoiceUI
extends Control


#region Parameters

@export var upgrade: Upgrade

## The [UpgradesComponent] to check for each Upgrade's [member Upgrade.requiredUpgrades] and [member Upgrade.mutuallyExclusiveUpgrades].
## If `null`, the [member GameState.players] Entity will be searched.
@export var targetUpgradesComponent: UpgradesComponent

## The [StatsComponent] to check for each Upgrade's [member Upgrade.costStat].
## If `null`, the [member GameState.players] Entity will be searched.
@export var targetStatsComponent: StatsComponent

@export var shouldShowDebugInfo: bool = false

#endregion


#region State
@onready var costAmountLabel:	Label  = %CostAmountLabel
@onready var costStatLabel:		Label  = %CostStatLabel
@onready var upgradeButton:		Button = %UpgradeButton
#endregion


#region Signals
signal didChooseUpgrade(upgrade: Upgrade)
#endregion


#region Dependencies
var player: PlayerEntity:
	get: return GameState.players.front()
#endregion


func _ready() -> void:
	if not targetUpgradesComponent:
		targetUpgradesComponent = player.upgradesComponent
		if not targetUpgradesComponent: Debug.printWarning("Missing targetUpgradesComponent", str(self))

	if not targetStatsComponent:
		targetStatsComponent = player.statsComponent
		if not targetStatsComponent: Debug.printWarning("Missing targetStatsComponent", str(self))


func updateUI() -> void:
	updateCostUI()
	updateButton()


## Shows the cost for the Upgrade's current level.
func updateCostUI() -> void:
	# NOTE: DESIGN: Only show the CURRENT level's cost to simplify development. For the next level, use a separate button.
	costStatLabel.text = upgrade.costStat.displayName
	costAmountLabel.text = str(upgrade.getCost())


func updateButton() -> void:
	# Cost is quicker to check first :)
	upgradeButton.text = upgrade.displayName
	upgradeButton.disabled = not self.validateCost() and not self.validateRequirements()


func validateCost() -> bool:
	# If there the Upgrade has no cost, it's valid!
	if upgrade.getCost() <= 0: return true

	# Do we have the required Stat and does its value meet the Upgrade's cost?
	if targetStatsComponent:
		var stat: Stat = targetStatsComponent.getStat(upgrade.costStat.name)
		if stat and stat.value >= upgrade.getCost():
			return true
	# else
	return false


func validateRequirements() -> bool:
	return upgrade.validateUpgradesComponent(targetUpgradesComponent)


func onUpgradeButton_pressed() -> void:
	if shouldShowDebugInfo: Debug.printDebug(str("onChoiceUI_didChooseUpgrade() ", upgrade.logName), str(self))
	self.didChooseUpgrade.emit(self.upgrade)
