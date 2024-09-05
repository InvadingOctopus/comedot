## A [Container] [Control] which builds and shows a list of [Upgrade] choices each represented by an [UpgradeChoiceUI].

class_name UpgradesList
extends Container


#region Parameters
@export var upgrades: Array[Upgrade]

## An [Entity] with an [UpgradesComponent] and a [StatsComponent] which will be used for validating and displaying each [Upgrade].
## If `null`, the first [member GameState.players] Entity will be used.
@export var targetEntity: Entity

@export var shouldShowDebugInfo: bool = false
#endregion


#region State

var lastUpgradeChosen: Upgrade

var targetUpgradesComponent: UpgradesComponent:
	get:
		if not targetUpgradesComponent: targetUpgradesComponent = targetEntity.getComponent(UpgradesComponent)
		return targetUpgradesComponent

var targetStatsComponent: StatsComponent:
	get:
		if not targetStatsComponent: targetStatsComponent = targetEntity.getComponent(StatsComponent)
		return targetStatsComponent

#endregion


#region Signals
signal didChooseUpgrade(upgrade: Upgrade)
#endregion


#region Dependencies
const choiceUIScene: PackedScene = preload("res://UI/Buttons/UpgradeChoiceUI.tscn") # TBD: load or preload?

var player: PlayerEntity:
	get: return GameState.players.front()
#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not targetEntity:
		targetEntity = player
		if not targetEntity: Debug.printWarning("Missing targetEntity", str(self))

	readdAllChoices()


## Removes all children and adds all choices again.
func readdAllChoices() -> void:
	Tools.removeAllChildren(self)
	for upgrade in upgrades:
		createChoiceUI(upgrade)


func createChoiceUI(upgrade: Upgrade) -> Control:
	var newChoiceUI: UpgradeChoiceUI = choiceUIScene.instantiate()
	newChoiceUI.shouldShowDebugInfo  = self.shouldShowDebugInfo

	newChoiceUI.targetEntity = self.targetEntity
	newChoiceUI.upgrade = upgrade

	Tools.addChildAndSetOwner(newChoiceUI, self)

	newChoiceUI.updateUI() # TBD: Update before adding or after?
	newChoiceUI.didChooseUpgrade.connect(self.onChoiceUI_didChooseUpgrade)

	return newChoiceUI


func onChoiceUI_didChooseUpgrade(upgrade: Upgrade) -> void:
	if shouldShowDebugInfo: Debug.printDebug(str("onChoiceUI_didChooseUpgrade() ", upgrade.logName), str(self))
	self.lastUpgradeChosen = upgrade
	self.didChooseUpgrade.emit(upgrade)
