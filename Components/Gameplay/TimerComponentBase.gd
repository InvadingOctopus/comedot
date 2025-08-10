## An abstract base class for Components that depend on a [Timer] or whose node itself is a [Timer].

@abstract class_name TimerComponentBase
extends Component


#region Parameters
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			if not isEnabled: timer.stop()
#endregion


#region State
@onready var timer: Timer = self.get_node(^".") as Timer
#endregion


## Abstract; override in subclasses.
@abstract func onTimeout() -> void
