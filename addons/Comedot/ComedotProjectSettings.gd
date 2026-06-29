## Comedot Project Settings
## IMPORTANT: These are NOT Godot's project settings like [ProjectSettings],
## and generally not exposed to the player or modifiable during gameplay runtime.
## INFO: These settings are set at DEVELOPMENT-TIME and  apply to Comedot AutoLoads, the Components Dock, Debugging/Logging,
## and general game DEVELOPMENT-TIME settings such as the music assets folder etc.
## TIP: Also optionally adds nodes and data to the [GameState].gd AutoLoad, to quickly add custom game-specific global state.
## NOTE: Most debugging flags default to `true` when running in a debug build.


class_name ComedotProjectSettings
extends Resource

# DESIGN: Why not just use custom settings in the Godot Editor's Project Settings UI and access them via [ProjectSettings]?
# Because that's too cumbersome & tedious compared to just `@export`
# It would require a lot of boilerplate and calls to `ProjectSettings.set_setting(path, defaultValue)`, `.set_initial_value()`, `.add_property_info()` etc.

# TBD: DESIGN: Why duplicate some `@export`s in both ComedotProjectSettings.gd and also the AutoLoads?
# To let some AutoLoad settings be modifiable at runtime during gameplay, such as music shuffle or turn delays etc.


#region Framework Settings
# DESIGN: Use `@export_category` instead of `@export_group` because these settings essentially apply to different "classes".
# @export_category("Comedot")

const projectSettingsResourcePathDefault: String = "res://ComedotProjectSettings.tres"


#region General
@export_category("Global Game State")

## The path of the main scene of your game to launch when the player chooses "Start" on the Main Menu.
## If omitted, then [member Settings.mainGameScenePath] remains unmodified.
## This is not a [PackedScene] Resource to avoid circular references or load()ing before it is needed.
@export_file("*.tscn") var mainGameScenePath: String

## Appends entries to [member GameState.globalData], a [Dictionary] of values that may be accessed and modified by multiple nodes/scripts in the scene tree at any time.
## ALERT: Entries with identical keys already in [member GameState.globalData] will be OVERWRITTEN!
## TIP: [StringName] may be the optimal type to use for keys.
@export var initialGlobalData: Dictionary[Variant, Variant] = {} # TBD: Allow only StringName keys?

## A list of scenes to add as child nodes of the [GameState].gd AutoLoad.
## @experimental
@export_file_path("*.tscn") var gameStateNodes: PackedStringArray

#endregion


#region Music
@export_category("Music")

## The path of the folder from which to load ".mp3" music files to build a playlist.
@export_dir var musicFolder: String = "res://Assets/Music"

## Overrides [member musicIndexToPlayOnStart]
@export_file("*.mp3") var musicFileToPlayOnStart: String

## If [member musicFileToPlayOnStart] is unspecified, then a random song is played from the list of files found in [member musicFolder]
@export var shouldPlayRandomMusicOnStart: bool = true

## If [member musicFileToPlayOnStart] is unspecified and [member shouldPlayRandomMusicOnStart] is `false`, then this is the index of the first song from the list of files found in [member musicFolder]
@export var musicIndexToPlayOnStart: int

#endregion


#region Turn-Based
@export_category("Turn-Based")
@export_group("Turn-Based Gameplay")

## To avoid the [Timer] error: "Time should be greater than zero" and other jank from being TOO fast.
## According to Godot documentation, it should be 0.05
const turnBasedMinimumDelay: float = 0.05

## If `false`, disables & removes the [TurnBasedCoordinator] AutoLoad.
## WARNING: If disabled, turn-based nodes and scripts may cause a crash.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var isTurnBasedGame: bool = false

## The delay after processing each [TurnBasedEntity] PER PHASE (Begin/Execute/End). May be used for aesthetics or debugging.
## NOTE: This delay also occurs even AFTER the LAST entity in the order, even if there is only 1 entity!
## This ensures a delay between multiple moves of the same entity.
@export_range(turnBasedMinimumDelay, 10, 0.05) var turnBasedDelayBetweenEntities: float = 0.5

@export var shouldWaitBetweenTurnStates:  bool = true ## Enables or disables [member turnBasedDelayBetweenStates].

## The delay after each turn state if [member shouldWaitBetweenTurnStates]: Begin → Execute → End. May be used for aesthetics or debugging.
## NOTE: The delay will occur BEFORE [member TurnBasedCoordinator.stateMachine] transitions to the next state.
## NOTE: This delay also occurs even AFTER the "End" phase! This ensures a delay between the end of the previous turn and the beginning of the next turn.
@export_range(turnBasedMinimumDelay, 10, 0.05) var turnBasedDelayBetweenStates: float = 0.25

#endregion


#region Debugging
@export_category("Debugging")

@export var debugAutoLoads:  bool = OS.is_debug_build()

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

## Displays a checkered grid parallax background, to assist with pixel-perfect alignment etc.
@export var showDebugBackground: bool = true:
	set(newValue):
		showDebugBackground = newValue
		if Debug.debugBackground: Debug.debugBackground.visible = newValue

#endregion

#endregion
