## "Boots" and initializes the Comedot Framework and applies global flags.
## ATTENTION: This script MUST be attached to the root node of the main scene of your game.
## Most debugging flags default to `true` when running in a debug build.
## NOTE: If you need custom functionality for your main scene's root node, such as initializing the game-specific environment,
## then your script must `extends Start` and if you override [method _ready], your ready method MUST also call `super._ready()`.

class_name Start
extends CanvasItem


#region Framework Settings
@export_category("Comedot")


#region General
@export_group("General")

## The path of the main scene of your game to launch when the player chooses "Start" on the Main Menu.
## If omitted, then [member Settings.mainGameScenePath] remains unmodified.
## This is not a [PackedScene] Resource to avoid circular references or load()ing before it is needed.
@export_file("*.tscn") var mainGameScenePath: String:
	set(newValue):
		if newValue != mainGameScenePath:
			mainGameScenePath = newValue
			Settings.mainGameScenePath = newValue


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


## Called when the scene enters the tree for the first time.
## IMPORTANT: A subclass which `extends Start` and overrides [method _ready] MUST call `super_ready()`
func _ready() -> void:
	startComedot()


func startComedot() -> void:
	printLog("[b]_ready()[/b]")
	Global.hasStartScript = true
	Debug.performFrameworkChecks() # Update the warning about missing Start script
	applyGlobalFlags()


func applyGlobalFlags() -> void:
	Debug.shouldPrintDebugLogs		= self.shouldPrintDebugLogs
	Debug.debugWindow.visible		= self.showDebugWindow if OS.is_debug_build() else false
	Debug.showDebugLabels			= self.showDebugLabels
	Debug.debugBackground.visible	= self.showDebugBackground

	if not mainGameScenePath.is_empty():
		Settings.mainGameScenePath	= self.mainGameScenePath

	# 🎶
	GlobalSonic.musicFolder			= self.musicFolder
	GlobalSonic.loadMusicFolder()

	GlobalSonic.currentMusicIndex	= self.musicIndexToPlayOnStart

	if not self.musicFileToPlayOnStart.is_empty():
		GlobalSonic.playMusic(self.musicFileToPlayOnStart)
	elif shouldPlayRandomMusicIndex:
		GlobalSonic.playRandomMusicIndex()
	else:
		GlobalSonic.playMusicIndex(self.musicIndexToPlayOnStart)


func printLog(message: String) -> void:
	Debug.printLog(message, str("[b]", self.get_script().resource_path.get_file(), "[/b] ", self), "WHITE", "WHITE")
