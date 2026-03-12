## Adds common "cooldown" functionality to a [Timer] for any actions a player may not perform too quickly, such as firing a gun or mining resources.
## Used by [CooldownComponent], [InteractionWithCooldownComponent] etc.
## IMPORTANT: ALWAYS use [method startCooldown]: Do NOT use the standard [method Timer.start] because the default Godot [Timer] is not aware of [member cooldownMilliseconds] or [member minimumCooldown] etc.
## IMPORTANT: ALWAYS check [member cooldownSeconds] instead of [member Timer.wait_time] because it resolves the [member cooldownMilliseconds] [member Stat.value]

class_name CooldownTimer
extends Timer

# TODO: Add isEnabled which should also toggle `Timer.paused`


#region Parameters

## According to Godot documentation, it should be 0.05
## Makes sure the new time is not 0 to avoid the annoying Godot error: "Time should be greater than zero."
const godotMinimumTime: float = 0.05

## Number of milliseconds between repeating an action, such as shooting another bullet or performing another dash.
## IMPORTANT: Since [Stats] are integers only, the cooldown time represented by this Stat must be in MILLISECONDS, i.e. 1000 = 1 second, 500 = 0.5 seconds.
## TIP: This allows [Upgrade]s with a [StatModifierPayload] or debuffs etc. to easily increase/decrease the player's rate of fire.
@export var cooldownMilliseconds: Stat

## The minimum value that will be enforced for [method Timer.start] during [method startCooldown]
## Supersedes [member cooldownMilliseconds] if that value is lower than this minimum.
@export_range(godotMinimumTime, 120, 0.05, "suffix:seconds", "or_greater") var minimumCooldown: float = 0.05

@export var debugMode: bool

#endregion


#region State

## Returns the [member cooldownMilliseconds] [member Stat.value] / 1000 if the [Stat] is present, otherwise [Timer.wait_time]
## Helps avoid crashes and reduce code because Dumbdot doesn't have an optional ? operator.
var cooldownSeconds: float:
	get: return float(cooldownMilliseconds.value) / 1000 if cooldownMilliseconds else self.wait_time # Convert from integer milliseconds to fractional seconds

## Returns `true` if there is still remaining [Timer.time_left].
## ALERT: Does NOT check [Timer.paused]
var isOnCooldown: bool: 
	get: return not is_zero_approx(self.time_left) # Apparently `not is_zero_approx()` is better than checking > 0

## Allows [method startCooldown] to ignore the cooldown ONCE; the function will return without starting the [Timer].
## IMPORTANT: This flag is always reset in [method startCooldown], so it must be set AFTER starting a cooldown.
@export_storage var shouldSkipNextCooldown: bool

#endregion


#region Signals
signal didStartCooldown(time: float) ## ALERT: NOT emitted if [method Timer.start] is called manually!
signal didFinishCooldown
#endregion


func _ready() -> void:
	# Also connect the signal via code to make it more convenient for subclasses which don't inherit the .tscn scene, such as GunComponent
	Tools.connectSignal(self.timeout, self.finishCooldown)


#region Cooldown

## Starts the cooldown delay, using [member cooldownSeconds] as the default for [param overrideTime] and emits [signal didStartCooldown].
## If this [Timer] is already running and [member Timer.paused], this method unpauses the [Timer].
## If [param restartIfOnCooldown] then an ongoing OR pause cooldown is restarted.
## TIP: Check [member isOnCooldown] before calling this method to avoid redundant processing or restarts.
## IMPORTANT: Do NOT use the standard [method Timer.start] because the default Godot [Timer] is of course unware of [member cooldownMilliseconds]
func startCooldown(overrideTime: float = self.cooldownSeconds, restartIfOnCooldown: bool = false) -> void:
	# TBD: PERFORMANCE: Do we really need all this crap just for a simple Timer.start()?
	# Or could the `didStartCooldown` signal be helpful in chaining with other components e.g. for animations etc.?

	if debugMode:
		Debug.printDebug(str("startCooldown() previous wait_time: ", self.wait_time, " → overrideTime: ", overrideTime, " + cooldownMilliseconds: ", (cooldownMilliseconds.logName if cooldownMilliseconds else "null"), ", minimumCooldown: ", minimumCooldown, ", shouldSkipNextCooldown: ", shouldSkipNextCooldown), self)

	if  shouldSkipNextCooldown: 
		shouldSkipNextCooldown = false
		return

	# Check for an ongoing cooldown to avoid unintended resets or redundant processing
	if self.isOnCooldown:
		if debugMode: Debug.printDebug(str("CooldownTimer already isOnCooldown: ", self.time_left, " paused: ", self.paused), self)
		if self.paused: self.paused = false # Unpause because running a Timer would be the behavior expected by the caller
		if not restartIfOnCooldown: return

	var clampedTime: float = maxf(minimumCooldown, overrideTime)

	# UNUSED: TBD: var previousTime: float = self.wait_time # Save the "actual" cooldown because Timer.start(overrideTime) modifies Timer.wait_time
	self.wait_time = clampedTime
	self.start()
	# UNUSED: TBD: self.wait_time = previousTime # Restore the default cooldown?
	didStartCooldown.emit(clampedTime)
	# TBD: If the new time is too low, just run straight to the finish?
	# UNUSED: finishCooldown()
	
	shouldSkipNextCooldown = false # Don't skip the NEXT next cooldown!


## Connected to [signal Timer.timeout] to be called when the cooldown [Timer] is over and emits [signal didFinishCooldown]
## May be called manually to call [method Timer.stop] and emit the signal.
func finishCooldown() -> void:
	# TBD: Check canSkipNextCooldown on finish?
	if debugMode: Debug.printDebug("finishCooldown()", self)
	var wasTimerRunning: bool = not is_zero_approx(self.time_left)
	self.stop()
	if wasTimerRunning:  didFinishCooldown.emit() # NOTE: Emit only if we were actually on cooldown

#endregion
