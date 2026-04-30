## Helper functions to assist with common tasks involving [Area2D]
## In the future, these functions & types may be incorporated into the builtin Godot API as native code or via custom extensions.

class_name AreaTools
extends GDScript # NOTE: DESIGN: We cannot `extends Area2D` because we want these functions to be global, not just for instances of a special subclass.


#region Geometry

## Returns a random point inside the combined rectangular boundary of ALL an [Area2D]'s [Shape2D]s.
## On failure, i.e. if the area has an invalid size, returns (0,0)
## NOTE: Does NOT verify whether a point is actually enclosed inside a [Shape2D]
## Best suited for areas with a single [RectangleShape2D]
static func getRandomPositionInArea(area: Area2D) -> Vector2:
	var areaBounds: Rect2 = CollisionTools.getAllShapeBounds(area)

	if not areaBounds.has_area(): return Vector2.ZERO

	# Generate a random position within the area.

	#randomize() # TBD: Do we need this?

	#var isWithinArea: bool = false
	#while not isWithinArea:

	var x: float = randf_range(areaBounds.position.x, areaBounds.end.x)
	var y: float = randf_range(areaBounds.position.y, areaBounds.end.y)
	var randomPosition: Vector2 = Vector2(x, y)

	#if shouldVerifyWithinArea: isWithinArea = ... # TODO: Cannot check if a point is within an area :( [as of 4.3 Dev 3]
	#else: isWithinArea = true

	# DEBUG: Debug.printDebug(str("area: ", area, ", areaBounds: ", areaBounds, ", randomPosition: ", randomPosition))
	return randomPosition


## Checks a list of [Area2D]s and returns the area nearest to a specified reference area.
## The [param comparedAreas] would usually be static "zones" and the [param referenceArea] may be the bounds of a player Entity or another character etc.
## NOTE: If 2 different [Area2D]s are at the same distance from [param referenceArea] then the one on top i.e. with the higher [member CanvasItem.z_index] will be used.
static func findNearestArea(referenceArea: Area2D, comparedAreas: Array[Area2D]) -> Area2D:
	# TBD: PERFORMANCE: Option to cache results?

	# DESIGN: PERFORMANCE: Cannot use RectTools.findNearestRect() because that would require calling CollisionTools.getShapeGlobalBounds() on all areas beforehand,
	# and there is a separate tie-break based on the Z index, so there has to be some code dpulication :')

	var nearestArea:	Area2D = null # Initialize with `null` to avoid the "used before assigning a value" warning
	var minimumDistance: float = INF  # Start with infinity

	var referenceAreaBounds: Rect2 = CollisionTools.getShapeGlobalBounds(referenceArea)
	var comparedAreaBounds:  Rect2

	# TBD: PERFORMANCE: All these variables could be replaced by directly accessing Rect2.position & Rect2.end etc. but these names may make the code easier to read and understand.

	var referenceLeft:	float = referenceAreaBounds.position.x
	var referenceRight:	float = referenceAreaBounds.end.x
	var referenceTop:	float = referenceAreaBounds.position.y
	var referenceBottom:float = referenceAreaBounds.end.y

	var comparedLeft:	float
	var comparedRight:	float
	var comparedTop:	float
	var comparedBottom:	float

	var gap:			Vector2 # The pixels between the area edges
	var distance:		float	# The Euclidean distance between edges

	for comparedArea: Area2D in comparedAreas:
		if comparedArea == referenceArea: continue

		comparedAreaBounds = CollisionTools.getShapeGlobalBounds(comparedArea)
		if not comparedAreaBounds.abs().has_area(): continue # Skip area if it doesn't have an area!

		# If both regions are exactly the same position & size,
		# or either of them completely contain the other, then you can't get any nearer than that!
		if comparedAreaBounds.is_equal_approx(referenceAreaBounds) \
		or comparedAreaBounds.encloses(referenceAreaBounds) or referenceAreaBounds.encloses(comparedAreaBounds):
			# Is this the first overlapping area? (i.e. the minimum distance is not already 0)
			# or is it another overlapping area visually on top (with a higher Z index) of a previous overlapping area?
			if not is_zero_approx(minimumDistance) \
			or (nearestArea and comparedArea.z_index > nearestArea.z_index):
				minimumDistance = 0
				nearestArea = comparedArea
			continue # NOTE: Do NOT `break` the loop here! Keep checking for multiple overlapping areas to choose the one with the highest Z index.

		# Simplify names
		comparedLeft	= comparedAreaBounds.position.x
		comparedRight	= comparedAreaBounds.end.x
		comparedTop		= comparedAreaBounds.position.y
		comparedBottom	= comparedAreaBounds.end.y
		gap				= Vector2.ZERO # Gaps will default to 0 if the edges are touching

		# Compute horizontal gap
		if   referenceRight < comparedLeft:  gap.x = comparedLeft  - referenceRight	# Primary to the left of Compared?
		elif comparedRight  < referenceLeft: gap.x = referenceLeft - comparedRight	# or to the right?

		# Compute vertical gap
		if   referenceBottom < comparedTop:	 gap.y = comparedTop  - referenceBottom	# Primary above Compared?
		elif comparedBottom  < referenceTop: gap.y = referenceTop - comparedBottom	# or below?

		# Get the Euclidean distance between edges
		distance = sqrt(gap.x * gap.x + gap.y * gap.y)

		# We have a nearer `nearestArea` if this is a new minimum
		if  distance < minimumDistance:
			minimumDistance = distance
			nearestArea = comparedArea

		# If 2 different [Area2D]s have the same distance,
		# use the one that is visually on top of the other: with a higher Z index
		elif is_equal_approx(distance, minimumDistance) \
		and nearestArea and comparedArea.z_index > nearestArea.z_index:
			nearestArea = comparedArea
		# TBD: Otherwise, keep the first area.

	return nearestArea

#endregion