## A wrapper around [CooldownTimer] which is a [Timer] specialized for representing a delay for any action the player may not perform too quickly, such as firing a gun or mining resources.
## Intended as a base class for other Components which must expose their cooldown state to external monitors.
## NOTE: For most cases, just using [CooldownTimer] itself is sufficient.
## @deprecated: Use [CooldownTimer]
## @experimental

class_name CooldownComponent
extends Component

# IMPORTANT: DESIGN: The Component Node itself should NOT be a [Timer] in order to allow other types of Nodes to extend this script, such as GunComponent which is Node2D


#region State

@onready var cooldownTimer: CooldownTimer = $CooldownTimer

## Returns `true` if the `cooldownTimer` still has remaining [Timer.time_left].
## ALERT: Does NOT check [Timer.paused]
var isOnCooldown: bool:
	get: return cooldownTimer.isOnCooldown

## Allows [method startCooldown] to ignore the cooldown ONCE.
## NOTE: This flag is reset in [method startCooldown], so it must be set AFTER starting a cooldown.
@export_storage var shouldSkipNextCooldown: bool:
	set(newValue):	if self.is_node_ready(): cooldownTimer.shouldSkipNextCooldown = newValue
	get:			return cooldownTimer.shouldSkipNextCooldown if self.is_node_ready() else false

#endregion


#region Signals
signal didStartCooldown(time: float) ## ALERT: NOT emitted if [method Timer.start] is called manually on [member cooldownTimer].
signal didFinishCooldown
#endregion


func _ready() -> void:
	Tools.connectSignal(cooldownTimer.didStartCooldown,  self.didStartCooldown.emit) # NOTE: This should automatically bind the `time` argument, right?
	Tools.connectSignal(cooldownTimer.didFinishCooldown, self.didFinishCooldown.emit)


#region Cooldown

## Calls [method CooldownTimer.startCooldown]
func startCooldown(overrideTime: float = cooldownTimer.cooldownSeconds, restartIfOnCooldown: bool = false) -> void:
	cooldownTimer.startCooldown(overrideTime, restartIfOnCooldown)


## Wrapper for [method CooldownTimer.finishCooldown]
func finishCooldown() -> void:
	cooldownTimer.finishCooldown()

#endregion
