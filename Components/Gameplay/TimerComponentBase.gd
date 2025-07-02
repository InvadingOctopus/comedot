## An abstract base class for Components that depend on a [Timer].

@abstract class_name TimerComponentBase
extends Component


#region Parameters
@export var isEnabled: bool = true
#endregion


#region State
@onready var selfAsTimer: Timer = self.get_node(^".") as Timer
#endregion


## Abstract; override in subclasses.
@abstract func onTimeout() -> void
