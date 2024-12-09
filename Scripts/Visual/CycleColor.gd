## Modifies the HSV components of the [member CanvasItem.modulate] color every frame.
## Wraps around at 0.0 and 1.0. If the node is a [Light2D] or subclass, then [member Light2D.color] is modified.
## WARNING: The [member CanvasItem.Modulate] property of the node MUST be set in the Godot Editor, otherwise this script will not be able to get the initial HSV components!
## WARNING: If the [member CanvasItem.Modulate] saturation component "s" is 0 or very low then the hue component "h" may have NO visible effect.

extends CanvasItem


# TODO: Option for cycle/wrap-around


#region Parameters

## The initial "H" component of the Modulate color's HSV.
#@export_range(0.0, 1.0, 0.01) var initialHue: float = 0.0

## Modifies the "H" component of the Modulate color's HSV every frame, cycling within 0.0 to 1.0
@export_range(-1.0, 1.0, 0.01) var hueModifier: float = 0.2

## The initial "S" component of the Modulate color's HSV.
## NOTE: If this is 0 or very low then the hue component "H" may have NO visible effect.
#@export_range(0.0, 1.0, 0.01) var initialSaturation: float = 1.0

## Modifies the "S" component of the Modulate color's HSV every frame, cycling within 0.0 to 1.0
@export_range(-1.0, 1.0, 0.01) var saturationModifier: float = 0.0

## The initial "V" component of the Modulate color's HSV (basically the brightness).
#@export_range(0.0, 1.0, 0.01) var initialValue: float = 1.0

## Modifies the "V" component of the Modulate color's HSV every frame, cycling within 0.0 to 1.0
@export_range(-1.0, 1.0, 0.01) var valueModifier: float = 0.0

## The initial alpha translucency of the Modulate color.
#@export_range(0.0, 1.0, 0.01) var initialAlpha: float = 1.0

## Modifies the alpha translucency every frame, cycling within 0.0 to 1.0
@export_range(-1.0, 1.0, 0.01) var alphaModifier: float = 0.0

## Sets the initial saturation to 1.0 if it is 0
## As a low saturation will not let the hue have any visible effect.
@export var fixSaturationIfZero: bool = true

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue
		if not isEnabled: modulate = Color.WHITE

#endregion


#region State
var hue:		float
var saturation:	float
var value:		float
var alpha:		float
#endregion


func _ready() -> void:
	## WARNING: The [member CanvasItem.Modulate] property of the node MUST be set in the Godot Editor, otherwise this script will not be able to get the initial HSV components!
	## NOTE: DESIGN: Why not provide initial values within this script? Because then it may not match what we see in the Godot Editor.

	# If the initial saturation is 0 then set it to 1.0
	# because hue will not have any effect otherwise.

	if fixSaturationIfZero and is_zero_approx(modulate.s):
		modulate.s = 1.0

	# Set the initial color

	hue			= modulate.h
	saturation	= modulate.s
	value		= modulate.v
	alpha		= modulate.a

	# Reset if not enabled
	if not isEnabled: modulate = Color.WHITE

	#Debug.printDebug(str("modulate: ", modulate, " h: ", modulate.h, ", s: ", modulate.s, ", v: ", modulate.v, ", a: ", modulate.a), self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not isEnabled: return

	# Cycle the values within 0.0 and 1.0

	# NOTE: Apparently setting [Color.from_hsv()] automatically modulates by 1.0
	# BUG: But ONLY IF the value is POSITIVE!
	# WORKAROUND: So we have to manually wrap the values around from 1.0 if a modifier is negative

	# TBD: Should we use `fmod()` or would `< 0` be more efficient and immune to floating errors?

	# H

	hue += hueModifier * delta
	if signf(hue) < 0: hue = 1.0 - hue

	# S

	saturation += saturationModifier * delta
	if signf(saturation) < 0: saturation = 1.0 - saturation

	# V

	value += valueModifier * delta
	if signf(value) < 0: value = 1.0 - value

	# Alpha

	alpha += alphaModifier * delta
	if signf(alpha) < 0: alpha = 1.0 - alpha

	# Apply

	var colorToApply: Color = Color.from_hsv(hue, saturation, value, alpha)
	#Debug.printDebug(str("modulate: ", modulate, " h: ", modulate.h, ", s: ", modulate.s, ", v: ", modulate.v, ", a: ", modulate.a), self)

	if is_instance_of(self, Light2D): self.color = colorToApply
	else: self.modulate = colorToApply

	# DEBUG

	#Debug.watchList.cycleColor = str(self)
	#Debug.watchList.h = hue
	#Debug.watchList.hModifier = (hueModifier * delta)
	#Debug.watchList.s = saturation
	#Debug.watchList.v = value
	#Debug.watchList.a = alpha
	#Debug.watchList.modulate  = self.modulate
	#Debug.watchList.modulateH = self.modulate.h
	#Debug.watchList.modulateS = self.modulate.s
	#Debug.watchList.modulateV = self.modulate.v
