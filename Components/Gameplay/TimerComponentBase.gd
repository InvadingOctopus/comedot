## An abstract base class for Components that depend on a [Timer] or whose node itself is a [Timer].

@abstract class_name TimerComponentBase
extends Component


#region Parameters
@export var isEnabled: bool = true:
	set = setIsEnabled ## Use function as setter so subclasses like [BulletlessGunComponent] may override it.
#endregion


#region State
@onready var timer: Timer = self.get_node(^".") as Timer
#endregion


func setIsEnabled(newValue: bool) -> void:
	if newValue != isEnabled:
		isEnabled = newValue
		if not isEnabled: timer.stop()


## Abstract; override in subclasses.
@abstract func onTimeout() -> void
