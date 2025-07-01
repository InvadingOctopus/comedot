## Allows a [ScrollContainer] to be scrolled with the Right Joystick.
## The Left, Joystick is used for moving the UI focus.

extends ScrollContainer


#region Parameters
@export var scrollSpeed: float   = 400.0 ## Pixels per second

## The amount to multiply each input axis with. 0 = axis disabled. Negative values = inverted scrolling.
## TIP: May be used to disable horizontal scrolling etc.
## ALERT: Fractional values may not work correctly; must be whole integers.
@export var scrollScale: Vector2 = Vector2.ONE
#endregion


#region State
var isScrolling: bool = false:
	set(newValue):
		if newValue != isScrolling:
			isScrolling = newValue
			self.set_process(isScrolling)

var scrollDirection: Vector2
#endregion


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		self.scrollDirection = Input.get_vector(
			GlobalInput.Actions.aimLeft,
			GlobalInput.Actions.aimRight,
			GlobalInput.Actions.aimUp,
			GlobalInput.Actions.aimDown)
		self.isScrolling = not self.scrollDirection.is_zero_approx()


func _process(delta: float) -> void:
	self.scroll_horizontal	+= int(scrollDirection.x * scrollScale.x * scrollSpeed * delta)
	self.scroll_vertical	+= int(scrollDirection.y * scrollScale.y * scrollSpeed * delta)
