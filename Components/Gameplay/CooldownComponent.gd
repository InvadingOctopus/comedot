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

## An OPTIONAL [Stat] whose [member Stat.value] is added to or subtracted from the base [member cooldown].
## IMPORTANT: Since [Stats] are integers only, the cooldown time represented by this Stat must be in MILLISECONDS, i.e. 1000 = 1 second, 500 = 0.5 seconds.
## TIP: This allows [Upgrade]s with a [StatModifierPayload] or debuffs etc. to easily increase/decrease the player's rate of fire.
## IMPORTANT: Use [member cooldownWithModifier] to get the actual combined cooldown value.
## @experimental
@export var cooldownMillisecondsModifier: Stat

#endregion


#region State
@onready var cooldownTimer: Timer = $CooldownTimer

## Returns the total cooldown value including the base [member cooldown] seconds +/- the [member cooldownMillisecondsModifier] [Stat] if any.
## @experimental
var cooldownWithModifier: float:
	get:
		if cooldownMillisecondsModifier: return self.cooldown + (float(cooldownMillisecondsModifier.value) / 1000.0) # Convert from milliseconds to seconds
		else: return cooldown

var hasCooldownCompleted: bool = true # Start with the cooldown off
#endregion


#region Signals
signal didStartCooldown
signal didFinishCooldown
#endregion


func _ready() -> void:
	# Also connect the signal via code to make it more convenient for subclasses which don't inherit the .tscn scene, such as GunComponent
	Tools.connectSignal(cooldownTimer.timeout, self.finishCooldown)


#region Cooldown

## Starts the cooldown delay, applying the [member cooldownMillisecondsModifier] if any to the [member cooldown].
func startCooldown(overrideTime: float = self.cooldownWithModifier) -> void:
	## The Stat is reapplied above in case its value has changed
	if debugMode:
		if cooldownMillisecondsModifier: printTrace(["cooldownMillisecondsModifier", cooldownMillisecondsModifier.value])
		printDebug(str("startCooldown() cooldown: ", self.cooldown, ", previous Timer.wait_time: ", cooldownTimer.wait_time, " → overrideTime/cooldownWithModifier: ", overrideTime, ", cooldownMillisecondsModifier: ", cooldownMillisecondsModifier.logName if cooldownMillisecondsModifier else "null"))
	hasCooldownCompleted = false

	if overrideTime > 0 and not is_zero_approx(overrideTime): # Avoid the annoying Godot error: "Time should be greater than zero."
		cooldownTimer.wait_time = overrideTime
		cooldownTimer.start(overrideTime)
		didStartCooldown.emit()
	else: # If the time is too low, run straight to the finish
		finishCooldown()


func finishCooldown() -> void:
	if debugMode: printDebug("finishCooldown()")
	cooldownTimer.stop()
	hasCooldownCompleted = true
	didFinishCooldown.emit()

#endregion
