## AutoLoad
## Global data and code provided by the framework for all games, such as constants, flags and helper functions etc.
## For scene management & transitions: see SceneManager.gd
## For player control & input actions: see GlobalInput.gd
## For window management, & visuals & sounds that must be present in every scene: see GlobalUI.gd
## To save & load the game state: see GameState.gd

# class_name Global
extends Node


#region Project-Specific Flags

## ATTENTION: This flag is set by the [Start] script which must be attached to the root node of the main scene of your game.
static var hasStartScript:		bool = false

#endregion


#region Constants

# NOTE: Classes containing a list of constants are named plural, so as to be more intuitive and not be confused with a more general type, i.e. "Actions" vs "Action".

const frameworkTitle	:= &"Comedot"


class Groups:
	const components	:= &"components"
	const entities		:= &"entities"

	const players		:= &"players"
	const enemies		:= &"enemies"
	const hazards		:= &"hazards"
	const collectibles	:= &"collectibles"
	const interactions	:= &"interactions"
	const targetables	:= &"targetables"
	const zones			:= &"zones"

	const turnBased		:= &"turnBased"
	const audio			:= &"audio" ## Temporary sound effects


class AudioBuses:
	const master:= &"Master"
	const sfx	:= &"SFX"
	const music	:= &"Music"


## A list of names for the custom data layer types that [TileMapLayer] Tile Sets may set on Tiles.
## For dynamic runtime data on CELLS, use [TileMapLayerWithCustomCellData].
class TileMapCustomData:
	const isWalkable	:= &"isWalkable"	## Tile is vacant. # TBD: Rename to isOccupiable?
	const isBlocked		:= &"isBlocked"		## Impassable terrain or object

	const isOccupied	:= &"isOccupied"	## Is occupied by a character
	const occupant		:= &"occupant"		## The entity occupying the tile

	const isDestructible	:= &"isDestructible"	## Tile may be damaged by a [TileDamageComponent]
	const nextTileOnDamage	:= &"nextTileOnDamage"	## If [member isDestructible], the Cell will be changed to the Tile coordinates specified here. If there is no next tile, the Cell will be destroyed/removed from the Map.

#endregion


#region Initialization

static func _static_init() -> void:
	print_rich("[color=WHITE]Global.gd[/color] _static_init()")
	printInitializationMessage()


static func printInitializationMessage() -> void:
	print_rich("[color=white][b]" + Global.frameworkTitle)

	var projectTitle: String = ProjectSettings.get_setting("application/config/name", "Comedot")
	if projectTitle.to_upper() != Global.frameworkTitle.to_upper():
		print_rich("[color=white]Project: " + projectTitle)

#endregion


#region Save & Load

## Takes a screenshot and saves it as a JPEG file in the "user://" folder.
## @experimental
func screenshot(titleSuffix: String = "") -> void:  # NOTE: Cannot be `static` because of `self.get_viewport()`
	# THANKS: CREDIT: https://stackoverflow.com/users/4423341/bugfish — https://stackoverflow.com/questions/77586404/take-screenshots-in-godot-4-1-stable
	# TBD: Is the `await` necessary?
	var date := Time.get_date_string_from_system().replace(".","-")
	var time := Time.get_time_string_from_system().replace(":","-")

	var screenshotPath := "user://" + "Comedot Screenshot " + date + " " + time
	if not titleSuffix.is_empty(): screenshotPath += " " + titleSuffix
	screenshotPath += ".jpeg"

	var screenshotImage := self.get_viewport().get_texture().get_image() # Capture what the player sees
	screenshotImage.save_jpg(screenshotPath)

	GlobalUI.createTemporaryLabel(str("Screenshot ", time + " " + titleSuffix))

#endregion
