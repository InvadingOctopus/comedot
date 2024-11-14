## Modifies a [Stat] over time at the interval specified on the child [Timer].
## TIP: Useful for regenerating a Health [Stat] or dealing poison damage-over-time, etc.
## For example, you may connect the [signal ShieldedHealthComponent.shieldDidDecrease] to [method Timer.start] on this [StatModifierComponent].
## TIP: Rename this component's node to "ManaRegenerationComponent" etc. to keep track of its purpose in the Scene Tree.

class_name StatModifierComponent
extends Component


#region Parameters
@export var stat: Stat
@export_range(-10.0, 10.0, 0.5, "or_greater", "or_less") var modifier: int # HACK: A step of 0.5 to forcibly show the slider :')
@export var isEnabled: bool = true
#endregion


func onTimerTimeout() -> void:
	if not isEnabled: return
	stat.value += modifier
