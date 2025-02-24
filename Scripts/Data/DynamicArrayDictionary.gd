## Stores data for arbitrary (X,Y) coordinates, as a Dictionary of the form: `{ 2D Array Index/Coordinates : Value }`
## May be used for building maps and other grid-like structures with "dynamic" or "lazily" generated content.

class_name DynamicArrayDictionary
extends Node


#region Parameters & State
## A Dictionary representing a grid: `{Coordinates : Value}`
## Each (x,y) [Vector2i] coordinate key contains an arbitrary value.
@export var gridDictionary: Dictionary[Vector2i, Variant] = { Vector2i(0, 0): null }

@export var debugMode: bool = false
#endregion


func setCellData(x: int, y: int, value: Variant) -> void:
	var coordinates: Vector2i = Vector2i(x, y)
	if debugMode: Debug.printDebug(str("setCellData() @", coordinates, " = ", value), self)
	gridDictionary[coordinates] = value


func getCellData(x: int, y: int) -> Variant:
	var coordinates: Vector2i = Vector2i(x, y)
	var value: Variant = gridDictionary.get(coordinates)
	if debugMode: Debug.printDebug(str("getCellData() @", coordinates, ": ", value), self)
	return value
