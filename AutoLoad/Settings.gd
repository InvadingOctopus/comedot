## Manages user settings and saves them in a configuration file.

# class_name Settings
extends Node


#region Project-Specific Settings

## The main scene of your game to launch when the player chooses "Start" on the Main Menu.
static var mainGameScene:		PackedScene

static var shouldAlertOnError:	bool = true # TODO: Add toggle in Start.gd # TBD: Should this be `OS.is_debug_build()`?

static var saveFilePath:		StringName = &"user://SaveGame.scn"

#endregion


#region Settings

var windowWidth: int:
	get: return getSetting(SettingNames.windowWidth)
	set(newValue): saveSetting(SettingNames.windowWidth, newValue)

var windowHeight: int:
	get: return getSetting(SettingNames.windowHeight)
	set(newValue): saveSetting(SettingNames.windowHeight, newValue)

var gravity: int:
	get: return getSetting(SettingNames.gravity)
	set(newValue): # Do not save gravity to file
		ProjectSettings.set_setting(projectSettingsPaths[SettingNames.gravity], newValue)

#endregion


#region Constants

const configFilePath	:= "user://Settings.cfg"

## A static list of names for settings, to prevent typing mistakes.
class SettingNames:
	const windowWidth	:= &"windowWidth"
	const windowHeight	:= &"windowHeight"
	const gravity		:= &"gravity"

## A static list of names for the sections (categories) that settings may be grouped under, to prevent typing mistakes.
class SectionNames:
	const projectSettings := &"ProjectSettings"

## A [Dictionary] where the key is the name of a setting such as [member windowWidth] and the value is its section (category) header in the configuration file.
const sections: Dictionary[StringName, StringName] = {
	SettingNames.windowWidth:	SectionNames.projectSettings,
	SettingNames.windowHeight:	SectionNames.projectSettings,
	SettingNames.gravity:		SectionNames.projectSettings,
	}

## A [Dictionary] where the key is the name of a setting such as [member windowWidth] and the value is the valid type code allowed for that setting, such as integer (`TYPE_INT`) etc.
const allowedTypes: Dictionary[StringName, Variant.Type] = {
	SettingNames.windowWidth:	TYPE_INT,
	SettingNames.windowHeight:	TYPE_INT,
	SettingNames.gravity:		TYPE_INT,
}

## A [Dictionary] where the key is the name of a setting such as [member windowWidth] and the value is a path for [ProjectSettings].
const projectSettingsPaths: Dictionary[StringName, String] = {
	SettingNames.windowWidth:	"display/window/size/window_width_override",
	SettingNames.windowHeight:	"display/window/size/window_height_override",
	SettingNames.gravity:		"physics/2d/default_gravity",
	}

## A [Dictionary] where the key is the name of a setting such as [member windowWidth] and the value is the default fallback in case of a missing [ConfigFile].
var defaults: Dictionary[StringName, Variant] = {
	SettingNames.windowWidth:	ProjectSettings.get_setting(projectSettingsPaths[SettingNames.windowWidth]),
	SettingNames.windowHeight:	ProjectSettings.get_setting(projectSettingsPaths[SettingNames.windowHeight]),
	SettingNames.gravity:		ProjectSettings.get_setting(projectSettingsPaths[SettingNames.gravity]),
	}

#endregion


#region State

var configFile: ConfigFile:
	get:
		if not configFile: loadConfig()
		return configFile

var shouldShowDebugInfo: bool = OS.is_debug_build()

#endregion


#region Signals
signal didChange(settingName: StringName, newValue: Variant)
#endregion


func _ready() -> void:
	loadConfig()
	loadProjectUserSettings()


func loadConfig() -> bool:
	printLog("loadConfig() " + configFilePath)
	self.configFile = ConfigFile.new()

	# Load data from the file.
	var error: Error = configFile.load(self.configFilePath)

	if error == Error.OK:
		return true
	else:
		Debug.printError(str("Error ", error, " — Cannot load settings file: ", self.configFilePath), str(self))
		return false


## Loads user settings which are counterpart to the Godot [ProjectSettings] such as window size.
func loadProjectUserSettings() -> void:
	self.get_window().size = (Vector2i(self.windowWidth, self.windowHeight))


func getSection(settingName: StringName) -> StringName:
	var section: StringName = sections.get(settingName)

	if not section.is_empty():
		return section
	else:
		Debug.printWarning("No section specified for setting: " + settingName, str(self))
		return ""


func getSetting(settingName: StringName) -> Variant:
	var section: StringName = getSection(settingName)
	if section.is_empty(): return null
	return getSettingFromFile(section, settingName)


func getSettingFromFile(section: StringName, key: StringName) -> Variant:
	var default: Variant = defaults.get(key)

	if not default: Debug.printWarning("No default specified for setting: " + key, str(self))

	var value: Variant = configFile.get_value(section, key, default)

	# Verify that the value retrieved from the config file is the correct type
	if not validateType(key, value):
		if default: value = default
		else: return null

	if shouldShowDebugInfo:
		var textForDefault: String = "" if configFile.has_section_key(section, key) else " (default)"
		printLog(str("getSetting() [", section, "] ", key, ": ", value, textForDefault))

	return value


## Checks the [member allowedTypes] [Dictionary] to make sure that the value for a setting stored in the config file is of the correct type, such as numbers or text.
func validateType(settingName: StringName, value: Variant) -> bool:
	var allowedType: Variant.Type = self.allowedTypes.get(settingName)

	if not allowedType:
		Debug.printWarning("Missing valid type for setting: " + settingName, str(self))
		return false

	if typeof(value) == allowedType:
		return true
	else:
		Debug.printWarning(str("Incorrect type for setting: ", settingName, ": ", value, " is not ", type_string(allowedType)), str(self))
		return false


func saveSetting(settingName: StringName, value: Variant) -> void:
	var section: StringName = getSection(settingName)
	if section.is_empty(): return

	if value != getSetting(settingName):
		saveSettingToFile(section, settingName, value)
		self.didChange.emit(settingName, value)
	else:
		printLog(str("saveSetting() value already set, not saving: ", settingName, " == ", value))


func saveSettingToFile(section: String, key: String, value: Variant) -> void:
	if shouldShowDebugInfo: printLog(str("saveSetting() section: ", section, " key: ", key, " ← ", value))

	configFile.set_value(section, key, value)

	# Save the file (overwrite if already exists).
	configFile.save(self.configFilePath)


func printLog(message: String) -> void:
	if shouldShowDebugInfo: Debug.printDebug(message, str(self))
