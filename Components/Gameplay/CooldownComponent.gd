## Represents a delay for any action the player may not perform too quickly, such as firing a gun or mining resources.
## Recommended subclass for other components like [GunComponent] or [InteractionControlComponent].

## BUG: NOTE: When this component is subclassed and a Cooldown [Timer] is connected to the subclass,
## Godot [as of 4.3 Dev 3] will not show the [method onCooldownTimer_timeout] in the existing methods list for the new connection.
## But you can connect a new [Timer] to the `onCooldownTimer_timeout` method even if it is not overridden in the subclass.

class_name CooldownComponent
extends Component


#region Parameters

## The value that [member Timer.wait_time] will be reset to if it goes <= 0
## According to Godot documentation, it should be 0.05
const minimumTimerWaitTime: float = 0.05

## Number of seconds after shooting before another bullet can be emitted.
## WARNING: A value of 0.0 may cause issues with [Timer]
@export_range(0.05, 100, 0.05, "suffix:seconds") var cooldown: float = 3:
	set(newValue):
		if is_zero_approx(newValue) or newValue < 0:
			newValue = 0

		if newValue != cooldown:
			cooldown = newValue
			if cooldownTimer: 
				if newValue > 0 and not is_zero_approx(newValue): # Avoid the annoying Godot error: "Time should be greater than zero."
					cooldownTimer.wait_time = newValue
				else:
					cooldownTimer.wait_time = minimumTimerWaitTime # HACK: TODO: Find a better way
					cooldownTimer.stop()

#endregion


#region State
@onready var cooldownTimer: Timer = $CooldownTimer

var hasCooldownCompleted: bool = true # Start with the cooldown off
#endregion


#region Signals
signal didStartCooldown
signal didFinishCooldown
#endregion


#region Cooldown

func startCooldown(overrideTime: float = self.cooldown) -> void:
	printDebug(str("startCooldown() cooldown: ", self.cooldown, ", previous Timer.wait_time: ", cooldownTimer.wait_time, " → overrideTime: ", overrideTime))
	hasCooldownCompleted = false
	if overrideTime > 0 and not is_zero_approx(overrideTime): # Avoid the annoying Godot error: "Time should be greater than zero."
		cooldownTimer.wait_time = overrideTime
		cooldownTimer.start(overrideTime)
		didStartCooldown.emit()
	else: # If the time is too low, just go straight to the finish
		finishCooldown()


func finishCooldown() -> void:
	printDebug("finishCooldown()")
	cooldownTimer.stop()
	hasCooldownCompleted = true
	didFinishCooldown.emit()


func onCooldownTimer_timeout() -> void:
	printDebug("onCooldownTimer_timeout()")
	finishCooldown()

#endregion
