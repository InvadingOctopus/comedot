## Represents a delay for any action the player may not perform too quickly, such as firing a gun or mining resources.
## Recommended subclass for other components like [GunComponent] or [InteractionControlComponent].

## BUG: NOTE: When this component is subclassed and a Cooldown [Timer] is connected to the sublass,
## Godot [as of 4.3 Dev 3] will not show the [method onCooldownTimer_timeout] in the existing methods list for the new connection.
## But you can connect a new [Timer] to the `onCooldownTimer_timeout` method even if it is not overridden in the subclass.

class_name CooldownComponent
extends Component


@onready var cooldownTimer: Timer = $CooldownTimer


#region Parameters

## Number of seconds after shooting before another bullet can be emitted.
@export_range(0.1, 10.0, 0.1, "suffix:seconds") var cooldown: float = 3:
	set(newValue):
		cooldown = newValue
		if cooldownTimer: cooldownTimer.wait_time = newValue

#endregion


#region State
var hasCooldownCompleted := true # Start with the cooldown off
#endregion


#region Signals
signal didStartCooldown
signal didFinishCooldown
#endregion


#region Cooldown

func startCooldown(overrideTime: float = self.cooldown) -> void:
	printDebug(str("startCooldown() cooldown: ", self.cooldown, ", previous Timer.wait_time: ", cooldownTimer.wait_time, " → overrideTime: ", overrideTime))
	hasCooldownCompleted = false
	cooldownTimer.wait_time = overrideTime	
	cooldownTimer.start(overrideTime)
	didStartCooldown.emit()


func finishCooldown() -> void:
	printDebug("finishCooldown()")
	cooldownTimer.stop()
	hasCooldownCompleted = true
	didFinishCooldown.emit()


func onCooldownTimer_timeout() -> void:
	printDebug("onCooldownTimer_timeout()")
	finishCooldown()

#endregion
