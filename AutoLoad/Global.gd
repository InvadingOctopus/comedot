## AutoLoad
## Global data and code provided by the framework for all games, such as constants, flags and helper functions etc.
## For player control & input actions, see [GlobalInput].
## For visuals and sounds that must be present in every scene, see [GlobalOverlay].

extends Node


#region Project-Specific Flags & Settings

## ATTENTION: This flag is set by the [Start] script which must be attached to the root node of the main scene of your game.
static var hasStartScript:		bool = false

## The main scene of your game to launch when the player chooses "Start" on the Main Menu.
static var mainGameScene:		PackedScene

static var shouldAlertOnError:	bool = true # TODO: Add toggle in Start.gd # TBD: Should this be `OS.is_debug_build()`?

static var saveFilePath:		StringName = &"user://SaveGame.scn"

#endregion

#region Constants

# NOTE: Classes containing a list of constants are named plural, so as to be more intuitive and not be confused with a more general type, i.e. "Actions" vs "Action".

const frameworkTitle		:= &"Comedot"

#region Settings

## Paths to project settings
## NOTE: This is not named "Settings" to avoid any confusion that they may be the actual properties; they're just paths to the values.
class SettingsPaths:
	const gravity		:= &"physics/2d/default_gravity"

#endregion


#region Groups

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

#endregion


class AudioBuses:
	const master:= &"Master"
	const sfx	:= &"SFX"
	const music	:= &"Music"


class TileMapCustomData: ## A list of names for the custom data types that [TileMapLayer] Tile Sets may set on tiles.
	const isWalkable	:= &"isWalkable"	## Tile is vacant
	const isBlocked		:= &"isBlocked"		## Impassable terrain or object

	const isOccupied	:= &"isOccupied"	## Is occupied by a character
	const occupant		:= &"occupant"		## The entity occupying the tile

#endregion


#region Scene Management

func transitionToScene(nextScene: PackedScene, pauseSceneTree: bool = true) -> void: # NOTE: Cannot be `static` because of `self.get_tree()`
	var sceneTree: SceneTree = self.get_tree()
	sceneTree.paused = pauseSceneTree
	await GlobalOverlay.fadeIn() # Fade the overlay in, fade the game out.

	sceneTree.change_scene_to_packed(nextScene)

	await GlobalOverlay.fadeOut() # Fade the overlay out, fade the game in.
	sceneTree.paused = false


## Sets [member SceneTree.paused] and returns the resulting paused status.
func setPause(paused: bool) -> bool: # NOTE: Cannot be `static` because of `self.get_tree()`
	var sceneTree: SceneTree = self.get_tree()
	sceneTree.paused = paused

	GlobalOverlay.showPauseVisuals(sceneTree.paused)
	return sceneTree.paused


## Toggles [member SceneTree.paused] and returns the resulting paused status.
func togglePause() -> bool: # NOTE: Cannot be `static` because of `self.get_tree()`
	# TBD: Should this be more efficient instead of so many function calls?
	return setPause(not self.get_tree().paused)

#endregion


#region Save & Load

## A very rudimentary implementation of saving the entire game state.
## @experimental
func saveGame() -> void: # NOTE: Cannot be `static` because of `self.process_mode`
	# TODO: Implement properly :(
	# BUG:  Does not save all state of all nodes
	# TBD:  Is it necessary to `await` & pause to ensure a reliable & deterministic save?

	GlobalOverlay.createTemporaryLabel("Saving...") # NOTE: Don't `await` here or it will wait for the animation to finish.
	@warning_ignore("redundant_await")
	await Debug.printLog("Saving state → " + Global.saveFilePath) # TBD: await or not?

	var sceneTree := get_tree()
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	sceneTree.paused = true

	Global.screenshot("Save") # DEBUG: Take a screenshop for comparison

	var packedSceneToSave := PackedScene.new()
	packedSceneToSave.pack(sceneTree.get_current_scene())
	ResourceSaver.save(packedSceneToSave, Global.saveFilePath)

	sceneTree.paused = false


## A very rudimentary implementation of loading the entire game state.
## @experimental
func loadGame() -> void:  # NOTE: Cannot be `static` because of `self.process_mode`
	# TODO: Implement properly :(
	# BUG:  Does not restore all state of all nodes
	# TBD:  Is it necessary to `await` & pause to ensure a reliable & deterministic load?

	GlobalOverlay.createTemporaryLabel("Loading...")  # NOTE: Don't `await` here or it will wait for the animation to finish.
	@warning_ignore("redundant_await")
	await Debug.printLog("Loading state ← " + Global.saveFilePath) # TBD: await or not?

	var sceneTree := get_tree()
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	sceneTree.paused = true

	var packedSceneLoaded := ResourceLoader.load(Global.saveFilePath)

	sceneTree.paused = false
	sceneTree.change_scene_to_packed(packedSceneLoaded)
	Global.screenshot("Load") # DEBUG: Take a screenshop for comparison, but BUG: The screenshot gets delayed


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

	GlobalOverlay.createTemporaryLabel(str("Screenshot ", time + " " + titleSuffix))

#endregion
