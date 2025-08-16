## Updates a [ProgressBar] to show the remaining time and of a [Timer].
## TIP: Use this to display UI for cooldowns.

class_name TimerProgressBar
extends ProgressBar

# TODO: Vertical bars


#region Parameters

@export var timer: Timer:
	set(newValue):
		if newValue != timer:
			timer = newValue
			if self.is_node_ready(): applyNewTimer()

@export var shouldSetStyle: bool = true # Applies a minial visual style
@export_range(0, 16, 1) var height: float = 2 # If [member shouldSetStyle]

@export var shouldHideWhenZero: bool = true # Hides the [ProgressBar] when the [Timer] is stopped at 0.

#endregion


func _ready() -> void:
	if shouldSetStyle:
		self.show_percentage = false
		self.size.y = height
		self.modulate = Color(self.modulate, 0.75)
	applyNewTimer()


func applyNewTimer() -> void:
	self.max_value			= timer.wait_time
	self.value				= timer.time_left
	self.process_mode		= timer.process_mode
	self.process_priority	= timer.process_priority # NOTSURE: Does doing this improve anything?	Tools.toggleSignal(timer.timeout, self.onTimer_timeout, self.shouldHideWhenZero)
	if shouldSetStyle: self.step = self.size.x / self.max_value # Try to make 1 step = 1 pixel


func _process(_delta: float) -> void:
	# TODO: PERFORMANCE: DUMBDOT: A way to enable _process() only when `timer` starts, but Dumbdot doesn't have a start signal for [Timer] :(
	if  shouldHideWhenZero and is_zero_approx(timer.time_left):
		self.visible = false
		return
	else:
		self.visible = true

	if  self.max_value != timer.wait_time: # TBD: PERFORMANCE: Check or set always?
		self.max_value  = timer.wait_time
		if shouldSetStyle: self.step = self.max_value / self.size.x

	self.value = timer.time_left
