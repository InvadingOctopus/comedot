## An abstract base class for simple AI Agent Components that depend on a [Timer].
## e.g. to have a random chance to attack every N seconds and so on.
## @experimental

class_name TimerAgentComponentBase # NOTE: TBD: Cannot set as `@abstract` because it causes an error in Spawner.gd:99 @ `var newSpawn: Node2D = sceneResource.instantiate()` "Cannot set object script."
extends Component


#region Parameters
@export var isEnabled: bool = true
#endregion


#region State
@onready var selfAsTimer: Timer = self.get_node(^".") as Timer
#endregion


## Abstract; override in subclasses.
func onTimeout() -> void:
	pass # if not isEnabled: return
