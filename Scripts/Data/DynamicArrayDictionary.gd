## Stores data for arbitrary (X,Y) coordinates, as a [Dictionary] structure of the form: `{ 2D Array Index/Coordinates : Value }`
## May be used for building maps and other grid-like structures with "dynamic" or "lazily" generated content.

class_name DynamicArrayDictionary
extends Resource


#region Parameters & State
## A [Dictionary] representing a grid: `{Coordinates : Value}`
## Each (x,y) [Vector2i] coordinate key contains an arbitrary value.
## TIP: A value may ITSELF also be a [Dictionary] that contains multiple "keys" with different values, such as whether a map cell is traversable or not, which Entity is occupying it and etc.
@export var gridDictionary: Dictionary[Vector2i, Variant] = { Vector2i(0, 0): null }

@export var debugMode: bool = false
#endregion


func setCellData(x: int, y: int, value: Variant) -> void:
	var coordinates: Vector2i = Vector2i(x, y)
	if debugMode:
		var existingValue: Variant = gridDictionary.get(coordinates)
		if existingValue: Debug.printTrace([str("@", coordinates, ": ", existingValue, " → ", value)], self)
		else: Debug.printTrace([str("@", coordinates, " = ", value)], self)
	gridDictionary[coordinates] = value


func getCellData(x: int, y: int) -> Variant:
	var coordinates: Vector2i = Vector2i(x, y)
	var value: Variant = gridDictionary.get(coordinates)
	if debugMode: Debug.printDebug(str("getCellData() @", coordinates, ": ", value), self)
	return value
