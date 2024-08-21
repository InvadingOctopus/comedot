## A collection of animations written in code that may be applied to any node.

class_name Animations
extends Node


#region Names

const overlayFadeIn		:= &"overlayFadeIn"
const overlayFadeOut	:= &"overlayFadeOut"

const blink				:= &"blink"

#endregion


#region Label Animations

## Plays different animations on a [Label] depending on how the specified number changes.
static func animateNumberLabel(label: Label, value: Variant, previousValue: Variant) -> void:
	var color: Color
	const duration: float = 0.25 # TBD: Should this be an argument?

	if    value > previousValue: color = Color.GREEN
	elif  value < previousValue: color = Color.RED
	else: return

	var defaultColor: Color = Color.WHITE # TODO: CHECK: A better way to reset a property.

	var tween: Tween = label.get_tree().create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate", color, duration)
	tween.tween_property(label, "modulate", defaultColor, duration)

#endregion


