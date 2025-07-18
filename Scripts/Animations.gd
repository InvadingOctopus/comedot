## A collection of animations written in code that may be applied to any node.

class_name Animations
extends GDScript

# TODO: Remember ongoing [Tween]s so we can kill or continue them on repeated animation calls?


#region Names
class Names:
	const blink				:= &"blink"
	const overlayFadeIn		:= &"overlayFadeIn"
	const overlayFadeOut	:= &"overlayFadeOut"
#endregion


#region General Animations

## A convenient shortcut for calling [method Node.create_tween()] (which also implicitly calls [method Tween.bind_node]) then [method Tween.tween_property] in a single call.
## Returns: The created [Tween].
static func tweenProperty(node: CanvasItem, property: NodePath, value: Variant, duration: float = 1.0) -> Tween:
	var tween: Tween = node.create_tween()
	tween.tween_property(node, property, value, duration)
	return tween

#endregion


#region Visibility Animations

static func fadeIn(node: CanvasItem, duration: float = 0.5) -> Tween:
	var currentColorWithMaxAlpha: Color = Color(node.modulate, 1.0)
	var tween: Tween = node.create_tween()
	node.visible = true
	tween.tween_property(node, ^"modulate", currentColorWithMaxAlpha, duration) \
		.set_ease(Tween.EASE_OUT) # TBD: .set_trans(Tween.TRANS_CUBIC)
	return tween


static func fadeOut(node: CanvasItem, duration: float = 0.5) -> Tween:
	var currentColorWithZeroAlpha: Color = Color(node.modulate, 0)
	var tween: Tween = node.create_tween()
	tween.tween_property(node, ^"modulate", currentColorWithZeroAlpha, duration) \
		.set_ease(Tween.EASE_OUT) # TBD: .set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, ^"visible", false, 0)
	return tween


## Toggles the [member CanvasItem.visible] flag from the INITIAL state (at the time of calling this function) to the opposite.
## NOTE: If [param initialVisibility] is not specified, the animation ends at the initial visibility state, which may NOT always be visible.
static func blink(node: CanvasItem, loops: int = 3, duration: float = 0.1, initialVisibility: bool = node.visible) -> Tween:
	var tween: Tween = node.create_tween()
	node.visible = initialVisibility
	tween.set_loops(loops)
	tween.tween_property(node, ^"visible", not initialVisibility, duration)
	tween.tween_property(node, ^"visible", initialVisibility, duration)
	return tween

#endregion


#region Label Animations

## Plays different animations on a [Label] depending on how the specified number changes.
## Modifies the [member label.label_settings] if available, otherwise [member label.modulate].
## WARNING: If the [LabelSettings] is not [member Resource.resource_local_to_scene] then ALL the Labels with that Resource will be modified!
static func animateNumberLabel(label: Label, value: Variant, previousValue: Variant, resetToColor: Color = Color.WHITE) -> Tween:
	var color: Color
	const duration: float = 0.25 # TBD: Should this be an argument?

	if    value > previousValue: color = Color.GREEN
	elif  value < previousValue: color = Color.RED
	else: return

	var labelSettings: LabelSettings = label.label_settings
	var tween: Tween = label.create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)

	if labelSettings:
		tween.tween_property(labelSettings, ^"font_color", color, duration)
		tween.tween_property(labelSettings, ^"font_color", resetToColor, duration)
	else:
		tween.tween_property(label, ^"modulate", color, duration)
		tween.tween_property(label, ^"modulate", resetToColor, duration)

	return tween

#endregion


#region Special Animations

static func bubble(node: CanvasItem, distance: Vector2 = Vector2(0, -32), toOpacity: float = 0, duration: float = 1.0) -> Tween:
	var tween: Tween = node.create_tween()
	var targetPosition: Vector2 = node.position + distance # Assume `node` has `position`
	var targetModulate: Color   = Color(node.modulate, toOpacity)
	tween.parallel().tween_property(node, ^"modulate", targetModulate, duration).set_delay(duration / 2) # Delay fading for a while
	tween.parallel().tween_property(node, ^"position", targetPosition, duration).set_ease(Tween.EaseType.EASE_OUT)
	return tween


## Plays different animations on a [NODE] depending on how the specified number changes.
static func modulateNumberDifference(node: CanvasItem, value: Variant, previousValue: Variant, colorForIncrement: Color = Color.GREEN, colorForDecrement: Color = Color.RED) -> Tween:
	var color: Color
	const duration: float = 0.25 # TBD: Should this be an argument?

	if    value > previousValue: color = colorForIncrement
	elif  value < previousValue: color = colorForDecrement
	else: return

	var previousColor: Color = Color.WHITE # TODO: A better way to reset a property: Using the current `modulate` won't work if called during another animation.
	var tween: Tween = node.create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(node, ^"modulate", color, duration)
	tween.tween_property(node, ^"modulate", previousColor, duration)

	return tween

#endregion
