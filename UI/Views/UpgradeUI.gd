## A [Label] linked to an [Upgrade] which automatically updates its text when the Upgrade changes.

class_name UpgradeUI
extends Label


#region Parameters
@export var upgrade: Upgrade:
	set(newValue):
		if newValue != upgrade:
			upgrade = newValue
			connectSignals()

@export var shouldBeHiddenUntilAcquired: bool = false
#endregion


#region Dependencies
var player: PlayerEntity:
	get: return GameState.players.front()
#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = not shouldBeHiddenUntilAcquired
	if upgrade: connectSignals()
	updateLabel()


func connectSignals() -> void:
	if not upgrade: return
	Tools.reconnectSignal(upgrade.didAcquire,   self.onUpgrade_didAcquire)
	Tools.reconnectSignal(upgrade.didDiscard,   self.onUpgrade_didDiscard)
	Tools.reconnectSignal(upgrade.didLevelUp,	self.onUpgrade_didLevelChange)
	Tools.reconnectSignal(upgrade.didLevelDown, self.onUpgrade_didLevelChange)


func onUpgrade_didAcquire(_entity: Entity) -> void:
	self.label_settings.font_color = Color.GREEN_YELLOW
	updateLabel()
	if self.shouldBeHiddenUntilAcquired: self.visible = true


func onUpgrade_didDiscard(_entity: Entity) -> void:
	self.label_settings.font_color = Color.GRAY
	updateLabel()


func onUpgrade_didLevelChange() -> void:
	updateLabel()


func updateLabel() -> void:
	if not upgrade: 
		self.text = "" # TBD: Should there be some text when there is no Upgrade?
		return

	if upgrade.maxLevel > 0 or upgrade.shouldAllowInfiniteLevels:
		self.text = str(upgrade.displayName, " L", upgrade.level)
	else:
		self.text = upgrade.displayName
