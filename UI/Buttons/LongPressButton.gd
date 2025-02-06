## A [Button] that must be held for a specified duration before it emits its [signal longPressed] signal.
## Used for confirmation about crucial tasks such as restarting the game or deleting data.
## Releasing the mouse INSIDE this button after the [member duration] will emit the [signal longPressed] signal.
## Releasing the mouse OUTSIDE this button will cancel the long press.

class_name LongPressButton
extends Button


#region Parameters
## The duration in seconds for how long the button must be held down before the [signal longPressed] signal can be emitted.
@export var duration: float = 1.0:
	set(newValue):
		if newValue != duration:
			duration = newValue
			if is_node_ready():
				timer.wait_time = self.duration
				bar.max_value = timer.wait_time
#endregion


#region State
@onready var timer: Timer = $Timer
@onready var bar:	ProgressBar = $ProgressBar

var isHeld: bool = false: ## `true` while the mouse is pressed after clicking on this button.
	set(newValue):
		if newValue != isHeld:
			isHeld = newValue
			self.set_process(isHeld) # Call _process() per frame only if the bar needs to be updated
			resetBar()

## Set to `true` after the button has been held down for [member duration].
## Releasing the mouse inside the button after this moment will emit the [signal longPressed] signal.
var hasCompletedPress: bool = false
#endregion


#region Signals
## Emitted after the button has been held down for the specified [member duration] and the mouse is released INSIDE the button.
signal longPressed
#endregion


func _ready() -> void:
	self.action_mode = ActionMode.ACTION_MODE_BUTTON_RELEASE # Make sure the Button is considered "clicked" only if the mouse is released INSIDE the Button.
	self.set_process(isHeld)
	timer.wait_time = self.duration # Make sure the Timer matches our property.
	resetBar()


func resetBar() -> void:
	bar.max_value = timer.wait_time
	bar.value = 0 # Grow from left→to→right
	bar.visible = self.isHeld


func onButtonDown() -> void:
	self.isHeld = true # calls resetBar()
	timer.start()


func onButtonUp() -> void:
	timer.stop()
	# NOTE: Counting on onPressed() to be called first if the mouse was released inside the Button.
	# CARE: May be a future bug if Godot behavior/order of events changes.

	# Reset
	self.isHeld = false # calls resetBar()
	self.hasCompletedPress = false


## Called when the mouse is released INSIDE this [Button].
func onPressed() -> void:
	# Emit the signal only if we are still pressed
	if self.isHeld and self.hasCompletedPress:
		self.longPressed.emit()
		# Reset
		self.isHeld = false # calls resetBar()
		self.hasCompletedPress = false


func _process(_delta: float) -> void:
	# Increase the bar from left→to→right
	bar.value = timer.wait_time - timer.time_left


func onTimer_timeout() -> void:
	if self.isHeld: self.hasCompletedPress = true
	bar.value = timer.wait_time - timer.time_left
	self.set_process(false)
