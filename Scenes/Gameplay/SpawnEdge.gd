## Adds [SpawnPoint]s at the 8 cardinal+ordinal directions on the screen's edge,
## and [SpawnArea]s just outside the 4 screen edges.
## NOTE: To set the scenes to spawn and other parameters, enable "Editable Children" to access all the underlying [SpawnTimer]s & their [Spawner] child nodes which do the core work,
## or subclass this script or use another script to access the [member spawnTimers] list, or control each `%N`, `%NArea` etc. node individually.
## TIP: If this script is attached to a [CanvasLayer], the Spawners will stay fixed at the edges even as the player/camera moves and the map scrolls.
## TIP: Ideal for spawning enemies just outside the view in scrolling shoot-em-ups etc.

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

## A list of all the [SpawnTimer]s under all the [SpawnPoint]s & [SpawnArea]s
## with the points in clockwise order from NW (0,0) then the areas.
## Each [SpawnTimer] contains a [Spawner] child node.
var spawnTimers: Array[SpawnTimer]

#endregion


#region Setup

func _enter_tree() -> void:
	spawnTimers = getAllSpawnTimers()
	validateSpawners()
	setSpawnerParents() # Apply our `parentOverride` before the Spawners' _ready()


func _ready() -> void:
	setSpawnerPlacements()


## Returns a list of all the [SpawnTimer]s under all the [SpawnPoint]s & [SpawnArea]s
## with the points in clockwise order from NW (0,0) then the areas.
## This is a separate method so it can be called when this script is ready.
## NOTE: Does NOT rebuild [member spawnTimers] in case a script wants to modify either list separately.
func getAllSpawnTimers() -> Array[SpawnTimer]:
	return [
		%NW/SpawnTimer, # Start in order from 0,0 clockwise
		%N/SpawnTimer,
		%NE/SpawnTimer,
		%E/SpawnTimer,
		%SE/SpawnTimer,
		%S/SpawnTimer,
		%SW/SpawnTimer,
		%W/SpawnTimer,
		%NArea/SpawnTimer,
		%EArea/SpawnTimer,
		%SArea/SpawnTimer,
		%WArea/SpawnTimer,
		]


## Enables or disables all [SpawnTimer]s based on whether they have a valid [member Spawner.sceneToSpawn] or not.
func validateSpawners() -> void:
	for spawnTimer: SpawnTimer in spawnTimers:
		spawnTimer.isEnabled = spawnTimer.spawner.validateSceneToSpawn()


func setSpawnerParents() -> void:
	var spawnParent: Node = self.parentOverride
	# If no `parentOverride` is provided and we're a CanvasLayer, use our parent
	if not spawnParent and is_instance_of(self, CanvasLayer):
		spawnParent = self.get_parent()

	if not spawnParent: return

	for spawnTimer: SpawnTimer in self.spawnTimers:
		spawnTimer.spawner.parentOverride = spawnTimer.spawner.get_path_to(spawnParent)


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
	%NW.position = pointsContainer.make_canvas_position_local(Vector2(screenMin.x, screenMin.y))
	%N.position  = pointsContainer.make_canvas_position_local(Vector2(screenMid.x, screenMin.y))
	%NE.position = pointsContainer.make_canvas_position_local(Vector2(screenMax.x, screenMin.y))
	%E.position  = pointsContainer.make_canvas_position_local(Vector2(screenMax.x, screenMid.y))
	%SE.position = pointsContainer.make_canvas_position_local(Vector2(screenMax.x, screenMax.y))
	%S.position  = pointsContainer.make_canvas_position_local(Vector2(screenMid.x, screenMax.y))
	%SW.position = pointsContainer.make_canvas_position_local(Vector2(screenMin.x, screenMax.y))
	%W.position  = pointsContainer.make_canvas_position_local(Vector2(screenMin.x, screenMid.y))

	# Spawn Areas
	var northAreaSize:	Vector2	= Vector2(viewportRect.size.x + screenPadding.x * 2.0, self.areaThickness)
	var eastAreaSize:	Vector2	= Vector2(self.areaThickness, viewportRect.size.y + screenPadding.y * 2.0)
	var southAreaSize:	Vector2	= Vector2(viewportRect.size.x + screenPadding.x * 2.0, self.areaThickness)
	var westAreaSize:	Vector2	= Vector2(self.areaThickness, viewportRect.size.y + screenPadding.y * 2.0)

	setAreaBounds(%NArea, Vector2(screenMin.x, screenMin.y - northAreaSize.y), northAreaSize)
	setAreaBounds(%EArea, Vector2(screenMax.x, screenMin.y), eastAreaSize)
	setAreaBounds(%SArea, Vector2(screenMin.x, screenMax.y), southAreaSize)
	setAreaBounds(%WArea, Vector2(screenMin.x - westAreaSize.x, screenMin.y),  westAreaSize)


func setAreaBounds(spawnArea: SpawnArea, viewportPosition: Vector2, size: Vector2) -> void:
	spawnArea.position = areasContainer.make_canvas_position_local(viewportPosition)

	if not spawnArea.spawnAreaShape.shape is RectangleShape2D:
		Debug.printWarning(str("SpawnEdge.setAreaBounds() requires a RectangleShape2D: ", spawnArea.spawnAreaShape.shape), spawnArea)
		return

	var rectangleShape: RectangleShape2D = spawnArea.spawnAreaShape.shape
	rectangleShape.size = size
	spawnArea.spawnAreaShape.position = size / 2.0

#endregion
