## A variant of [StatLabel] that shows multiple "pips"/symbols to represent a [Stat]'s [member Stat.value].
## For example, a series of heart symbols to represent the number of a player's lives.
## TIP: Optimal for [Stat]s with a small [member Stat.max] number, such as 5-10.

class_name StatPips
extends StatLabel


#region Parameters

## The symbol to repeat for each unit in a [Stat]'s [member Stat.value], such as a heart for a player's remaining lives.
@export var symbol: Texture2D

## An optional symbol to repeat for each unit above a [Stat]'s [member Stat.value] up to its [member Stat.max], such as a hollow heart outline for the lives lost.
@export var depletedSymbol: Texture2D

#endregion


#region State
@onready var pips: Container = $Pips
@onready var availablePips: TextureRect = $Pips/AvailablePips
@onready var depletedPips:  TextureRect = $Pips/DepletedPips

var symbolWidth: float
var depletedSymbolWidth: float

var tween: Tween
#endregion


func arrangeControls() -> void:
	if not shouldShowIconAfterText:
		self.move_child(icon,  0)
		self.move_child(pips,   1)
		self.move_child(label, 2)
	else:
		self.move_child(label, 0)
		self.move_child(pips,  1)
		self.move_child(icon,  2)


func onStat_changed() -> void:
	updateStatText()
	updatePips()


func updateUI(animate: bool = self.shouldAnimate) -> void:
	setPipTextures()
	super.updateUI(animate)
	updatePips(animate)


func setPipTextures() -> void:
	availablePips.texture = symbol
	availablePips.visible = true
	symbolWidth = symbol.get_width()
	
	depletedPips.texture  = depletedSymbol
	depletedSymbolWidth   = depletedSymbol.get_width()


func updatePips(_animate: bool = self.shouldAnimate) -> void:
	# TODO: animate

	# The remaining pips
	
	var value: int = stat.value

	if symbol != null and value > 0:
		var availablePipsNodeWidth: float   = symbolWidth * value
		availablePips.custom_minimum_size.x = availablePipsNodeWidth
		availablePips.visible = true
	else:
		availablePips.visible = false
	
	# The depleted pips

	var depletedValue: int = (stat.max - value)

	if depletedSymbol != null and depletedValue > 0:
		var depletedPipsNodeWidth: float   = depletedSymbolWidth * depletedValue
		depletedPips.custom_minimum_size.x = depletedPipsNodeWidth
		depletedPips.visible = true
	else:
		depletedPips.visible = false