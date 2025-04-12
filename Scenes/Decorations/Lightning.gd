## A basic lightning flash effect.
## @experimental

class_name Lightning
extends Node2D


#region Parameters

@export var lightningChance: float = 0.5
@export var isEnabled:		 bool = true

@export_group("CanvasModulate")
@export var canvasModulate: CanvasModulate
@export var canvasCustomDefaultColor:		Color = Color(0.5, 0.5, 0.5) ## The color to restore the [member canvasModulate] to after the [member canvasFlashColor]. Overridden by [member setCanvasDefaultColorFromNode]
@export var setCanvasDefaultColorFromNode:	bool = true ## Overrides [member canvasCustomDefaultColor]
@export var canvasFlashColor:				Color = Color(0.8, 0.8, 0.8)

@export_group("Sky")
@export var sky: Node2D ## The node representing the sky background.
@export var skyCustomDefaultColor:	Color = Color(0.5, 0.5, 0.5) ## The color to restore the [member canvasModulate] to after the [member canvasFlashColor]. Overridden by [member setCanvasDefaultColorFromNode]
@export var setSkyDefaultColorFromNode:	 bool = true ## Overrides [member canvasCustomDefaultColor]

#endregion


#region State
var isFlashing: bool = false:
	set(newValue):
		if newValue != isFlashing:
			isFlashing = newValue
			self.set_process(isFlashing)

var canvasDefaultColor: Color
var skyDefaultColor: Color
#endregion


func _ready() -> void:
	if canvasModulate:
		canvasDefaultColor = canvasModulate.color if setCanvasDefaultColorFromNode else canvasCustomDefaultColor
	if sky:
		skyDefaultColor = sky.modulate if setSkyDefaultColorFromNode else skyCustomDefaultColor


func onLightningTimer_timeout() -> void:
	if isEnabled and randf() <= lightningChance:
		strikeLightning()


func strikeLightning() -> void:
	self.visible = true
	isFlashing = true
	flashCanvas()


## The lingering bloom
func flashCanvas() -> void:
	if canvasModulate:
		canvasModulate.color = canvasFlashColor
		Animations.tweenProperty(canvasModulate, ^"color", canvasDefaultColor, 0.25)
	if sky:
		sky.modulate = Color.WHITE
		Animations.tweenProperty(sky, ^"modulate", skyDefaultColor, 0.25)


func _process(_delta: float) -> void:
	if not isEnabled or not isFlashing: return
	
	# Show or hide flash
	if randf() <= 0.5:	 self.visible = true
	elif randf() <= 0.3: self.visible = false

	# End current strike?
	if randf() <= 0.2:
		self.visible = false
		isFlashing = false
		flashCanvas()
