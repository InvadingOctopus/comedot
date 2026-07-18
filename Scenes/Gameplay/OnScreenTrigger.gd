## A convenience subclass of [VisibleOnScreenNotifier2D] with features such as a limited number of uses & a [Timer] delay etc.
## TIP: EXAMPLE USAGE:
## Triggering cutscenes.
## Spawning preset enemy waves via [SpawnerStack] at specific locations on a map e.g. in an scrolling shoot-em-up.

class_name OnScreenTrigger # TBD: Better name? ScreenEntryTrigger?
extends VisibleOnScreenNotifier2D


#region Parameters

@export var isEnabled:	bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			if timer: Tools.toggleSignal(timer.timeout, self.onTimer_timeout, self.isEnabled)

## An optional [Timer] that will be started on a [signal screen_entered] to add a delay before calling [member trigger]
## NOTE: [Timer.one_shot] is enforced.
@export var timer:		Timer:
	set(newValue):
		if newValue != timer:
			# Disconnect any previous Timers
			if  timer: Tools.disconnectSignal(timer.timeout, self.onTimer_timeout)
			timer = newValue
			if  timer:
				timer.one_shot = true
				Tools.toggleSignal(timer.timeout, self.onTimer_timeout, self.isEnabled)

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
signal didTrigger(triggerCount: int) ## Emitted from [method trigger] if [member isEnabled] and if [member triggerCount] is valid or irrelevant.
signal didReachMaxTriggers ## Emitted after [method trigger] sets [member triggerCount] >= [member maxTriggers]
#endregion


func _ready() -> void:
	if shouldLimitTriggers and triggerCount >= maxTriggers:
		handleMaxTriggers(false) # not emitSignals becuase a `triggerCount` loaded from @export_storage may have happeend a long time ago

	if timer:
		timer.one_shot = true
		Tools.toggleSignal(timer.timeout, self.onTimer_timeout, self.isEnabled)


func onScreenEntered() -> void:
	if not isEnabled: return

	if not timer:
		trigger()
	elif timer and (timer.time_left < 0 or is_zero_approx(timer.time_left)):
		timer.one_shot = true # Just in case
		timer.start()


func onTimer_timeout() -> void:
	timer.stop()
	if isEnabled: trigger()


func trigger() -> void:
	if not isEnabled \
	or (shouldLimitTriggers and triggerCount >= maxTriggers): return

	# Keep track of how many times we were triggered
	triggerCount += 1

	if shouldLimitTriggers and triggerCount >= maxTriggers:
		handleMaxTriggers(true) # emitSignals
	else:
		if debugMode: Debug.printDebug(str("onScreenEntered() triggerCount: ", triggerCount), self)
		didTrigger.emit(triggerCount)


func handleMaxTriggers(emitSignals: bool = true) -> void:
	if triggerCount < maxTriggers: return
	if debugMode: Debug.printDebug(str("onScreenEntered() shouldLimitTriggers: triggerCount: ", triggerCount, " >= maxTriggers: ", maxTriggers, " ・ Disabling…"), self)
	
	self.isEnabled = false # Let signal handlers see that we're disabled now after the last trigger

	if emitSignals: 
		didTrigger.emit(triggerCount)
		didReachMaxTriggers.emit()

	if shouldDeleteAfterMaxTriggers:
		if debugMode: Debug.printLog("onScreenEntered() shouldDeleteAfterMaxTriggers: Deleting…", self)
		self.queue_free()
