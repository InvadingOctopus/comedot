## A collection of animations written in code that may be applied to any node.

class_name Animations
extends Node


#region Names

const overlayFadeIn		:= &"overlayFadeIn"
const overlayFadeOut	:= &"overlayFadeOut"

const blink				:= &"blink"

#endregion


#region General Animations

## A convenient shortcut for calling [method Node.create_tween()] (which also implicitly calls [method Tween.bind_node]) then [method Tween.tween_property] in a single call.
## Returns: The created [Tween].
static func tweenProperty(node: Node, property: NodePath, value: Variant, duration: float = 1.0) -> Tween:
	var tween: Tween = node.create_tween()
	tween.tween_property(node, property, value, duration)
	return tween


static func blinkNode(node: Node2D, loops: int = 3, duration: float = 0.1) -> Tween:
	var tween: Tween = node.create_tween()
	tween.set_loops(loops)
	tween.tween_property(node, "visible", false, duration)
	tween.tween_property(node, "visible", true,  duration)
	return tween

#endregion


#region Label Animations

## Plays different animations on a [Label] depending on how the specified number changes.
static func animateNumberLabel(label: Label, value: Variant, previousValue: Variant) -> Tween:
	var color: Color
	const duration: float = 0.25 # TBD: Should this be an argument?

	if    value > previousValue: color = Color.GREEN
	elif  value < previousValue: color = Color.RED
	else: return

	var defaultColor: Color = Color.WHITE # TODO: CHECK: A better way to reset a property.

	var tween: Tween = label.create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate", color, duration)
	tween.tween_property(label, "modulate", defaultColor, duration)

	return tween

#endregion


