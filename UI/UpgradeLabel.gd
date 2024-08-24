## A [Label] linked to an [Upgrade] which automatically updates its text when the Upgrade changes.

class_name UpgradeLabel
extends Label


#region Parameters
@export var upgrade: Upgrade:
	set(newValue):
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
	connectSignals()


func connectSignals() -> void:
	upgrade.didAcquire.connect(self.onUpgrade_didAcquire)
	upgrade.didDiscard.connect(self.onUpgrade_didDiscard)
	upgrade.didLevelUp.connect(self.onUpgrade_didLevelChange)
	upgrade.didLevelDown.connect(self.onUpgrade_didLevelChange)


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
	if upgrade.maxLevel > 0 or upgrade.shouldAllowInfiniteLevels:
		self.text = str(upgrade.displayName, " L", upgrade.level)
	else:
		self.text = upgrade.displayName
