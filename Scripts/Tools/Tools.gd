## Helper functions for built-in Godot nodes and types to assist with common tasks.
## Most of this is stuff that should be built-in Godot but isn't :')
## and can't be injected into the base types such as Node etc. because GDScript doesn't have a feature like Swift's "extension" :(
## In the future, these functions & types may be incorporated into the builtin Godot API as native code or via custom extensions.

class_name Tools
extends GDScript


#region Constants

## The cardinal & ordinal directions, each assigned a number representing the associated rotation angle in degrees, with East = 0 and incrementing by 45
enum CompassDirection {
	# DESIGN: Start from East to match the default rotation angle of 0
	# TBD: Should this be in `Tools.gd` or in `Global.gd`? :')
	none		=  -1,
	east		=   0,
	southEast	=  45,
	south		=  90,
	southWest	= 135,
	west		= 180,
	northWest	= 225,
	north		= 270,
	northEast	= 315
	}

const compassDirectionVectors: Dictionary[CompassDirection, Vector2i] = {
	CompassDirection.none:		Vector2i.ZERO,
	CompassDirection.east:		Vector2i.RIGHT,
	CompassDirection.southEast:	Vector2i(+1, +1),
	CompassDirection.south:		Vector2i.DOWN,
	CompassDirection.southWest:	Vector2i(-1, +1),
	CompassDirection.west:		Vector2i.LEFT,
	CompassDirection.northWest:	Vector2i(-1, -1),
	CompassDirection.north:		Vector2i.UP,
	CompassDirection.northEast:	Vector2i(+1, -1)
	}

const compassDirectionOpposites: Dictionary[CompassDirection, CompassDirection] = {
	CompassDirection.none:		CompassDirection.none,
	CompassDirection.east:		CompassDirection.west,
	CompassDirection.southEast:	CompassDirection.northWest,
	CompassDirection.south:		CompassDirection.north,
	CompassDirection.southWest:	CompassDirection.northEast,
	CompassDirection.west:		CompassDirection.east,
	CompassDirection.northWest:	CompassDirection.southEast,
	CompassDirection.north:		CompassDirection.south,
	CompassDirection.northEast:	CompassDirection.southWest,
	}

## A list of unit vectors representing 8 compass directions.
class CompassVectors:
	# TBD: PERFORMANCE: Replace with `compassDirectionVectors[CompassDirection]` or are these simple `const`ants faster?
	const none		:= Vector2i.ZERO
	const east		:= Vector2i.RIGHT
	const southEast	:= Vector2i(+1, +1)
	const south		:= Vector2i.DOWN
	const southWest	:= Vector2i(-1, +1)
	const west		:= Vector2i.LEFT
	const northWest	:= Vector2i(-1, -1)
	const north		:= Vector2i.UP
	const northEast	:= Vector2i(+1, -1)


enum Shape {
	none,
	circle,
	rectangle, # Wanted to call #2 "square" to match with "²" :')
	triangle
	}


## For use with [method Array.pick_random] with an optional scaling factor.
const plusMinusOneOrZero:		Array[int]	 = [-1, 0, +1] # TBD: Name :')

## For use with [method Array.pick_random] with an optional scaling factor.
const plusMinusOneOrZeroFloat:	Array[float] = [-1.0, 0.0, +1.0] # TBD: Name :')

## For use with [method Array.pick_random] with an optional scaling factor.
const plusMinusOne:				Array[int]	 = [-1, +1] # TBD: Name :')

## For use with [method Array.pick_random] with an optional scaling factor.
const plusMinusOneFloat:		Array[float] = [-1.0, +1.0] # TBD: Name :')

## A sequence of float numbers from -1.0 to +1.0 stepped by 0.1
## TIP: Use [method Array.pick_random] to pick a random variation from this list for colors etc.
const sequenceNegative1toPositive1stepPoint1: Array[float] = [-1.0, -0.9, -0.8, -0.7, -0.6, -0.5, -0.4, -0.3, -0.2, -0.1, 0, +0.1, +0.2, +0.3, +0.4, +0.5, +0.6, +0.7, +0.8, +0.9, +1.0] # TBD: Better name pleawse :')

#endregion


#region Subclasses

## A set of parameters for [method CanvasItem.draw_line]
class Line: # UNUSED: Until Godot can support custom class @export :')
	var start:	Vector2
	var end:	Vector2
	var color:	Color = Color.WHITE
	var width:	float = -1.0 ## A negative means the line will remain a "2-point primitive" i.e. always be a 1-width line regardless of scaling.

#endregion


#region Scene Management
# See SceneManager.gd
#endregion


#region Script Tools

## Connects or reconnects a [Signal] to a [Callable] only if the connection does not already exist, to silence any annoying Godot errors about existing connections (presumably for reference counting).
static func connectSignal(sourceSignal: Signal, targetCallable: Callable, flags: int = 0) -> int:
	if not sourceSignal.is_connected(targetCallable):
		return sourceSignal.connect(targetCallable, flags) # No idea what the return value is for.
	else:
		return 0


## Disconnects a [Signal] from a [Callable] only if the connection actually exists, to silence any annoying Godot errors about missing connections (presumably for reference counting).
static func disconnectSignal(sourceSignal: Signal, targetCallable: Callable) -> void:
	if  sourceSignal.is_connected(targetCallable):
		sourceSignal.disconnect(targetCallable)


## Connects/reconnects OR disconnects a [Signal] from a [Callable] safely, based on the [param reconnect] flag.
## TIP: This saves having to type `if someFlag: connectSignal(…) else: disconnectSignal(…)`
static func toggleSignal(sourceSignal: Signal, targetCallable: Callable, reconnect: bool, flags: int = 0) -> int:
	if reconnect and not sourceSignal.is_connected(targetCallable):
		return sourceSignal.connect(targetCallable, flags) # No idea what the return value is for.
	elif not reconnect and sourceSignal.is_connected(targetCallable):
		sourceSignal.disconnect(targetCallable)
	# else:
	return 0


## A safe wrapper around [method Object.call] or [method Object.callv] that does not crash if the function/method name is missing.
## Returns the result of the call.
## TIP: Useful for passing customizable functions such as dynamically choosing different animations on `Animations.gd`
## ALERT: Does NOT check if [param object] is a valid non-null [Object]
static func callCustom(object: Object, functionName: StringName, ...arguments: Array) -> Variant:
	if object.has_method(functionName):
		return object.callv(functionName, arguments)
	else:
		Debug.printWarning(str("callCustom(): ", object, " invalid or has no such function: " + functionName), object)
		return null


## Returns a [StringName] with the `class_name` from a [Script] type.
## NOTE: This method is needed because we cannot directly write `SomeTypeName.get_global_name()` :(
static func getStringNameFromClass(type: Script) -> StringName:
	return type.get_global_name()


## Checks whether a script has a function/method with the specified name.
## NOTE: Only checks for the name, NOT the arguments or return type.
## ALERT: Use the EXACT SAME CASE as the method you need to find!
static func findMethodInScript(script: Script, methodName: StringName) -> bool: # TBD: Should it be [StringName]?
	# TODO: A variant or option to check for multiple methods.
	# TODO: Check arguments and return type.
	var methodDictionary: Array[Dictionary] = script.get_script_method_list()
	for method in methodDictionary:
		# DEBUG: Debug.printDebug(str("findMethodInScript() script: ", script, " searching: ", method))
		if method["name"] == methodName: return true
	return false

#endregion


#region Node Management
# See NodeTools.gd
#endregion


#region NodePath Functions

## Convert a [NodePath] from the `./` form to the absolute representation: `/root/` INCLUDING the property path if any.
static func convertRelativeNodePathToAbsolute(parentNodeToConvertFrom: Node, relativePath: NodePath) -> NodePath:
	var absoluteNodePath: NodePath = parentNodeToConvertFrom.get_node(relativePath).get_path()
	var subnames:		  String   = relativePath.get_concatenated_subnames()

	# DEBUG:
	# Debug.printLog(str("Tools.convertRelativeNodePathToAbsolute() parentNodeToConvertFrom: ", parentNodeToConvertFrom, \
		#", relativePath: ", relativePath, \
		#", absoluteNodePath: ", absoluteNodePath, \
		#", propertyPath: ", propertyPath))

	if subnames.is_empty(): return absoluteNodePath
	else: return NodePath(str(absoluteNodePath, ":", subnames))


## Splits a [NodePath] into an Array of 2 paths where index [0] is the node's path and [1] is the property chain, e.g. `/root:size:x` → [`/root`, `:size:x`]
static func splitPathIntoNodeAndProperty(path: NodePath) -> Array[NodePath]:
	var nodePath:	  NodePath	= NodePath(str("/" if path.is_absolute() else "", path.get_concatenated_names()))
	var subnames:	  String	= path.get_concatenated_subnames()
	var propertyPath: NodePath	= NodePath(str(":", subnames)) if not subnames.is_empty() else NodePath() # Avoid an invalid trailing `:` if there is no property
	return [nodePath, propertyPath]

#endregion


#region Geometry Functions
# For Area2D: See AreaTools.gd
# For CollisionObject2D/CollisionShape2D: See CollisionTools.gd
# For Rect2/Rect2i: See RectTools.gd

## Returns a COPY of a [Vector2i] moved in the specified [enum CompassDirection]
static func offsetVectorByCompassDirection(vector: Vector2i, direction: CompassDirection) -> Vector2i:
	return vector + Tools.compassDirectionVectors[direction]

#endregion


#region Physics Functions

## Sets the X and/or Y components of [member CharacterBody2D.velocity] to 0 if the [method CharacterBody2D.get_last_motion()] is 0 in the respective axes.
## This prevents the "glue effect" where if the player keeps inputting a direction while the character is pushed against a wall,
## it will take a noticeable delay to move in the other direction while the velocity gradually changes from the wall's direction to away from the wall.
static func resetBodyVelocityIfZeroMotion(body: CharacterBody2D) -> Vector2:
	var lastMotion: Vector2 = body.get_last_motion()
	if is_zero_approx(lastMotion.x): body.velocity.x = 0
	if is_zero_approx(lastMotion.y): body.velocity.y = 0
	return lastMotion

#endregion


#region Visual Functions

static func addRandomDistance(position: Vector2,    \
minimumDistance: Vector2, maximumDistance: Vector2, \
xScale: float = 1.0, yScale: float = 1.0) -> Vector2:

	var randomizedPosition: Vector2 = position
	randomizedPosition.x += randf_range(minimumDistance.x, maximumDistance.x) * xScale
	randomizedPosition.y += randf_range(minimumDistance.y, maximumDistance.y) * yScale
	return randomizedPosition


## Returns a [Color] with R,G,B each set to a random value "quantized" to steps of 0.25
static func getRandomQuantizedColor() -> Color:
	const steps: Array[float] = [0.25, 0.5, 0.75, 1.0]
	return Color(steps.pick_random(), steps.pick_random(), steps.pick_random())


## Returns the global position of the top-left corner of the screen in the camera's view.
## Handles zoom, rotation, limits etc.
## IMPORTANT: Assumes the [param camera] is the active [Camera2D] for its [Viewport]
static func getScreenTopLeftInCamera(camera: Camera2D) -> Vector2:
	# Convert the viewport-space point into the camera canvas's world coordinates.
	# This uses the actual current canvas transform, so it respects rotation, zoom,
	# smoothing, drag margins, limits, and other camera-driven view changes.
	return camera.get_canvas_transform().affine_inverse() \
		 * camera.get_viewport_rect().position # The viewport's top-left corner in viewport coordinates


## Returns the global position of a specific corner of the screen in the camera's view.
## Handles zoom, rotation, limits etc.
## [param corner] uses normalized viewport coordinates: (0,0) = top-left, (1,1) = bottom-right.
## IMPORTANT: Assumes the [param camera] is the active [Camera2D] for its [Viewport]
static func getScreenCornerInCamera(camera: Camera2D, corner: Vector2) -> Vector2:
	var viewportRect: Rect2 = camera.get_viewport_rect()
	return camera.get_canvas_transform().affine_inverse() \
		* (viewportRect.position + (viewportRect.size * corner))

#endregion


#region Tile Map Functions
# See TileMapTools.gd
#endregion


#region UI Functions

## Creates a new copy of a [Control]'s [StyleBox] to avoid affecting other controls sharing the same StyleBox,
## and sets the specified color on the specified property.
## @experimental
static func setNewStyleBoxColor(control: Control, color: Color, styleBoxName: StringName = &"fill", propertyName: StringName = &"bg_color") -> StyleBox:
	var styleBox: StyleBox = control.get_theme_stylebox(styleBoxName)
	if not styleBox:
		Debug.printWarning(str("Tools.setNewStyleBoxColor(): Cannot get StyleBox: ", styleBoxName), control)
		return null

	if styleBox is StyleBoxFlat:
		var newStyleBox: StyleBox = styleBox.duplicate() # NOTE: Don't want to change the color of ALL controls sharing the same StyleBox!
		newStyleBox.set(propertyName, color)
		control.add_theme_stylebox_override(styleBoxName, newStyleBox)
		return newStyleBox
	else:
		# TBD: Handle other StyleBox variants?
		Debug.printWarning(str("Tools.setNewStyleBoxColor(): Unsupported StyleBox type: ", styleBox), control)
		return null


## Sets the text of [Label]s from a [Dictionary].
## Iterates over an array of [Label]s, and takes the prefix of the node name by removing the "Label" suffix, if any, and making it LOWER CASE,
## and searches the [param dictionary] for any String keys which match the label's name prefix. If there is a match, sets the label's text to the dictionary value for each key.
## Example: `logMessageLabel.text = dictionary["logmessage"]`
## TIP: Use to quickly populate an "inspector" UI with text representing multiple properties of a selected object etc.
## NOTE: The dictionary keys must all be fully LOWER CASE.
static func setLabelsWithDictionary(labels: Array[Label], dictionary: Dictionary[String, Variant], shouldShowPrefix: bool = false, shouldHideEmptyLabels: bool = false) -> void:
	# DESIGN: We don't accept an array of any Control/Node because Labels may be in different containers, and some Labels may not need to be assigned from the Dictionary.
	for label: Label in labels:
		if not label: continue

		var namePrefix:		 String  = label.name.trim_suffix("Label").to_lower()
		var dictionaryValue: Variant = dictionary.get(namePrefix)
		var valueText:		 String

		if dictionary.has(namePrefix): # NOTE: Do NOT check `dictionaryValue` because then values like `0`, `false`, empty strings will be considered non-existent!
			valueText = str(dictionaryValue) if dictionaryValue != null else ""
		else:
			valueText = ""

		label.text  = namePrefix + ":" if shouldShowPrefix else "" # TBD: Space after colon?
		label.text += valueText
		if shouldHideEmptyLabels: label.visible = not valueText.is_empty() # Hides missing keys AND empty/false/zero values. Also automatically shows non-empty labels in case they were hidden before



## Displays non-null values of the specified [Object]'s properties in different [Label]s.
## Each [Label] must have EXACTLY the same case-sensitie name as a matching property in [param object]: `isEnabled` but NOT `IsEnabled` or `EnabledLabel` etc.
## TIP: Example: May be used to quickly display a [Resource] or [Component]'s data in a UI [Container].
## RETURNS: The number of [Label]s with names matching non-null properties of the [param object]
## For a script to attach to a UI [Container], use "PrintPropertiesToLabels.gd"
static func printPropertiesToLabels(object: Object, labels: Array[Label], shouldShowPropertyNames: bool = true, shouldHideNullProperties: bool = true, shouldUnhideAvailableLabels: bool = true) -> int:
	var value: Variant # NOTE: Should not be String so we can explicitly check for `null`
	var matchCount: int = 0

	# Go through all our Labels
	for label in labels:
		# Does the object have a property with a matching name?
		value = object.get(label.name)

		if shouldShowPropertyNames: label.text = label.name + ": "
		else: label.text = ""

		# NOTE: Explicitly check for `null` so values like 0, `false`, and empty strings still count as valid values
		# BUGRISK: Properties that exist but are `null` may be considered as non-existent!
		if value != null:
			label.text += str(value)
			if shouldUnhideAvailableLabels: label.visible = true
			matchCount += 1
		else:
			label.text += "null" if shouldShowPropertyNames else ""
			if shouldHideNullProperties: label.visible = false

	return matchCount

#endregion


#region Text Functions

## Returns an [Enum]'s value along with its key as a text string, e.g. "0 (default)" or "270 (north)"
## TIP: To just get the [Enum] key corresponding to the specified value, use [method Dictionary.find_key]
## WARNING: May NOT work as expected for enums with non-sequential values or starting below 0, or if there are multiple identical values, or if there is a 'null' key.
static func getEnumKey(enumType: Dictionary, value: int) -> String:
	# TBD: Less ambiguous name?
	var key: Variant = enumType.find_key(value) # Variant to allow for `null` because str(Dictionary.find_key()) returns "null" (as text) which doesn't work for checking with String.is_empty()
	if  key == null: key = "[invalid key/value]"
	return str(value, " (", key, ")")


## Iterates over a [String] and replaces all occurrences of text matching the [param substitutions] [Dictionary]'s [method Dictionary.keys] with the values for those keys.
## Example: A Dictionary of { "Apple":"Banana", "Cat":"Dog" } would replace all "Apple" in [param sourceString] with "Banana" and all "Cat" with "Dog".
## NOTE: Does NOT modify the [param sourceString], instead returns a modified string.
static func replaceStrings(sourceString: String, substitutions: Dictionary[String, String]) -> String:
	var modifiedString: String = sourceString
	for key: String in substitutions.keys():
		modifiedString = modifiedString.replace(key, substitutions[key])
	return modifiedString

#endregion


#region Maths Functions

## TIP: To "truncate" the number of decimal points, use Godot's [method @GlobalScope.snappedf] function.

## "Rolls" a random integer number from 1…100 (inclusive) and returns `true` if the result is less than or equal to the specified [param chancePercent].
## i.e. If the chance is 10% then a roll of 1…10 will succeed but 11…100 (90 possibilities) will fail.
static func rollChance(chancePercent: int) -> bool:
	return randi_range(1, 100) <= chancePercent


## Returns a copy of a number wrapped around to the [param minimum] or [param maximum] value if it exceeds or goes below either limit (inclusive).
## May be used to cycle through a range by adding/subtracting an offset to [param current] such as +1 or -1. The number may be an array index or `enum` state, or a sprite position to wrap it around the screen Pac-Man-style.
## If [param minimum] > [param maximum] then [param current] is returned unmodified.
static func wrapInteger(minimum: int, current: int, maximum: int) -> int:
	# NOTE: Cannot use Godot's pingpong() because it "bounces" not "wraps"
	if minimum > maximum:
		Debug.printWarning(str("wrapInteger(): minimum ", minimum, " > maximum ", maximum, ", returning current: ", current))
		return current # TBD: Return `current` or `minimum` or `maximum` in case of invalid arguments??
	elif minimum == maximum: # If there is no difference between the range, just return either.
		return minimum

	# NOTE: Do NOT clamp first! So that an already-offset value may be provided for `current`

	# THANKS: rubenverg@Discord, lololol__@Discord
	return posmod(current - minimum, maximum - minimum + 1) + minimum # +1 to make limits inclusive


## Wraps a [float] value around if it is below 0.0 or higher than 1.0
static func wrapUnitFloat(value: float) -> float:
	if value < 0.0 or value > 1.0: return fposmod(value, 1.0)
	else: return value

#endregion


#region Array Functions

## NOTE: Packed arrays such as [PackedStringArray] etc. are accepted even though [param array] is typed as [Array]
static func validateArrayIndex(array: Array, index: int) -> bool:
	return index >= 0 and index < array.size()


## Takes a [param index] and increments it by the specified amount, wrapping it around to 0 + remainder if it exceeds an [param array]'s size.
## Returns 0 if the array is empty, which will be an invalid index.
## NOTE: Packed arrays such as [PackedStringArray] etc. are accepted even though [param array] is typed as [Array]
static func wrapArrayIndex(array: Array, index: int, increment: int) -> int:
	if not array.is_empty(): return Tools.wrapInteger(0, index + increment, array.size() - 1)
	else: return 0


## Returns a specific number of random unique array indices.
## If [param numberOfIndices] is greater than [param arraySize], the returned count is clamped to [param arraySize]
## PERFORMANCE: Uses a "sparse partial Fisher-Yates shuffle" to only track selected/swapped slots instead of allocating an Array for every possible index.
## TIP: To shuffle an entire Array, use Godot's builtin [method Array.shuffle]
static func pickRandomArrayIndices(arraySize: int, numberOfIndices: int) -> Array[int]:
	# TBD: Add parameter for a custom RandomNumberGenerator?
	if arraySize <= 0 or numberOfIndices <= 0: return []

	var selectedIndexCount:	int = mini(numberOfIndices, arraySize)
	var shuffledIndices:	 Array[int] = []
	shuffledIndices.resize(selectedIndexCount)

	# Store indexes or "slots" for the Fisher-Yates algorithm (each step explained in the loop below)
	# Key:   Logical slot still available to roll
	# Value: Actual index represented by that slot
	var swappedIndices:		 Dictionary[int, int]
	var remainingIndexCount: int = arraySize
	var selectedSlot:		 int
	var selectedIndex:		 int

	for count in selectedIndexCount:
		# 1: Roll one slot from the still available range.
		# Example: [A,B,C,D]: select B
		selectedSlot  = randi_range(0, remainingIndexCount - 1)

		# 2: Resolve that slot to the actual index.
		# Instead of using a list of every possible index, assume that every slot points to itself unless `swappedIndices` says otherwise:
		# If the slot was never swapped (i.e. the key doesn't exist) then it represents itself.
		selectedIndex = swappedIndices.get(selectedSlot, selectedSlot)

		# 3: Remove the selected slot by replacing it with the last available slot.
		# This is the same idea as swapping `selectedSlot` with the end of an array, then shrinking the array by 1.
		# Example: [A,D,C | B]: B selected & "removed" from the "pool" because the `remainingIndexCount` is decreased
		# The Dictionary becomes: swappedIndices[1] = D
		remainingIndexCount -= 1
		swappedIndices[selectedSlot] = swappedIndices.get(remainingIndexCount, remainingIndexCount)

		# 4: The old last slot is now outside the available range, so it can be forgotten.
		# Example: [A,D,C]
		swappedIndices.erase(remainingIndexCount)

		# 5: Build the list of random indices.
		shuffledIndices[count] = selectedIndex

		# 6: On the next pass, [A,D,C] → Select A, swap with C → [C,D | A,B] and so on...

	return shuffledIndices

#endregion


#region File System Functions
# See FileSystemTools.gd
#endregion


#region Miscellaneous Functions

## Checks whether a [Variant] value may be considered a "success", for example the return of a function.
## If [param value] is a [bool], then it is returned as is.
## If the value is a number, `true` is returned even if it's 0, unless it's a `float` NAN (Not A Number).
## If the value is an [Array] or [Dictionary] or a "packed array" type, `true` is returned if it's not empty.
## For all other types, `true` is returned if the value is not `null`
## TIP: Use for verifying whether a [Payload]'s [method executeImplementation] executed successfully.
static func checkResult(value: Variant) -> bool:
	# Because GDScript doesn't have Tuples :')
	if    value is bool:	return value
	elif  value == null:	return false # Check a common case first, even though we fall through to accepting all non-null values in the end
	elif  value is int:		return true  # TBD: Return `true` even if a number is 0?
	elif  value is float:	return not is_nan(value)
	elif  value is Array or value is Dictionary: return not value.is_empty()
	else: 
		# Check for Packed Arrays
		var valueTypeName: String = type_string(typeof(value))
		if    valueTypeName.begins_with("Packed") and valueTypeName.ends_with("Array"): return not value.is_empty()
		elif  value != null: return true # Just in case, even though `null` was checked above
		else: return false


## Stops a [Timer] and emits its [signal Timer.timeout] signal.
## WARNING: This may cause bugs, especially when multiple objects are using `await` to wait for a Timer.
## Returns: The leftover time before the timer was stopped. WARNING: May not be accurate!
static func skipTimer(timer: Timer) -> float:
	# WARNING: This may not be accurate because the Timer is still running until the `stop()` call.
	var leftoverTime: float = timer.time_left
	timer.stop()
	timer.timeout.emit()
	return leftoverTime


## Searches for a [param value] in an [param options] array and if found, returns the next item from the list.
## If [param value] is the last member of the array, then the array's first item is returned.
## If there is only 1 item in the array, then the same value is returned, or `null` if [param value] is not found.
## TIP: May be used to cycle through a list of possible options, such as [42, 69, 420, 666]
## WARNING: The cycle may get "stuck" if there are 2 or more identical values in the list: [a, b, b, c] will always only return the 2nd `b`
static func cycleThroughList(value: Variant, list: Array[Variant]) -> Variant:
	if list.is_empty(): return null # NOTE: Do NOT check `if value` because that will exclude 0, `false` and empty strings etc.!

	var  index: int = list.find(value)
	if   index < 0:					return null		# -1 means `value` not found
	elif list.size() == 1:			return value	# If there's only 1 item, there's nothing else to return
	elif index < list.size() - 1:	return list[index + 1] # Return the next item from the array
	else:							return list[0]	# Wrap around if `value` is at the end of the array


## Resets a [Resource] to its saved default values by reloading its `.tres` file from the project bundle.
## Copies all serialized properties back onto the live instance IN-PLACE,
## preserving all signal connections, [Dictionary] caches, and external references.
## Returns `true` if successful. Returns `false` if the [param resource] has no [member Resource.resource_path] (e.g. if it's an inline Resource inside a `.tscn` scene)
## EXAMPLE: Resetting stats like health, ammo, etc. and other flags etc. when resetting a level after death etc.
## TIP: For a [Stat], this restores the [member Stat.value] to the designer's saved default, which may differ from [member Stat.min] and [member Stat.max]
## ALERT: This is a "shallow" reset that does NOT preserve stored Array, Dictionary, and nested Resource/Object properties within the [param resource]
## ALERT: Property setters WILL fire during the reset, which may emit signals such as [signal Resource.changed]/[signal Stat.didMin]/[signal Stat.didMax]
## @experimental
static func resetResource(resource: Resource) -> bool:
	# TBD: CHECK: Is there a better way?

	if not resource or resource.resource_path.is_empty():
		Debug.printWarning(str("resetResourceToDefaults() Resource: ", resource, " has no resource_path • May be inline/dynamic resource?"), resource)
		return false

	var savedResource: Resource = ResourceLoader.load(resource.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE) # TBD: Use `CACHE_MODE_REPLACE_DEEP`?

	if not savedResource:
		Debug.printWarning("resetResourceToDefaults() ResourceLoader.load failed: " + resource.resource_path, resource)
		return false

	# NOTE: Copy each property, to reset without destroying the existing Resource instance
	# to preserve existing signals etc.
	for property: Dictionary in savedResource.get_property_list():
		if property.usage & PROPERTY_USAGE_STORAGE:
			resource.set(property.name, savedResource.get(property.name))

	return true

#endregion
