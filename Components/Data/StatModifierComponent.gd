## Modifies a [Stat] over time at the interval specified on the child [Timer].
class_name StatModifierComponent
extends Component

@export var stat: Stat

@export_range(-10.0, 10.0, 0.5, "or_greater", "or_less") var modifier: int # HACK: A step of 0.5 to fordibly show the slider :')

@export var isEnabled := true

func onTimerTimeout() -> void:
	if not isEnabled: return
	stat.value += modifier
