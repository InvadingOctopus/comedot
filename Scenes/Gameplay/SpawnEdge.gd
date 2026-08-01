## Wraps [Spawner]s placed around the screen border.
## Includes a [SpawnPoint] at each of the 8 cardinal+ordinal directions,
## and a [SpawnArea] at each of the 4 screen edges.
## TIP: If this script is attached to a [CanvasLayer], the Spawners will stay fixed at the edges even as the player/camera moves and the map scrolls.
## TIP: Ideal for spawning enemies just outside the view in scrolling shoot-em-ups etc.
## IMPORTANT: To choose scenes to spawn and set other parameters, enable "Editable Children" to access all the underlying [Spawner] child nodes,
## or use a subclass or other script to access the [member SpawnEdge.spawners] list, or control each `%PointX`, `%AreaX` etc. node individually.

class_name SpawnEdge
extends Node


#region Parameters

## The number of pixels away from and outside the screen edge to shift the Spawners by.
@export var padding: int

## The size of each [SpawnArea]'s shorter axis; the height of the N/S areas and the width of the E/W areas.
## TIP: This distance effectively adds a delay to each spawn before it moves into the view onscreen.
@export_range(2, 1024, 2, "or_greater") var areaThickness: int = 32

## The parent node to add the spawned nodes to.
## If `null` and this node is a [CanvasLayer], the [CanvasLayer]'s parent is used.
## ALERT: This sets the [member Spawner.parentOverride] of ALL the [SpawnPoint]s & [SpawnArea]s.
@export var parentOverride: Node

#endregion


#region State

@onready var pointsContainer: Node2D = $Points
@onready var areasContainer:  Node2D = $Areas

## A list of all the [Spawner]s under all the [SpawnPoint]s & [SpawnArea]s
## with the points in clockwise order from NW (0,0) then the areas.
## TIP: The default [Spawner] scripts may be replaced by subclasses such as [SpawnerList] or [SpawnerStack]
var spawners: Array[Spawner]

#endregion


#region Setup

func _enter_tree() -> void:
	spawners = getAllSpawners()
	setSpawnerParents() # Apply our `parentOverride` before the Spawners' _ready()


func _ready() -> void:
	setSpawnerPlacements()


## Returns a list of all the [Spawner]s under all the [SpawnPoint]s & [SpawnArea]s
## with the points in clockwise order from NW (0,0) then the areas.
## TIP: The default [Spawner] scripts may be replaced by subclasses such as [SpawnerList] or [SpawnerStack]
## This is a separate method so it can be called when this script is ready.
## NOTE: Does NOT rebuild [member spawners] in case a script wants to modify either list separately.
func getAllSpawners() -> Array[Spawner]:
	return [
		%PointNW/Spawner, # Start in order from 0,0 clockwise
		%PointN/Spawner,
		%PointNE/Spawner,
		%PointE/Spawner,
		%PointSE/Spawner,
		%PointS/Spawner,
		%PointSW/Spawner,
		%PointW/Spawner,
		%AreaN/Spawner,
		%AreaE/Spawner,
		%AreaS/Spawner,
		%AreaW/Spawner,
		]


func setSpawnerParents() -> void:
	var spawnParent: Node = self.parentOverride
	# If no `parentOverride` is provided and we're a CanvasLayer, use our parent
	if not spawnParent and is_instance_of(self, CanvasLayer):
		spawnParent = self.get_parent()

	if not spawnParent: return

	for spawner: Spawner in self.spawners:
		spawner.parentOverride = spawner.get_path_to(spawnParent)


## Sets the positions of all the [SpawnPoint]s and [SpawnArea]s,
## as well as the sizes of all [SpawnArea]s,
## in relation to the screen/viewport size/resolution.
func setSpawnerPlacements() -> void:
	# Screen dimensions
	var viewportRect:	Rect2	= self.get_viewport().get_visible_rect()
	var screenPadding:	Vector2	= Vector2(self.padding, self.padding)
	var screenMin:		Vector2	= viewportRect.position	- screenPadding
	var screenMax:		Vector2	= viewportRect.end		+ screenPadding
	var screenMid:		Vector2	= viewportRect.position	+ (viewportRect.size / 2.0)

	# Spawn Points
	%PointNW.position = pointsContainer.make_canvas_position_local(Vector2(screenMin.x, screenMin.y))
	%PointN.position  = pointsContainer.make_canvas_position_local(Vector2(screenMid.x, screenMin.y))
	%PointNE.position = pointsContainer.make_canvas_position_local(Vector2(screenMax.x, screenMin.y))
	%PointE.position  = pointsContainer.make_canvas_position_local(Vector2(screenMax.x, screenMid.y))
	%PointSE.position = pointsContainer.make_canvas_position_local(Vector2(screenMax.x, screenMax.y))
	%PointS.position  = pointsContainer.make_canvas_position_local(Vector2(screenMid.x, screenMax.y))
	%PointSW.position = pointsContainer.make_canvas_position_local(Vector2(screenMin.x, screenMax.y))
	%PointW.position  = pointsContainer.make_canvas_position_local(Vector2(screenMin.x, screenMid.y))

	# Spawn Areas
	var northAreaSize:	Vector2	= Vector2(viewportRect.size.x + screenPadding.x * 2.0, self.areaThickness)
	var eastAreaSize:	Vector2	= Vector2(self.areaThickness, viewportRect.size.y + screenPadding.y * 2.0)
	var southAreaSize:	Vector2	= Vector2(viewportRect.size.x + screenPadding.x * 2.0, self.areaThickness)
	var westAreaSize:	Vector2	= Vector2(self.areaThickness, viewportRect.size.y + screenPadding.y * 2.0)

	setAreaBounds(%AreaN, Vector2(screenMin.x, screenMin.y - northAreaSize.y), northAreaSize)
	setAreaBounds(%AreaE, Vector2(screenMax.x, screenMin.y), eastAreaSize)
	setAreaBounds(%AreaS, Vector2(screenMin.x, screenMax.y), southAreaSize)
	setAreaBounds(%AreaW, Vector2(screenMin.x - westAreaSize.x, screenMin.y),  westAreaSize)


func setAreaBounds(spawnArea: SpawnArea, viewportPosition: Vector2, size: Vector2) -> void:
	spawnArea.position = areasContainer.make_canvas_position_local(viewportPosition)

	if not spawnArea.spawnAreaShape.shape is RectangleShape2D:
		Debug.printWarning(str("SpawnEdge.setAreaBounds() requires a RectangleShape2D: ", spawnArea.spawnAreaShape.shape), spawnArea)
		return

	var rectangleShape: RectangleShape2D = spawnArea.spawnAreaShape.shape
	rectangleShape.size = size
	spawnArea.spawnAreaShape.position = size / 2.0

#endregion
