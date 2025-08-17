# PopulateTest

extends Start


#region Parameters
const nodeGroup := &"testMap"

@export_range(0, 1.0, 0.01) var selectionChance:  float = 1.0
@export_range(0, 1.0, 0.01) var spawnChance:	  float = 1.0

@export_range(0, 256, 1) var numberOfCopies:		int = 8
@export_range(0, 256, 1) var maximumNumberOfCopies:	int = 8

@export var includeUsedCells:  bool = true
@export var includeEmptyCells: bool = true
#endregion


func _ready() -> void:
	super._ready()
	populateMap()
	$RepoulationTimer.start()


func populateMap() -> void:
	var sceneToSpawn := load("res://Templates/TestSprite16.tscn") # Not preload because it might get loaded at startup even if this test is never used.
	var spawnedNodes: Dictionary[Vector2i, Node2D]
	var randomCells: Array[Vector2i]

	spawnedNodes = Tools.populateTileMap(%TileMap1, sceneToSpawn,
		self.numberOfCopies,
		null,	 # parentOverride
		nodeGroup) # groupToAddTo
	print(str("Spawned by populateTileMap(): ", spawnedNodes))

	randomCells = Tools.findRandomTileMapCells(
		%TileMap2,
		self.selectionChance,
		self.includeUsedCells,
		self.includeEmptyCells)

	spawnedNodes = Tools.populateTileMapCells(
		%TileMap2, randomCells, sceneToSpawn,
		self.maximumNumberOfCopies,
		self.spawnChance,
		null,	 # parentOverride
		nodeGroup) # groupToAddTo
	print(str("Spawned by populateTileMapCells(): ", spawnedNodes))


func onRepoulationTimer_timeout() -> void:
	removeTestNodes()
	populateMap()


func removeTestNodes() -> void:
	for node in self.get_tree().get_nodes_in_group(nodeGroup):
		node.queue_free()
