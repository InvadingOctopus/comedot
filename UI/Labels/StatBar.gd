## A variant of a [StatLabel] combined with a [ProgressBar].

class_name StatBar
extends StatLabel

# TODO: Constant animation duration, independent of value difference?


#region Parameters
@export var animationDuration: float = 0.25
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
	updateStatText()
	updateBar()


func updateUI(animate: bool = self.shouldAnimate) -> void:
	super.updateUI(animate)
	
	bar.min_value = stat.min
	bar.max_value = stat.max
	updateBar(animate)


func updateBar(animate: bool = self.shouldAnimate) -> void:
	if animate:
		if tween: tween.kill()
		tween = bar.create_tween()
		tween.tween_property(bar, "value", stat.value, animationDuration)
	else:
		bar.value = stat.value