## Stores data for arbitrary (X,Y) coordinates, as a [Dictionary] structure of the form: `{ 2D Array Index/Coordinates : Value }`
## May be used for building maps and other grid-like structures with "dynamic" or "lazily" generated content.

class_name GridDictionary
extends Resource


#region Parameters & State
## A [Dictionary] representing a grid: `{Coordinates : Value}`
## Each (x,y) [Vector2i] coordinate key contains an arbitrary value.
## TIP: A value may ITSELF also be a [Dictionary] that contains multiple "keys" with different values, such as whether a map cell is traversable or not, which Entity is occupying it and etc.
@export var cellData: Dictionary[Vector2i, Variant] # Example: `= { Vector2i(0, 0): null }`

@export var debugMode: bool = false
#endregion


func setCellData(x: int, y: int, value: Variant) -> void:
	var coordinates: Vector2i = Vector2i(x, y)
	if debugMode: # Log whether replacing an existing cell or writing for the first time
		if cellData.has(coordinates): Debug.printTrace([str("@", coordinates, ": ", cellData[coordinates], " → ", value)], self)
		else: Debug.printTrace([str("@", coordinates, " = ", value)], self)
	cellData[coordinates] = value


## ALERT: Make sure the cell exists by callig [method hasCell] first! Otherwise a missing cell will also return `null`, which is indistinguishable from a cell that exists but has `null` as its data! 
func getCellData(x: int, y: int) -> Variant:
	var coordinates: Vector2i = Vector2i(x, y)
	var value: Variant = cellData.get(coordinates)
	if debugMode:
		if cellData.has(coordinates): Debug.printDebug(str("getCellData() @", coordinates, ": ", value), self)
		else: Debug.printDebug(str("getCellData() @", coordinates, ": cellData has no such key!"), self)
	return value


## Returns whether a "cell" has been set with data, even if it's `null`
## which is different from the cell never having been set i.e. the [member cellData] never having such a [Vector2i] key.
func hasCell(x: int, y: int) -> bool:
	return cellData.has(Vector2i(x, y))


## Deletes the key for the corresponding [Vector2i] cell from the [member cellData]
## Returns `true` if the cell previously existed, or `false` if the [member cellData] did not have a matching [Vector2i] key.
func eraseCell(x: int, y: int) -> bool:
	return cellData.erase(Vector2i(x, y))
