## AutoLoad
## Global game-specific state and "signal/event bus" available to all scenes and nodes at all times.
## Extend to manage the state of each game "campaign", such as the difficulty level, character class, and current map etc.
## NOTE: Use the `Settings.gd` to store the "system environment" (like player preferences such as buttons and volume etc.)

# class_name GameState
extends Node


#region Game State

## A dictionary of values that may be accessed and modified by multiple nodes and the scripts in the scene tree.
## [StringName] is the optimal type to use for keys.
@export var globalData: Dictionary[Variant, Variant] = {} # TBD: Allow only StringName keys?

## The list of active players, each represented by a [PlayerEntity] or [TurnBasedPlayerEntity].
## WARNING: Do NOT modify this property directly; use [method addPlayer] and [method removePlayer] to ensure that signals are emitted and proper cleanup is performerd.
## NOTE: To avoid an error or crash when there is no player, access players with [method getPlayer] NOT `players.front()` or `player[0]`
var players: Array[Entity] = [] # TBD: Should we use separate arrays for PlayerEntity and TurnBasedPlayerEntity? # But a generic Entity type also allows for game-specific custom subclasses.


## A dictionary of stats and values to display in the HUD UI.
## Changes to the dictionary should emit the `hudUpdated` signal which may be used by UI nodes to efficiently update themselves only when stats change.
## [StringName] is the optimal type to use for keys.
@export var hudStats: Dictionary[Variant, Variant] = {} # TBD: Allow only StringName keys?

#endregion


#region Signals
# DESIGN: The names of the signals start with the names of the related types/objects, instead of "did/will" etc., because GameState is a global object.
signal playersChanged
signal playerAdded(player:   Entity)
@warning_ignore("unused_signal")
signal playerReady(player:   Entity) ## Emitted by a [PlayerEntity] or [TurnBasedPlayerEntity] at the end of its [method Node._ready], indicating that it has entered a Scene.
signal playerRemoved(player: Entity)
#endregion

#region Signal Event Bus
# These signals may be emitted by any object and connected to any object at any time, usually via scripts.
# IGNORE Godot Warning; these signals are used by other classes.

@warning_ignore("unused_signal")
signal statUpdated(stat: Stat) ## Emitted when a [Stat] is changed, so that any UI elements which depend on that Stat may be updated, such as a [ManualStatsList]

@warning_ignore("unused_signal")
signal gameDidOver ## Emitted when You Died. NOTE: Multiplayer games must check if other players are still "alive".

@warning_ignore("unused_signal")
signal gameWillRestart ## Emitted when the player chooses to restart the game or level etc.
#endregion


func _enter_tree() -> void:
	Debug.printAutoLoadLog("_enter_tree()")


#region Player Management

## Adds a player if it is not already in the [member GameState.players] array, emits the related signals, and returns the new size of the [member players] array.
func addPlayer(newPlayer: Entity) -> int:
	if not newPlayer in self.players:
		self.players.append(newPlayer)
		Debug.printLog("addPlayer(): [b]" + str(newPlayer.logFullName) + "[/b] → GameState.players → size: " + str(GameState.players.size()), self)
		playerAdded.emit(newPlayer)
		playersChanged.emit()
	else:
		Debug.printWarning("Tried to re-add player already in GameState.players: " + str(newPlayer))

	return self.players.size()


## Returns the requested entity from the global [member players] array, if present.
func getPlayer(playerIndex: int = 0) -> Entity:
	if self.players.is_empty() or not Tools.validateArrayIndex(self.players, playerIndex): # TBD: Remove is_empty() because it's checked by validateArrayIndex() anyway?
		return null

	return GameState.players[playerIndex]


## Removes a player, emits the related signals, and returns `true` if the removal was successful.
func removePlayer(playerToRemove: Entity) -> bool:
	var indexToRemove: int = self.players.find(playerToRemove)

	# NOTE: Do NOT use `indexToRemove` as a boolean check, because 0 is a valid index but would be considered `false`!
	# Therefore, compare with `-1` which is returned if [Array.find] fails.

	if indexToRemove != -1:
		Debug.printLog("removePlayer(): " + str(playerToRemove.logFullName) + " | Removing from GameState.players → size: " + str(GameState.players.size() - 1), self)
		self.players.remove_at(indexToRemove)
		playerRemoved.emit(playerToRemove)
		playersChanged.emit()

		# Did everyone die?
		if players.is_empty(): gameDidOver.emit()

		return true

	elif indexToRemove == -1:
		Debug.printWarning("removePlayer(): Player to remove not found in GameState.players: " + str(playerToRemove), self)

	return false

#endregion


#region Game Cycle

## Transitions to the [member Settings.mainGameScenePath].
func startMainScene() -> void:
	if not Settings.mainGameScenePath:
		Debug.printError("Settings.mainGameScenePath not set!", self)
		return
		
	var mainGameScene: PackedScene = load(Settings.mainGameScenePath)
	if not mainGameScene:
		Debug.printError("Cannot load mainGameScenePath: " + Settings.mainGameScenePath, self)
		return

	SceneManager.transitionToScene(mainGameScene)
	GlobalInput.isPauseShortcutAllowed = true


## Called when the user or a condition like Game Over causes the game (or level) to be restarted.
## By default, returns to the Main Menu.
## Override for game-specific functionality.
## @experimental
func restart() -> void:
	SceneManager.transitionToScene(load("res://Scenes/Launch/GameFrame.tscn"))


#endregion


#region Save & Load

## A very rudimentary implementation of saving the entire game state.
## @experimental
func saveGame() -> void: # NOTE: Cannot be `static` because of `self.process_mode`
	# TODO: Implement properly :(
	# BUG:  Does not save all state of all nodes
	# TBD:  Is it necessary to `await` & pause to ensure a reliable & deterministic save?

	GlobalUI.createTemporaryLabel("Saving...") # NOTE: Don't `await` here or it will wait for the animation to finish.
	@warning_ignore("redundant_await")
	await Debug.printLog("Saving state → " + Settings.saveFilePath) # TBD: await or not?

	var sceneTree := get_tree()
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	sceneTree.paused = true

	Global.screenshot("Save") # DEBUG: Take a screenshop for comparison

	var packedSceneToSave := PackedScene.new()
	packedSceneToSave.pack(sceneTree.get_current_scene())
	ResourceSaver.save(packedSceneToSave, Settings.saveFilePath)

	sceneTree.paused = false


## A very rudimentary implementation of loading the entire game state.
## @experimental
func loadGame() -> void:  # NOTE: Cannot be `static` because of `self.process_mode`
	# TODO: Implement properly :(
	# BUG:  Does not restore all state of all nodes
	# TBD:  Is it necessary to `await` & pause to ensure a reliable & deterministic load?

	GlobalUI.createTemporaryLabel("Loading...")  # NOTE: Don't `await` here or it will wait for the animation to finish.
	@warning_ignore("redundant_await")
	await Debug.printLog("Loading state ← " + Settings.saveFilePath) # TBD: await or not?

	var sceneTree := get_tree()
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	sceneTree.paused = true

	var packedSceneLoaded := ResourceLoader.load(Settings.saveFilePath)

	sceneTree.paused = false
	sceneTree.change_scene_to_packed(packedSceneLoaded)
	Global.screenshot("Load") # DEBUG: Take a screenshop for comparison, but BUG: The screenshot gets delayed

#endregion