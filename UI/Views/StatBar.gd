## A variant of a [StatUI] combined with a [ProgressBar].
## TIP: For smoother animations instead of integer-only steps, set the [member Range.step] property of the [ProgressBar] to a fractional value like 0.1
## TIP: For [Stats] with a small range of values like the player's lives, consider [StatPips]
## ALERT: By default, the [member ProgressBar.step] is 1.0 so that it only shows exact integer values,
## but that may cause choppy animation if the maximum value is small and the bar is too long. To fix, set the step to 0.1

class_name StatBar
extends StatUI

# TODO: Constant animation duration, independent of value difference?


#region Parameters
@export var animationDuration: float = 0.25
@export var barColor:		   Color = Color.WHITE
@export var shouldAnimateBar:	bool = true
#endregion


#region State
@onready var bar: ProgressBar = $Bar
var tween: Tween
#endregion


func arrangeControls() -> void:
	if not shouldShowIconAfterText:
		self.move_child(icon,  0)
		self.move_child(bar,   1)
		self.move_child(label, 2)
	else:
		self.move_child(label, 0)
		self.move_child(bar,   1)
		self.move_child(icon,  2)


func onStat_changed() -> void:
	updateText()
	updateBar()


func updateUI(animate: bool = self.shouldAnimate) -> void:
	super.updateUI(animate)
	Tools.setNewStyleBoxColor(bar, barColor, &"fill", &"bg_color")
	bar.min_value = stat.min
	bar.max_value = stat.max
	updateBar(animate)


func updateBar(animate: bool = self.shouldAnimate) -> void:
	if animate:
		if tween: tween.kill()
		tween = bar.create_tween()
		tween.tween_property(bar, "value", stat.value, animationDuration)
		# TODO: Find a way to animate the StyleBox color instead of using `modulate` which does not display red/green properly on certain bar colors like blue etc.
		# JANK: if shouldAnimateBar: Animations.modulateNumberDifference(bar, stat.value, stat.previousValue)
	else:
		bar.value = stat.value
