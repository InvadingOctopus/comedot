## Helper functions to assist with common tasks involving rectangles: [Rect2] or [Rect2i]

class_name RectTools
extends GDScript # NOTE: DESIGN: We cannot `extends Rect2` because we want these functions to be global and also available for [Rect2i], not just for instances of a special subclass.


#region Constants
# Because Dumbdot doesn't have Rect2.ZERO etc.
const rect2Zero:	Rect2  = Rect2 ( Vector2.ZERO,  Vector2.ZERO)
const rect2iZero: 	Rect2i = Rect2i(Vector2i.ZERO, Vector2i.ZERO)
#endregion


#region Geometry

static func getRectCorner(rectangle: Rect2, compassDirection: Vector2i) -> Vector2:
	var position:	Vector2 = rectangle.position
	var center:		Vector2 = rectangle.get_center()
	var end:		Vector2 = rectangle.end

	match compassDirection:
		Tools.CompassVectors.northWest:	return Vector2(position.x,	position.y)
		Tools.CompassVectors.north:		return Vector2(center.x,	position.y)
		Tools.CompassVectors.northEast:	return Vector2(end.x,		position.y)
		Tools.CompassVectors.east:		return Vector2(end.x,		center.y)
		Tools.CompassVectors.southEast:	return Vector2(end.x,		end.y)
		Tools.CompassVectors.south:		return Vector2(center.x,	end.y)
		Tools.CompassVectors.southWest:	return Vector2(position.x,	end.y)
		Tools.CompassVectors.west:		return Vector2(position.x,	center.y)

		_: return Vector2.ZERO


## Returns a [Vector2] representing the distance by which an [intended] inner/"contained" [Rect2] is outside of an outer/"container" [Rect2], e.g. a player's [ClimbComponent] in relation to a Climbable [Area2D] "ladder" etc.
## TIP: To put the inner rectangle back inside the container rectangle, SUBTRACT (or add the negative of) the returned offset from the [param containedRect]'s [member Rect2.position] (or from the position of the Entity it represents).
## WARNING: Does NOT include rotation or scaling etc.
## Returns: The offset/displacement by which the [param containedRect] is outside the bounds of the [param containerRect].
## Negative -X values mean to the left, +X means to the right. -Y means jutting upwards, +Y means downwards.
## (0,0) if the [param containedRect] is completely inside the [param containerRect].
static func getRectOffsetOutsideContainer(containedRect: Rect2, containerRect: Rect2) -> Vector2:
	# If the container completely encloses the containee, no need to do anything.
	if containerRect.encloses(containedRect): return Vector2.ZERO

	var displacement: Vector2

	# Out to the left?
	if containedRect.position.x < containerRect.position.x:
		displacement.x = containedRect.position.x - containerRect.position.x # Negative if the containee's left edge is further left
	# Out to the right?
	elif containedRect.end.x > containerRect.end.x:
		displacement.x = containedRect.end.x - containerRect.end.x # Positive if the containee's right edge is further right

	# Out over the top?
	if containedRect.position.y < containerRect.position.y:
		displacement.y = containedRect.position.y - containerRect.position.y # Negative if the containee's top is higher
	# Out under the bottom?
	elif containedRect.end.y > containerRect.end.y:
		displacement.y = containedRect.end.y - containerRect.end.y # Positive if the containee's bottom is lower

	return displacement


## Checks a list of [Rect2]s and returns the rectangle nearest to a specified reference rectangle.
## The [param comparedRects] would usually represent static "zones" and the [param referenceRect] may be the bounds of a player Entity or another character etc.
static func findNearestRect(referenceRect: Rect2, comparedRects: Array[Rect2]) -> Rect2:
	# TBD: PERFORMANCE: Option to cache results?

	var nearestRect:	 Rect2
	var minimumDistance: float = INF # Start with infinity

	# TBD: PERFORMANCE: All these variables could be replaced by directly accessing Rect2.position & Rect2.end etc. but these names may make the code easier to read and understand.

	var referenceLeft:	float = referenceRect.position.x
	var referenceRight:	float = referenceRect.end.x
	var referenceTop:	float = referenceRect.position.y
	var referenceBottom:float = referenceRect.end.y

	var comparedLeft:	float
	var comparedRight:	float
	var comparedTop:	float
	var comparedBottom:	float

	var gap:			Vector2 # The pixels between the area edges
	var distance:		float	# The Euclidean distance between edges

	for comparedRect: Rect2 in comparedRects:
		if not comparedRect.abs().has_area(): continue # Skip rect if it doesn't have an area

		# If both regions are exactly the same position & size,
		# or either of them completely contain the other, then you can't get any nearer than that!
		if comparedRect.is_equal_approx(referenceRect) \
		or comparedRect.encloses(referenceRect) or referenceRect.encloses(comparedRect):
			minimumDistance = 0
			nearestRect = comparedRect
			break

		# Simplify names
		comparedLeft	= comparedRect.position.x
		comparedRight	= comparedRect.end.x
		comparedTop		= comparedRect.position.y
		comparedBottom	= comparedRect.end.y
		gap				= Vector2.ZERO # Gaps will default to 0 if the edges are touching

		# Compute horizontal gap
		if   referenceRight < comparedLeft:  gap.x = comparedLeft  - referenceRight	# Primary to the left of Compared?
		elif comparedRight  < referenceLeft: gap.x = referenceLeft - comparedRight	# or to the right?

		# Compute vertical gap
		if   referenceBottom < comparedTop:	 gap.y = comparedTop  - referenceBottom	# Primary above Compared?
		elif comparedBottom  < referenceTop: gap.y = referenceTop - comparedBottom	# or below?

		# Get the Euclidean distance between edges
		distance = sqrt(gap.x * gap.x + gap.y * gap.y)

		# We have a nearer `nearestRect` if this is a new minimum
		if  distance < minimumDistance:
			minimumDistance = distance
			nearestRect = comparedRect

	return nearestRect

#endregion