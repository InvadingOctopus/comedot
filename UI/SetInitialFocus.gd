## Apply to a [Button] or other [Control] that should receive the initial UI focus when the player tries to navigate with a gamepad or keyboard when no control is focused.

class_name SetInitialFocus # This is a class so that other Button-handling etc. scripts may subclass and incorporate this functionality.
extends Control

# TODO: Option to set focus to some other node, so this script could be attached to a parent [Container] etc.


var didSetInitialFocus: bool = false:
	set(newValue):
		if newValue != didSetInitialFocus:
			didSetInitialFocus = newValue
			self.set_process_input(not didSetInitialFocus) # Only gobble input events when there is no focus


func _ready() -> void:
	# NOTE: If ANY other control already has focus, we don't need to set the -initial- focus anymore.
	self.didSetInitialFocus = is_instance_valid(self.get_viewport().gui_get_focus_owner())
	# If there is a gamepad but nothing focus, highlight a control to reduce the steps a player has to take before navigating the UI.
	if not didSetInitialFocus and not Input.get_connected_joypads().is_empty():
		setInitialFocus()


func setInitialFocus() -> void:
	if not didSetInitialFocus:
		self.grab_focus.call_deferred() # Godot Documentation: Using this method together with `Callable.call_deferred()` makes it more reliable, especially when called inside _ready().
		self.didSetInitialFocus = true


func _input(event: InputEvent) -> void: # TBD: Use _unhandled_input()?
	if not self.didSetInitialFocus \
	and ((event is InputEventJoypadButton or event is InputEventJoypadMotion) \
		or GlobalInput.isInputEventUIAction(event)):
			setInitialFocus()
			self.get_viewport().set_input_as_handled() # CHECK: Is this necessary or could it cause undesired behavior?
