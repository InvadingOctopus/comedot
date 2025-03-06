## Modifies [Stat] Resources over time at the interval specified on the child [Timer].
## TIP: Useful for regenerating a Health [Stat] or dealing poison damage-over-time, etc.
## For example, you may connect the [signal ShieldedHealthComponent.shieldDidDecrease] to [method Timer.start] on this [StatModifierComponent].
## TIP: Rename this component's node to "ManaRegenerationComponent" etc. to keep track of its purpose in the Scene Tree.
## TIP: To modify Stats such as the player's score or XP when monsters die etc., use [StatModifierOnDeathComponent]

class_name StatModifierComponent
extends Component


#region Parameters
@export var statsToModify: Dictionary[Stat, int] ## A [Dictionary] where the keys are [Stat] Resources and the values are the positive or negative modifier to apply to that respective Stat.
@export var isEnabled: bool = true
#endregion


func onTimerTimeout() -> void:
	if not isEnabled: return
	modifyStats()


func modifyStats() -> void:
	for stat in statsToModify:
		stat.value += statsToModify[stat]
