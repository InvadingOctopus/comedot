## A label & icon linked to an [Upgrade] which automatically updates its text when the Upgrade changes.

@warning_ignore("missing_tool")
class_name UpgradeUI
extends GameplayResourceUI


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
	super._ready() # TBD: First or last?
	if upgrade: connectSignals()
	self.visible = not shouldBeHiddenUntilAcquired
	updateUI()


func connectSignals() -> void:
	if not upgrade: return
	Tools.connectSignal(upgrade.didAcquire,   self.onUpgrade_didAcquire)
	Tools.connectSignal(upgrade.didDiscard,   self.onUpgrade_didDiscard)
	Tools.connectSignal(upgrade.didLevelUp,	self.onUpgrade_didLevelChange)
	Tools.connectSignal(upgrade.didLevelDown, self.onUpgrade_didLevelChange)


func onUpgrade_didAcquire(_entity: Entity) -> void:
	label.label_settings.font_color = Color.GREEN_YELLOW
	icon.modulate = Color.WHITE
	updateUI()
	if self.shouldBeHiddenUntilAcquired: self.visible = true


func onUpgrade_didDiscard(_entity: Entity) -> void:
	label.label_settings.font_color = Color.GRAY
	updateUI()


func updateUI(animate: bool = self.shouldAnimate) -> void:
	super.updateUI(animate)
	if self.shouldBeHiddenUntilAcquired:
		self.visible = upgrade.isAcquired
	else:
		self.visible = true
		self.modulate = Color.WHITE if upgrade.isAcquired else Color(1.0, 1.0, 1.0, 0.5)


func onUpgrade_didLevelChange() -> void:
	updateText()


func updateIcon(_animate: bool = self.shouldAnimate) -> void:
	icon.texture = upgrade.icon


func updateText(_animate: bool = self.shouldAnimate) -> void:
	if not upgrade:
		label.text = "" # TBD: Should there be some text when there is no Upgrade?
		return

	if upgrade.maxLevel > 0 or upgrade.shouldAllowInfiniteLevels:
		label.text = str(upgrade.displayName, " L", upgrade.level)
	else:
		label.text = upgrade.displayName
