# Tile-based Movement Test for [TileBasedPositionComponent]

extends Start


@onready var mapA: TileMapLayer = %TileMapA
@onready var mapB: TileMapLayer = $TileMapB
@onready var mapC: TileMapLayer = $TileMapC

@onready var player: PlayerEntity = $"Player-TileBased"
@onready var tileBasedPositionComponent: TileBasedPositionComponent = $"Player-TileBased/TileBasedPositionComponent"


func onButtonACell_pressed() -> void:
	tileBasedPositionComponent.setMapAndKeepCoordinates(mapA)


func onButtonBCell_pressed() -> void:
	tileBasedPositionComponent.setMapAndKeepCoordinates(mapB)


func onButtonBPixel_pressed() -> void:
	tileBasedPositionComponent.setMapAndKeepPosition(mapB)


func onButtonCCell_pressed() -> void:
	tileBasedPositionComponent.setMapAndKeepCoordinates(mapC)


func onButtonCPixel_pressed() -> void:
	tileBasedPositionComponent.setMapAndKeepPosition(mapC)
