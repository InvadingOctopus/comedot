## AutoLoad
## Global game-specific state and "signal/event bus" available to all scenes and nodes at all times.
## May be used to store the "system environment" (like player preferences such as buttons and volume etc.) and also the state of each game "campaign", such as the difficulty level and character class etc.

# class_name GameState
extends Node


#region Game State

## A dictionary of values that may be accessed and modified by multiple nodes and the scripts in the scene tree.
## [StringName] is the optimal type to use for keys.
@export var globalData: Dictionary[Variant, Variant] = {} # TBD: Allow only StringName keys?

## The list of active players.
## WARNING: Do NOT modify this property directly; use [method addPlayer] and [method removePlayer] instead.
## NOTE: To avoid a crash when there is no player, access the first player with `players.front()` NOT `player[0]`.
var players: Array[PlayerEntity] = []

## A dictionary of stats and values to display in the HUD UI.
## Changes to the dictionary should emit the `hudUpdated` signal which may be used by UI nodes to efficiently update themselves only when stats change.
## [StringName] is the optimal type to use for keys.
@export var hudStats: Dictionary[Variant, Variant] = {} # TBD: Allow only StringName keys?

#endregion


#region Signals
# DESIGN: The names of the signals start with the names of the related types/objects, instead of "did/will" etc., because GameState is a global object.
signal playersChanged
signal playerAdded(player: PlayerEntity)
@warning_ignore("unused_signal")
signal playerReady(player: PlayerEntity) ## Emitted by a [PlayerEntity] at the end of its [method Node._ready], indicating that it has entered a Scene.
signal playerRemoved(player: PlayerEntity)
#endregion

#region Signal Event Bus
# These signals may be emitted by any object and connected to any object at any time, usually via scripts.
# IGNORE Godot Warning; these signals are used by other classes.

## @experimental
@warning_ignore("unused_signal")
signal uiActionDidRequestTarget(action: Action, source: Variant) ## Emitted when an [Action] requires a target, so that the UI may prompt the player to choose a target.

@warning_ignore("unused_signal")
signal uiStatUpdated(stat: Stat) ## Emitted when a [Stat] is changed, so that any UI elements which depend on that Stat may be updated.
#endregion


func _enter_tree() -> void:
	Debug.printAutoLoadLog("_enter_tree()")


## Adds a player if it is not already in the [member GameState.players] array, emits the related signals, and returns the new size of the [member players] array.
func addPlayer(newPlayer: PlayerEntity) -> int:
	if not newPlayer in self.players:
		self.players.append(newPlayer)
		Debug.printLog("addPlayer(): [b]" + str(newPlayer.logFullName) + "[/b] → GameState.players → size: " + str(GameState.players.size()), self)
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
		Debug.printLog("removePlayer(): " + str(playerToRemove.logFullName) + " | Removing from GameState.players → size: " + str(GameState.players.size() - 1), self)
		self.players.remove_at(indexToRemove)
		playerRemoved.emit(playerToRemove)
		playersChanged.emit()
		return true
	elif indexToRemove == -1:
		Debug.printWarning("removePlayer(): Player to remove not found in GameState.players: " + str(playerToRemove), self)

	return false
