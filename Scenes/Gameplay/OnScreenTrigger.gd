## A convenience subclass of [VisibleOnScreenNotifier2D] with features such as a limited number of uses & a [Timer] delay etc.
## TIP: EXAMPLE USAGE:
## Triggering cutscenes.
## Spawning preset enemy waves via [SpawnPoint] & [SpawnerList] at specific locations on a map e.g. in a scrolling shoot-em-up.

class_name OnScreenTrigger # TBD: Better name? ScreenEntryTrigger?
extends VisibleOnScreenNotifier2D


#region Parameters

@export var isEnabled:	bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			if delayTimer: Tools.toggleSignal(delayTimer.timeout, self.onTimer_timeout, self.isEnabled)

## An optional [Timer] that will be started on a [signal screen_entered] to add a delay before calling [member trigger]
## If [member shouldStopDelayTimerOnExit], stopped without triggering when this [VisibleOnScreenNotifier2D] goes off screen.
## NOTE: [Timer.one_shot] is enforced.
## NOTE: Calling [method Timer.stop] will NOT invoke [method trigger]
@export var delayTimer:		Timer:
	set(newValue):
		if newValue != delayTimer:
			# Disconnect any previous Timers
			if  delayTimer: Tools.disconnectSignal(delayTimer.timeout, self.onTimer_timeout)
			delayTimer = newValue
			if  delayTimer:
				delayTimer.one_shot = true
				Tools.toggleSignal(delayTimer.timeout, self.onTimer_timeout, self.isEnabled)

## If `true` (default) then [member delayTimer] is stopped without calling [method trigger] when this node goes offscreen.
@export var shouldStopDelayTimerOnExit: bool = true

@export var debugMode:	bool


@export_group("Number of Uses")

@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")	var shouldLimitTriggers: bool
@export_range(0, 100, 1, "or_greater")			var maxTriggers:	int = 100
@export var shouldDeleteAfterMaxTriggers: bool = true

#endregion


#region State
@export_storage var triggerCount: int = 0
#endregion


#region Signals
## Emitted from [method trigger] if [member isEnabled] and if [member triggerCount] is valid or irrelevant.
## TIP: If connecting to methods like [method SpawnerList.spawnBatch] remember to "unbind" 1 signal argument to avoid sending the [param triggerCount]
signal didTrigger(triggerCount: int)

## Emitted after [method trigger] sets [member triggerCount] >= [member maxTriggers]
signal didReachMaxTriggers
#endregion


#region Events

func _ready() -> void:
	if  shouldLimitTriggers and triggerCount >= maxTriggers:
		handleMaxTriggers(false) # not emitSignals because a `triggerCount` loaded from @export_storage may have happened a long time ago

	if  delayTimer:
		delayTimer.one_shot = true
		Tools.toggleSignal(delayTimer.timeout, self.onTimer_timeout, self.isEnabled)


func onScreenEntered() -> void:
	if not isEnabled: return
	if debugMode: Debug.printDebug("onScreenEntered()", self)
	if not delayTimer:
		trigger()
	elif delayTimer and (delayTimer.time_left < 0 or is_zero_approx(delayTimer.time_left)):
		delayTimer.one_shot = true # Just in case
		delayTimer.start()


func onTimer_timeout() -> void:
	delayTimer.stop()
	if isEnabled: trigger()


## May be overridden by subclasses to add extra "cleanup"
func onScreenExited() -> void:
	if debugMode:  Debug.printDebug("onScreenExited()", self)
	if shouldStopDelayTimerOnExit and delayTimer: delayTimer.stop() # NOTE: Does not emit `timeout`

#endregion


#region Trigger

func trigger() -> bool:
	if not isEnabled \
	or (shouldLimitTriggers and triggerCount >= maxTriggers): return false

	# Keep track of how many times we were triggered
	triggerCount += 1

	if shouldLimitTriggers and triggerCount >= maxTriggers:
		handleMaxTriggers(true) # emitSignals
	else:
		if debugMode: Debug.printDebug(str("onScreenEntered() triggerCount: ", triggerCount), self)
		didTrigger.emit(triggerCount)
	return true


func handleMaxTriggers(emitSignals: bool = true) -> void:
	if triggerCount < maxTriggers: return
	if debugMode: Debug.printDebug(str("onScreenEntered() shouldLimitTriggers: triggerCount: ", triggerCount, " >= maxTriggers: ", maxTriggers, " ・ Disabling…"), self)
	
	if emitSignals: didTrigger.emit(triggerCount)

	# Let signal handlers see that we're disabled now after the last trigger
	# DESIGN: Disable AFTER `didTrigger` so subclasses such as SpawnLocationTrigger can do their work properly, as in onSpawner_willAddSpawn() etc.
	self.isEnabled = false

	if emitSignals: didReachMaxTriggers.emit()

	if shouldDeleteAfterMaxTriggers:
		if debugMode: Debug.printLog("onScreenEntered() shouldDeleteAfterMaxTriggers: Deleting…", self)
		self.queue_free()

#endregion
