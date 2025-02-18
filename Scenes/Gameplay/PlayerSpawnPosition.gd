## Sets the position of the specified player [Entity] to itself on [method _ready].

extends Marker2D


#region Parameters

## The index into the [member GameState.players] array.
## NOTE: Ignored if [member playerOverride] is set.
@export var playerIndex: int = 0

## A custom [Entity] instead of a member of the [member GameState.players] array.
## NOTE: Overrides [member playerIndex].
@export var playerOverride: Entity

@onready var playerSpawnPosition: Marker2D = self

#endregion


var player: PlayerEntity:
	get:
		if playerOverride: return playerOverride
		else: return GameState.getPlayer(playerIndex)


func _ready() -> void:
	if player: setPlayerPosition()
	else: GameState.playerReady.connect(self.onGameState_playerReady) # If there is no player yet, wait for one to be ready
	

func onGameState_playerReady(newPlayer: Entity) -> void:
	# Make sure that the player that just became ready is the one that we were asked to position
	if newPlayer == self.player: self.setPlayerPosition()


func setPlayerPosition() -> void:
	if player: player.global_position = playerSpawnPosition.global_position
