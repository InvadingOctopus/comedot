## A [Label] linked to an [Upgrade] which automatically updates its text when the Upgrade changes.

class_name UpgradeLabel
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
	connectSignals()
	updateLabel()


func connectSignals() -> void:
	Tools.reconnect(upgrade.didAcquire,   self.onUpgrade_didAcquire)
	Tools.reconnect(upgrade.didDiscard,   self.onUpgrade_didDiscard)
	Tools.reconnect(upgrade.didLevelUp,	  self.onUpgrade_didLevelChange)
	Tools.reconnect(upgrade.didLevelDown, self.onUpgrade_didLevelChange)


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
