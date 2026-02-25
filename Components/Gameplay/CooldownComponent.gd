## Represents a delay for any action the player may not perform too quickly, such as firing a gun or mining resources.
## Recommended base class for other Components to extend such as [GunComponent] or [InteractionControlComponent].

class_name CooldownComponent
extends Component

# IMPORTANT: DESIGN: The Component Node itself should NOT be a [Timer] in order to allow other types of Nodes to extend this script, such as GunComponent which is Node2D


#region Parameters

## The value that [member Timer.wait_time] will be reset to if it goes <= 0
## According to Godot documentation, it should be 0.05
const minimumDelay: float = 0.05

## Number of seconds between repeating an action, such as shooting another bullet or performing another dash.
## WARNING: A value of 0.0 may cause issues with [Timer]
@export_range(minimumDelay, 120, 0.05, "suffix:seconds") var cooldown: float = 3:
	set(newValue):
		if is_zero_approx(newValue) or newValue < 0: # Snap the new value to 0 if it's almost 0 or less
			if debugMode: printDebug(str("Correcting cooldown newValue: ", newValue, " → 0"))
			newValue = 0

		if newValue != cooldown:
			if debugMode: printTrace(str("cooldown: ", cooldown, " → ", newValue))
			cooldown = newValue
			if self.is_node_ready(): self.setCooldown()

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

## Returns `true` if the `cooldownTimer` still has remaining [Timer.time_left].
## ALERT: Does NOT check [Timer.paused]
var isOnCooldown: bool: 
	get: return not is_zero_approx(cooldownTimer.time_left) # Apparently `not is_zero_approx()` is better than checking > 0

## Allows [method startCooldown] to ignore the cooldown ONCE.
## NOTE: This flag is reset in [method startCooldown], so it must be set AFTER starting a cooldown.
@export_storage var shouldSkipNextCooldown: bool

#endregion


#region Signals
signal didStartCooldown(time: float) ## ALERT: NOT emitted if [method Timer.start] is called manually on [member cooldownTimer].
signal didFinishCooldown
#endregion


func _ready() -> void:
	setCooldown() # Property setters are not applied on _ready()
	# Also connect the signal via code to make it more convenient for subclasses which don't inherit the .tscn scene, such as GunComponent
	Tools.connectSignal(cooldownTimer.timeout, self.finishCooldown)


#region Cooldown

## Sets the [member cooldownTimer] [member Timer.wait_time] and returns the resulting corrected time.
func setCooldown(newTime: float = self.cooldownWithModifier) -> float:
	if not cooldownTimer: return 0

	if (newTime > minimumDelay or is_equal_approx(newTime, minimumDelay)) \
	and not is_zero_approx(newTime): # Avoid the annoying Godot error: "Time should be greater than zero."
		cooldownTimer.wait_time = newTime
	else:
		cooldownTimer.wait_time = minimumDelay # HACK: TODO: Find a better way
		cooldownTimer.stop()
	
	if debugMode: printTrace(str("newTime: ", newTime, " → ", cooldownTimer, ".wait_time: ", cooldownTimer.wait_time))
	return cooldownTimer.wait_time


## Starts the cooldown delay, applying the [member cooldownMillisecondsModifier] if any to the [member cooldown].
## If the [member cooldownTimer] is already running and [member Timer.paused], this method unpauses the [Timer].
## If [param restartIfOnCooldown] then an ongoing OR pause cooldown is restarted.
## May be skipped for one call by [member shouldSkipNextCooldown] which is always reset in this function.
## IMPORTANT: Check [member isOnCooldown] before calling this method to avoid restarting an ongoing cooldown!
func startCooldown(overrideTime: float = self.cooldownWithModifier, restartIfOnCooldown: bool = false) -> void:
	# TODO: Handle ongoing Timer

	## The Stat is reapplied above in case its value has changed
	if debugMode:
		if cooldownMillisecondsModifier: printTrace(["cooldownMillisecondsModifier", cooldownMillisecondsModifier.value])
		printDebug(str("startCooldown() cooldown: ", self.cooldown, ", previous Timer.wait_time: ", cooldownTimer.wait_time, " → overrideTime/cooldownWithModifier: ", overrideTime, ", cooldownMillisecondsModifier: ", (cooldownMillisecondsModifier.logName if cooldownMillisecondsModifier else "null"), ", shouldSkipNextCooldown: ", shouldSkipNextCooldown))
	
	if  shouldSkipNextCooldown:
		shouldSkipNextCooldown = false
		return

	# Check for an ongoing cooldown to avoid unintended resets or redundant processing
	if self.isOnCooldown:
		if debugMode: printDebug(str("cooldownTimer already isOnCooldown: ", cooldownTimer.time_left, " paused: ", cooldownTimer.paused))
		if cooldownTimer.paused: cooldownTimer.paused = false # Unpause because running a Timer would be the behavior expected by the caller
		if not restartIfOnCooldown: return

	if overrideTime > 0 and not is_zero_approx(overrideTime): # Avoid the annoying Godot error: "Time should be greater than zero."
		var previousTime: float = cooldownTimer.wait_time # Save the "actual" cooldown because Timer.start(overrideTime) modifies Timer.wait_time
		cooldownTimer.start(overrideTime)
		cooldownTimer.wait_time = previousTime # Restore the default cooldown
		didStartCooldown.emit(overrideTime)
	else: # If the time is too low, run straight to the finish
		finishCooldown()
	
	shouldSkipNextCooldown = false # Don't skip the NEXT next cooldown


func finishCooldown() -> void:
	if debugMode: printDebug("finishCooldown()")
	cooldownTimer.stop()
	didFinishCooldown.emit()

#endregion
