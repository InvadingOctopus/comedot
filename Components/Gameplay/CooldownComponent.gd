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

			# Update the Stat too because that would be the expected behavior of modifying the cooldown, right?
			if cooldownMillisecondsStat: cooldownMillisecondsStat.value = int(newValue * 1000)
			
			if cooldownTimer:
				if newValue > 0 and not is_zero_approx(newValue): # Avoid the annoying Godot error: "Time should be greater than zero."
					cooldownTimer.wait_time = newValue
				else:
					cooldownTimer.wait_time = minimumTimerWaitTime # HACK: TODO: Find a better way
					cooldownTimer.stop()

## An OPTIONAL alternative way to specify the delay between shots, by overriding the [member cooldown] property with a shared [Stat].
## IMPORTANT: Since [Stats] are integers only, the cooldown time represented by this Stat must be in MILLISECONDS, i.e. 1000 = 1 second, 500 = 0.5 seconds.
## TIP: This allows [Upgrade]s with a [StatModifierPayload] or debuffs etc. to easily increase/decrease the player's fire rate.
## @experimental
@export var cooldownMillisecondsStat: Stat:
	set(newValue):
		if newValue != cooldownMillisecondsStat:
			cooldownMillisecondsStat = newValue
			if cooldownMillisecondsStat: self.cooldown = cooldownMillisecondsStat.value / 1000.0
			else: self.cooldown = 3 # Use internal default if there is no Stat

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

## Starts the cooldown delay, applying the [member cooldownMillisecondsStat] if any to the [member cooldown].
func startCooldown(overrideTime: float = (cooldownMillisecondsStat.value / 1000.0) if cooldownMillisecondsStat else self.cooldown) -> void:
	## The Stat is reapplied above in case its value has changed
	if debugMode: 
		if cooldownMillisecondsStat: printTrace(["cooldownMillisecondsStat", cooldownMillisecondsStat.value])
		printDebug(str("startCooldown() cooldown: ", self.cooldown, ", previous Timer.wait_time: ", cooldownTimer.wait_time, " → overrideTime: ", overrideTime, ", cooldownMillisecondsStat: ", cooldownMillisecondsStat))
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
