## "Boots" and initializes the Comedot Framework and applies global flags.
## Also optionally adds nodes and data to the [GameState].gd AutoLoad, to quickly add custom game-specific global state.
## ATTENTION: This script MUST be attached to the root node of the main scene of your game.
## Most debugging flags default to `true` when running in a debug build.
## NOTE: If you need custom functionality for your main scene's root node, such as initializing the game-specific environment,
## then your script must `extends Start` and if you override [method _ready], your ready method MUST also call `super._ready()`.

class_name Start
extends CanvasItem


#region Framework Settings
@export_category("Comedot")


#region General
@export_group("Global Game State")

## The path of the main scene of your game to launch when the player chooses "Start" on the Main Menu.
## If omitted, then [member Settings.mainGameScenePath] remains unmodified.
## This is not a [PackedScene] Resource to avoid circular references or load()ing before it is needed.
@export_file("*.tscn") var mainGameScenePath: String:
	set(newValue):
		if newValue != mainGameScenePath:
			mainGameScenePath = newValue
			Settings.mainGameScenePath = newValue

## Appends entries to [member GameState.globalData], a [Dictionary] of values that may be accessed and modified by multiple nodes/scripts in the scene tree at any time.
## ALERT: Entries with identical keys already in [member GameState.globalData] will be OVERWRITTEN!
## TIP: [StringName] may be the optimal type to use for keys.
@export var initialGlobalData: Dictionary[Variant, Variant] = {} # TBD: Allow only StringName keys?

## A list of scenes to add as child nodes of the [GameState].gd AutoLoad.
## @experimental
@export_file_path("*.tscn") var gameStateNodes: PackedStringArray

#endregion


#region Music
@export_group("Music")

## The path of the folder from which to load ".mp3" music files to build a playlist.
@export_dir var musicFolder: String = "res://Assets/Music"

## Overrides [member musicIndexToPlayOnStart].
@export_file("*.mp3") var musicFileToPlayOnStart: String

## If [member musicFileToPlayOnStart] is unspecified, then a random song is played from the list of files found in [member musicFolder].
@export var shouldPlayRandomMusicIndex: bool = true

## If [member musicFileToPlayOnStart] is unspecified and [member shouldPlayRandomMusicIndex] is `false`, then this is the index of the first song from the list of files found in [member musicFolder].
@export var musicIndexToPlayOnStart: int

#endregion


#region Turn-Based
@export_group("Turn-Based Gameplay")

## To avoid the [Timer] error: "Time should be greater than zero" and other jank from being TOO fast.
## According to Godot documentation, it should be 0.05
const minimumTurnDelay: float = 0.05

## If `false`, disables & removes the [TurnBasedCoordinator] AutoLoad.
## WARNING: If disabled, turn-based nodes and scripts may cause a crash.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var isTurnBasedGame: bool = false

## The delay after processing each [TurnBasedEntity] PER PHASE (Begin/Update/End). May be used for aesthetics or debugging.
## NOTE: This delay also occurs even AFTER the LAST entity in the order, even if there is only 1 entity!
## This ensures a delay between multiple moves of the same entity.
@export_range(minimumTurnDelay, 10, 0.05) var turnBasedDelayBetweenEntities: float = TurnBasedCoordinator.delayBetweenEntities if TurnBasedCoordinator else minimumTurnDelay:
	set(newValue):
		if newValue != turnBasedDelayBetweenEntities:
			turnBasedDelayBetweenEntities = newValue
			if TurnBasedCoordinator: TurnBasedCoordinator.delayBetweenEntities = newValue

# TBD: @export_subgroup("Turn-Based States Delay")

@export var shouldWaitBetweenTurnStates: bool = TurnBasedCoordinator.shouldWaitBetweenStates if TurnBasedCoordinator else true: ## Enables or disables [member turnBasedDelayBetweenStates.
	set(newValue):
		if newValue != shouldWaitBetweenTurnStates:
			shouldWaitBetweenTurnStates = newValue
			if TurnBasedCoordinator: TurnBasedCoordinator.shouldWaitBetweenStates = newValue

## The delay after each [enum TurnBasedCoordinator.TurnBasedState] if [member shouldWaitBetweenTurnStates]: Begin → Update → End. May be used for aesthetics or debugging.
## NOTE: The delay will occur BEFORE the [member TurnBasedCoordinator.currentTurnState] is incremented.
## NOTE: This delay also occurs even AFTER the "End" phase! This ensures a delay between the end of the previous turn and the beginning of the next turn.
@export_range(minimumTurnDelay, 10, 0.05) var turnBasedDelayBetweenStates: float = TurnBasedCoordinator.delayBetweenStates if TurnBasedCoordinator else minimumTurnDelay:
	set(newValue):
		if newValue != turnBasedDelayBetweenStates:
			turnBasedDelayBetweenStates = newValue
			if TurnBasedCoordinator: TurnBasedCoordinator.delayBetweenStates = newValue

#endregion


#region Debugging
@export_group("Debugging")

## NOTE: Only applicable in debug builds (i.e. running from the Godot Editor)
@export var showDebugWindow: bool = OS.is_debug_build():
	set(newValue):
		showDebugWindow = newValue
		if Debug.debugWindow: Debug.debugWindow.visible = newValue

## Sets the visibility of "debug"-level messages in the log.
## NOTE: Does NOT affect normal logging.
@export var shouldPrintDebugLogs: bool = OS.is_debug_build():
	set(newValue):
		shouldPrintDebugLogs = newValue
		Debug.shouldPrintDebugLogs = newValue

## Sets the visibility of the debug information overlay text.
## NOTE: Does NOT affect the visibility of the framework warning label.
@export var showDebugLabels: bool = OS.is_debug_build():
	set(newValue):
		showDebugLabels = newValue
		Debug.showDebugLabels = newValue

@export var showDebugBackground: bool = true:
	set(newValue):
		showDebugBackground = newValue
		if Debug.debugBackground: Debug.debugBackground.visible = newValue

#endregion

#endregion


#region Bootup

## Called when the scene enters the tree for the first time.
## ATTENTION: A subclass which `extends Start` and overrides [method _enter_tree] MUST call `super._enter_tree()`
func _enter_tree() -> void:
	# NOTE: This must be _enter_tree() instead of _ready() because nodes are readied from the bottom-up, children-first,
	# and since Start.gd is attached to the root node, it will be ready last, so we need to prepare up the global state earlier,
	# in case other scripts depend on it in their _ready()
	setupGameState()


## @experimental
func setupGameState() -> void:
	if not mainGameScenePath.is_empty():
		Settings.mainGameScenePath	= self.mainGameScenePath

	GameState.globalData.merge(self.initialGlobalData, true) # overwrite

	for path in gameStateNodes:
		GameState.createNode(path)


## ATTENTION: A subclass which `extends Start` and overrides [method _ready] MUST call `super._ready()`
func _ready() -> void:
	startComedot()


func startComedot() -> void:
	printLog("[b]_ready()[/b]")
	Global.hasStartScript = true
	Debug.performFrameworkChecks() # Update the warning about missing Start script
	applyGlobalFlags()


func applyGlobalFlags() -> void:
	# Debugging
	Debug.shouldPrintDebugLogs		= self.shouldPrintDebugLogs
	Debug.debugWindow.visible		= self.showDebugWindow if OS.is_debug_build() else false
	Debug.showDebugLabels			= self.showDebugLabels
	Debug.debugBackground.visible	= self.showDebugBackground

	# Game State handled by setupGameState()

	# 🎶

	GlobalSonic.musicFolder			= self.musicFolder
	GlobalSonic.loadMusicFolder()
	GlobalSonic.currentMusicIndex	= self.musicIndexToPlayOnStart

	if not self.musicFileToPlayOnStart.is_empty():
		GlobalSonic.playMusicFile(self.musicFileToPlayOnStart)
	elif shouldPlayRandomMusicIndex:
		GlobalSonic.playRandomMusicIndex(true) # allowRepeats to allow index 0 to be included :')
	else:
		GlobalSonic.playMusicIndex(self.musicIndexToPlayOnStart)

	# Turn-Based
	if isTurnBasedGame:
		printLog("isTurnBasedGame: Setting TurnBasedCoordinator")
		TurnBasedCoordinator.delayBetweenEntities	 = self.turnBasedDelayBetweenEntities

		TurnBasedCoordinator.shouldWaitBetweenStates = self.shouldWaitBetweenTurnStates
		TurnBasedCoordinator.delayBetweenStates		 = self.turnBasedDelayBetweenStates
	else:
		printLog("not isTurnBasedGame:[color=red] Removing TurnBasedCoordinator")
		if is_instance_valid(TurnBasedCoordinator):
			TurnBasedCoordinator.process_mode = Node.PROCESS_MODE_DISABLED
			TurnBasedCoordinator.queue_free()
			# NOTE: DESIGN: Accessing TurnBasedCoordinator after starting a non-turn-based game will cause a crash, which is the intended behavior.

#endregion


func printLog(message: String) -> void:
	Debug.printLog(message, str("[b]", self.get_script().resource_path.get_file(), "[/b] ", self), "WHITE", "WHITE")
