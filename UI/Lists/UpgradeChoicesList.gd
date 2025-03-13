## Builds and shows a list of [Upgrade] choices each represented by an [UpgradeChoiceUI].
## Attach this script to any [Container] [Control] such as a [GridContainer] or [HBoxContainer].
## NOTE: If this control is instantiated by some other script, such as a hypothetical LevelUpComponent, then [method readdAllChoices] must be called manually after setting all the properties.

class_name UpgradeChoicesList
extends Container


#region Parameters
@export var upgrades: Array[Upgrade]

## An [Entity] with an [UpgradesComponent] and a [StatsComponent] which will be used for validating and displaying each [Upgrade].
## If `null`, the first [member GameState.players] Entity will be used.
@export var targetEntity: Entity:
	get:
		if not targetEntity: targetEntity = player
		return targetEntity

## If `false` this UI will not automatically install upgrades into the [UpgradesComponent].
## So another script such as the [UpgradeChoiceUI] buttons or a manual Signal connection from [signal didChooseUpgrade] to [method UpgradesComponent.addOrLevelUpUpgrade] must be made.
## Supersedes [member UpgradeChoiceUI.shouldInstallUpgrades]
@export var shouldInstallUpgrades: bool = true

@export var debugMode: bool = false
#endregion


#region State
var lastUpgradeChosen: Upgrade
#endregion


#region Signals
signal didChooseUpgrade(upgrade: Upgrade)
#endregion


#region Dependencies

const choiceUIScene: PackedScene = preload("res://UI/Views/UpgradeChoiceUI.tscn") # TBD: load or preload?

var targetUpgradesComponent: UpgradesComponent:
	get:
		if not targetUpgradesComponent and targetEntity: targetUpgradesComponent = targetEntity.getComponent(UpgradesComponent)
		return targetUpgradesComponent

var targetStatsComponent: StatsComponent:
	get:
		if not targetStatsComponent and targetEntity: targetStatsComponent = targetEntity.getComponent(StatsComponent)
		return targetStatsComponent

var player: PlayerEntity:
	get: return GameState.getPlayer(0)

#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not targetEntity:
		# targetEntity = player # Assigned automatically by getter
		Debug.printWarning("Missing targetEntity", self)

	if targetUpgradesComponent: readdAllChoices()
	else: Debug.printWarning("Missing targetUpgradesComponent", self)


## Removes all children and adds all choices again.
func readdAllChoices() -> void:
	Tools.removeAllChildren(self)
	for upgrade in upgrades:
		createChoiceUI(upgrade)


func createChoiceUI(upgrade: Upgrade) -> Control:
	var newChoiceUI: UpgradeChoiceUI = choiceUIScene.instantiate()
	newChoiceUI.debugMode  = self.debugMode

	newChoiceUI.targetEntity = self.targetEntity
	newChoiceUI.upgrade = upgrade
	newChoiceUI.shouldInstallUpgrades = not self.shouldInstallUpgrades # Who should install the Upgrades?

	Tools.addChildAndSetOwner(newChoiceUI, self)

	newChoiceUI.updateUI() # TBD: Update before adding or after?
	newChoiceUI.didChooseUpgrade.connect(self.onChoiceUI_didChooseUpgrade)

	return newChoiceUI


func onChoiceUI_didChooseUpgrade(upgrade: Upgrade) -> void:
	if debugMode: Debug.printDebug(str("onChoiceUI_didChooseUpgrade() ", upgrade.logName), self)
	self.lastUpgradeChosen = upgrade
	self.didChooseUpgrade.emit(upgrade)
	if self.shouldInstallUpgrades: targetUpgradesComponent.addOrLevelUpUpgrade(upgrade)
