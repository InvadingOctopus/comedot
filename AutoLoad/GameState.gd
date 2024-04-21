# AutoLoad
## Global game-specific state and "event bus" available to all scenes and nodes at all times.
## May be used as the state of the overal "environment" (like settings and a network lobby) and also the state of each "run".

extends Node


## The list of active players.
## WARNING: Do NOT modify this property directly; use [method addPlayer] and [method removePlayer] instead.
var players: Array[PlayerEntity] = []

## A dictionary of values that may be accessed and modified by multiple nodes and the scripts in the scene tree.
## [StringName] is the optimal type to use for keys.
@export var globalData = {}

## A dictionary of stats and values to display in the HUD UI.
## Changes to the dictionary emit the `hudUpdated` signal which may be used by UI nodes to efficiently update themselves only when stats change.
## [StringName] is the optimal type to use for keys.
@export var hudStats = {}


#region Signals

signal playersChanged
signal playerAdded(player: PlayerEntity)
signal playerRemoved(player: PlayerEntity)

signal HUDStatUpdated(stat: Stat)

#endregion


## Adds a player if it is not already in the [member GameState.players] array, emits the related signals, and returns the new size of the [member players] array.
func addPlayer(newPlayer: PlayerEntity) -> int:
	if not newPlayer in self.players:
		self.players.append(newPlayer)
		Debug.printLog("addPlayer(): [b]" + str(newPlayer.logFullName) + "[/b] → GameState.players → size: " + str(GameState.players.size()), "", str(self))
		playerAdded.emit(newPlayer)
		playersChanged.emit()
	else:
		Debug.printWarning("Tried to re-add player already in GameState.players: " + str(newPlayer))

	return self.players.size()


## Removes a player, emits the related signals, and returns `true` if the removal was successful.
func removePlayer(playerToRemove: PlayerEntity) -> bool:
	var indexToRemove: int = self.players.find(playerToRemove)

	# NOTE: Do NOT use `indexToRemove` as a boolean check, because 0 is a valid index but would be considered `false`!
	# Therefore, compare with `-1` which is returned if [Array.find] fails.

	if indexToRemove != -1:
		Debug.printLog("removePlayer(): " + str(playerToRemove.logFullName) + " | Removing from GameState.players → size: " + str(GameState.players.size() - 1), "", str(self))
		self.players.remove_at(indexToRemove)
		playerRemoved.emit(playerToRemove)
		playersChanged.emit()
		return true
	elif indexToRemove == -1:
		Debug.printWarning("removePlayer(): Player to remove not found in GameState.players: " + str(playerToRemove), str(self))

	return false


