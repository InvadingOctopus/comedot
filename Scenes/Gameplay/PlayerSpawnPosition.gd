## Sets the position of the specified player [Entity] to itself on [method _ready].
## ALERT: If the player entity has a [Camera2D] node that is saved in the scene at a different position,
## the camera will "jump" to this [PlayerSpawnPosition] if the player is not [method _ready] before this script runs.
## To avoid, check the order of nodes in the scene tree, or enable [member Camera2D.position_smoothing_enabled] for a slower panning effect,
## or delete the player's initial [Camera2D] and enable the [member shouldCreateCamera] option.

class_name PlayerSpawnPosition
extends Marker2D


#region Parameters

## The index into the [member GameState.players] array.
## NOTE: Ignored if [member playerOverride] is set.
@export var playerIndex: int = 0

## A custom [Entity] instead of a member of the [member GameState.players] array.
## NOTE: Overrides [member playerIndex].
@export var playerOverride: Entity

## If `true` and if the player entity doesn't have a [Camera2D] node, a new camera will be created and added to the player.
## TIP: This option may resolve jumps between the difference in the player's initial position as saved in the scene, and this spawn point, if the player is not [method _ready] before this script.
@export var shouldCreateCamera: bool = false

@export var debugMode: bool = false

#endregion


#region State

var player: PlayerEntity:
	get:
		if playerOverride: return playerOverride
		else: return GameState.getPlayer(playerIndex)

@onready var playerSpawnPosition: Marker2D = self

#endregion


func _ready() -> void:
	if player: setPlayerPosition()
	else: GameState.playerReady.connect(self.onGameState_playerReady) # If there is no player yet, wait for one to be ready
	

func onGameState_playerReady(newPlayer: Entity) -> void:
	# Make sure that the player that just became ready is the one that we were asked to position
	if newPlayer == self.player: self.setPlayerPosition()


func setPlayerPosition() -> void:
	if player:
		if debugMode: Debug.printDebug(str("setPlayerPosition(): ", player.global_position, " → ", playerSpawnPosition.global_position), self)
		player.global_position = playerSpawnPosition.global_position
		if shouldCreateCamera: setCamera()


## Creates a [Camera2D] if the player entity does not already have one, or just returns the existing camera.
## This avoids any jumps between different initial positions. See the [member shouldCreateCamera] flag.
func setCamera() -> Camera2D:
		var camera: Camera2D = player.findFirstChildOfType(Camera2D)
		if shouldCreateCamera and camera == null:
			camera = Camera2D.new()
			Tools.addChildAndSetOwner(camera, player)
			if debugMode: Debug.printDebug(str("setCamera() new: ", camera), self)
		
		return camera
