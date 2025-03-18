## Displays a UI view when a [Stat] representing the player's Experience Points (XP) reaches its maximum.
## May be used to display a list of [Upgrade] choices via [UpgradeChoicesList] or perform other game-specific tasks via more specialized subclasses.

class_name LevelUpComponent
extends Component

# NOTE: This component's Scene is a Node2D so that it itself may be used as the UI or UI container.


#region Parameters
@export var xp: Stat:
	set(newValue):
		if newValue != xp:
			xp = newValue
			if xp and self.is_node_ready(): connectSignals()

@export var nodeToShowOnMaxXP: CanvasItem
@export var isEnabled: bool = true
#endregion


#region Signals
signal xpDidMax
signal xpDidReset
#endregion


func _ready() -> void:
	connectSignals()
	nodeToShowOnMaxXP.visible = false


func connectSignals() -> void:
	if xp: Tools.connectSignal(xp.didMax, self.onxp_didMax)


func onxp_didMax() -> void:
	nodeToShowOnMaxXP.visible = true
	xpDidMax.emit()


## Hides the [member nodeToShowOnMaxXP] and resets the [member xp] [Stat] to it's [member Stat.min] value.
func resetXP() -> void:
	nodeToShowOnMaxXP.visible = false
	xp.setToMin()
	xpDidReset.emit()
