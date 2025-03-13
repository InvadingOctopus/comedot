## Represents a delay for any action the player may not perform too quickly, such as firing a gun or mining resources.
## Recommended base class for other Components to extend such as [GunComponent] or [InteractionControlComponent].

class_name CooldownComponent
extends Component

# NOTE: The Component Node itself should NOT be a [Timer] in order to allow other types of Nodes to extend this script, such as GunComponent which is Node2D


#region Parameters

## The value that [member Timer.wait_time] will be reset to if it goes <= 0
## According to Godot documentation, it should be 0.05
const minimumTimerWaitTime: float = 0.05

## Number of seconds after shooting before another bullet can be emitted.
## WARNING: A value of 0.0 may cause issues with [Timer]
@export_range(0.05, 120, 0.05, "suffix:seconds") var cooldown: float = 3:
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


func _ready() -> void:
	# Also connect the signal via code to make it more convenient for subclasses which don't inherit the .tscn scene, such as GunComponent
	Tools.reconnectSignal(cooldownTimer.timeout, self.finishCooldown)


#region Cooldown

func startCooldown(overrideTime: float = self.cooldown) -> void:
	if debugMode: printDebug(str("startCooldown() cooldown: ", self.cooldown, ", previous Timer.wait_time: ", cooldownTimer.wait_time, " → overrideTime: ", overrideTime))
	hasCooldownCompleted = false
	if overrideTime > 0 and not is_zero_approx(overrideTime): # Avoid the annoying Godot error: "Time should be greater than zero."
		cooldownTimer.wait_time = overrideTime
		cooldownTimer.start(overrideTime)
		didStartCooldown.emit()
	else: # If the time is too low, just go straight to the finish
		finishCooldown()


func finishCooldown() -> void:
	if debugMode: printDebug("finishCooldown()")
	cooldownTimer.stop()
	hasCooldownCompleted = true
	didFinishCooldown.emit()

#endregion
