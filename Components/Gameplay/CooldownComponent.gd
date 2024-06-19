## Represents a delay for any action the player may not perform too quickly, such as firing a gun or mining resources.
## Recommended subclass for other components like [GunComponent] or [InteractionControlComponent].

## BUG: NOTE: When this component is subclassed and a Cooldown [Timer] is connected to the sublass,
## Godot [as of 4.3 Dev 3] will not show the [method onCooldownTimer_timeout] in the existing methods list for the new connection.
## But you can connect a new [Timer] to the `onCooldownTimer_timeout` method even if it is not overridden in the subclass.

class_name CooldownComponent
extends Component


@onready var cooldownTimer := $CooldownTimer


#region Parameters

## Number of seconds after shooting before another bullet can be emitted.
@export_range(0.1, 10.0, 0.1, "suffix:seconds") var cooldown: float = 3:
	get:
		return %CooldownTimer.wait_time if %CooldownTimer else cooldown
	set(newValue):
		cooldown = newValue
		if %CooldownTimer:
			%CooldownTimer.wait_time = newValue

#endregion


#region State
var hasCooldownCompleted := true # Start with the cooldown off
#endregion


#region Signals
signal didStartCooldown
signal didFinishCooldown
#endregion


#region Cooldown

func startCooldown():
	printDebug("startCooldown()")
	hasCooldownCompleted = false
	cooldownTimer.start()
	didStartCooldown.emit()


func finishCooldown():
	printDebug("finishCooldown()")
	cooldownTimer.stop()
	hasCooldownCompleted = true
	didFinishCooldown.emit()


func onCooldownTimer_timeout():
	printDebug("onCooldownTimer_timeout()")
	finishCooldown()

#endregion
