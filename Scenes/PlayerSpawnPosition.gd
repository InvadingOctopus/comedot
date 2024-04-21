## Sets the position of the specified player [Entity] to itself on [method _ready]

extends Marker2D

#region Parameters

## The index into the [member GameState.players] array.
@export var playerIndex: int = 0

## A custom [Entity] instead of a member of the [member GameState.players] array.
@export var playerOverride: Entity

@onready var playerSpawnPosition: Marker2D = self

#endregion


var player: PlayerEntity:
	get:
		if playerOverride:
			return playerOverride
		elif playerIndex == 0:
			return GameState.players.front()
		else:
			return GameState.players[playerIndex]


func _ready() -> void:
	if player:
		player.global_position = playerSpawnPosition.global_position
