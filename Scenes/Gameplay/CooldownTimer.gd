## Adds common "cooldown" functionality to a [Timer] for any actions a player may not perform too quickly, such as firing a gun or mining resources.
## Used by [GunComponent], [BulletlessGunComponent], [InteractionWithCooldownComponent] etc.
## IMPORTANT: ALWAYS use [method startCooldown]: Do NOT use the standard [method Timer.start] because the default Godot [Timer] is not aware of [member cooldownMilliseconds] or [member minimumCooldown] etc.
## WARNING: Calling [method Timer.stop] will NOT emit [signal Timer.timeout] or [signal CooldownTimer.didFinishCooldown] — Call [method cancelCooldown] to manually cancel a cooldown.

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
## NOTE: [method startCooldown] rejects time values < [constant godotMinimumTime] 0.05
@export_range(godotMinimumTime, 120, 0.05, "suffix:seconds", "or_greater") var minimumCooldown: float = 0.05:
	set(newValue):
		newValue = maxf(godotMinimumTime, newValue)
		if newValue != minimumCooldown:
			minimumCooldown = newValue


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

## Allows [method startCooldown] to ignore the cooldown ONCE; the function will return without starting the [Timer]
## IMPORTANT: This flag is always reset in [method startCooldown], so it must be set AFTER starting a cooldown.
@export_storage var shouldSkipNextCooldown:		 bool

## Enabled by [method startCooldown] to make sure repeated calls to [method onTimeout] don't emit redundant [signal didFinishCooldown] signals.
@export_storage var shouldEmitDidFinishCooldown: bool

#endregion


#region Signals
signal didStartCooldown(time: float) ## ALERT: NOT emitted if [method Timer.start] is called manually!
signal didFinishCooldown ## ALERT: NOT emitted if [method Timer.stop] or [method cancelCooldown] is called! TIP: Use [method onTimeout] to stop AND emit.
#endregion


func _ready() -> void:
	# Also connect the signal via code to make it more convenient for subclasses which don't inherit the .tscn scene, such as GunComponent
	if not self.timeout.is_connected(self.onTimeout):
		self.timeout.connect(self.onTimeout, CONNECT_PERSIST)


#region Cooldown

## Starts the cooldown delay, using [member cooldownSeconds] as the default for [param overrideTime] and emits [signal didStartCooldown].
## If this [Timer] is already running and [member Timer.paused], this method unpauses the [Timer].
## If [param restartIfOnCooldown] then an ongoing OR pause cooldown is restarted.
## Returns the [member Timer.time_left] if a cooldown was started or already running.
## Returns 0 if [member shouldSkipNextCooldown] or if [member cooldownSeconds] or [param overrideTime] is < [constant godotMinimumTime] 0.05 then this call is ignored.
## Returns -1 if the state is invalid.
## TIP: Check [member isOnCooldown] before calling this method to avoid redundant processing or restarts.
## IMPORTANT: Do NOT use the standard [method Timer.start] because the default Godot [Timer] is of course unware of [member cooldownMilliseconds]
func startCooldown(overrideTime: float = self.cooldownSeconds, restartIfOnCooldown: bool = false) -> float:
	# TBD: PERFORMANCE: Do we really need all this crap just for a simple Timer.start()?
	# Or could the `didStartCooldown` signal be helpful in chaining with other components e.g. for animations etc.?

	if overrideTime < godotMinimumTime: return 0

	if  not self.is_node_ready() or not self.is_inside_tree():
		Debug.printDebug("startCooldown(): Timer node not ready", self)
		return -1 # TBD: Use different values?

	if  debugMode:
		Debug.printDebug(str("startCooldown() previous wait_time: ", self.wait_time, " → overrideTime: ", overrideTime, " + cooldownMilliseconds: ", (cooldownMilliseconds.logName if cooldownMilliseconds else "null"), ", minimumCooldown: ", minimumCooldown, ", shouldSkipNextCooldown: ", shouldSkipNextCooldown), self)

	# Check for an ongoing cooldown to avoid unintended resets or redundant processing
	if  self.isOnCooldown:
		if debugMode: Debug.printDebug(str("CooldownTimer already isOnCooldown: ", self.time_left, " paused: ", self.paused), self)
		if self.paused: self.paused = false # Unpause because running a Timer would be the behavior expected by the caller
		if not restartIfOnCooldown: return self.time_left

	# IMPORTANT: Check for skip AFTER checking for a running cooldown,
	# because "consuming" `shouldSkipNextCooldown` and then cancelling would prevent the ACTUAL next cooldown from being skipped.
	if  shouldSkipNextCooldown:
		shouldSkipNextCooldown = false
		return 0 # TBD: Use different values?

	var  clampedTime:  float = maxf(minimumCooldown, overrideTime)

	var  previousTime: float = self.wait_time # Save the "actual" cooldown because Timer.start(overrideTime) modifies `Timer.wait_time`
	self.wait_time = clampedTime
	self.start()
	self.shouldEmitDidFinishCooldown = true
	self.wait_time = previousTime # Restore the default cooldown

	shouldSkipNextCooldown = false # Don't skip the NEXT next cooldown! # NOTE: Set BEFORE `didStartCooldown` so handlers can change it if they want
	didStartCooldown.emit(clampedTime)

	# TBD: If the new time is too low, just run straight to the finish?
	return self.time_left


## Stops this [Timer] and disables [member shouldEmitDidFinishCooldown]
## NOTE: Does NOT emit [signal Timer.timeout] or [signal didFinishCooldown]
func cancelCooldown() -> void:
	if debugMode: Debug.printDebug(str("cancelCooldown() time_left: ", time_left), self)
	stop() # GODOT: Calling stop() does not emit the `timeout` signal
	shouldEmitDidFinishCooldown = false


## Connected to [signal Timer.timeout] to be called when the cooldown [Timer] is over.
## Emits [signal didFinishCooldown] if [member shouldEmitDidFinishCooldown] is enabled.
## NOTE: Does NOT emit [signal Timer.timeout] if called manually.
func onTimeout() -> void:
	# TBD: Check shouldSkipNextCooldown on finish?
	if  debugMode: Debug.printDebug(str("onTimeout() shouldEmitDidFinishCooldown: ", shouldEmitDidFinishCooldown, ", time_left: ", time_left), self)
	stop() # GODOT: Calling stop() does not emit the `timeout` signal
	if  shouldEmitDidFinishCooldown:
		shouldEmitDidFinishCooldown = false # IMPORTANT: Clear BEFORE emitting because handlers may immediately start a new cooldown
		didFinishCooldown.emit() # TBD: Emit only if we were actually on cooldown? But that won't work for the "natural" `Timer.timeout` signal which is emitted after the Timer stops

#endregion
