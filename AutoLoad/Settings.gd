## Manages user settings and saves them in a configuration file.

# class_name Settings
extends Node

# TODO: Better comments & documentation
# TBD: Settings should be `static` to enforce a "single source of truth" because there shouldn't be multiple instances,
# but we cannot elegantly do that because of dynamic properties, signals etc. :()


#region Comedot Project Settings

## The main scene of your game to launch when the player chooses "Start" on the Main Menu.
static var mainGameScene:		PackedScene

static var shouldAlertOnError:	bool = OS.is_debug_build() # TODO: Add toggle in Start.gd

static var saveFilePath:		StringName = &"user://SaveGame.scn"

#endregion


#region Player Preferences / Game-specific Settings

# NOTE: Properties will be handled dynamically via the `settingsDictionary` Dictionary and the `_get_property_list()`, `_get()` and `_set()` methods.
# Dynamic/implicit settings will be saved/loaded via `getSetting()` and `saveSetting()` which may also be called manually.
# Settings with customized behavior must be added manually as explicit normal properties.

## A [Dictionary] where the key is the name of a setting and the property via which it will be accessed, and the value is an instance of the [Setting] inner class.
var settingsDictionary: Dictionary[StringName, Setting] = {
	SettingNames.windowWidth:	Setting.new(SettingNames.windowWidth,	SectionNames.projectSettings,	TYPE_INT,	1920),
	SettingNames.windowHeight:	Setting.new(SettingNames.windowHeight,	SectionNames.projectSettings,	TYPE_INT,	1080),

	SettingNames.musicVolume:	Setting.new(SettingNames.musicVolume,	SectionNames.audio,	TYPE_FLOAT,	0.0),
	SettingNames.sfxVolume:		Setting.new(SettingNames.sfxVolume,		SectionNames.audio,	TYPE_FLOAT,	0.0),
	}

# Explicit properties for settings with customized behavior

var gravity: int: # Not accessed via file. An example of an "abstraction" for a value from [ProjectSettings].
	get: return    ProjectSettings.get_setting(projectSettingsPaths[SettingNames.gravity], 980.0)
	set(newValue): ProjectSettings.set_setting(projectSettingsPaths[SettingNames.gravity], newValue)

#endregion


#region Constants

const configFilePath	:= "user://Settings.cfg"

## A static list of names for settings, to prevent typing mistakes.
class SettingNames:
	const windowWidth	:= &"windowWidth"
	const windowHeight	:= &"windowHeight"
	const musicVolume	:= &"musicVolume"
	const sfxVolume		:= &"sfxVolume"
	const gravity		:= &"gravity"

## A static list of names for the sections (categories) that settings may be grouped under, to prevent typing mistakes.
class SectionNames:
	const default			:= &"General"
	const projectSettings	:= &"GodotProjectSettings"
	const audio				:= &"Audio"

## A [Dictionary] where the key is the name of a setting such as [member windowWidth] and the value is a path for [ProjectSettings].
const projectSettingsPaths: Dictionary[StringName, String] = {
	SettingNames.windowWidth:	"display/window/size/window_width_override",
	SettingNames.windowHeight:	"display/window/size/window_height_override",
	SettingNames.gravity:		"physics/2d/default_gravity",
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


#region Setting Inner Class

## A structure which defines the name of a setting, which is also its "key" in the configuration file,
## its section/category in the file,
## the type allowed for its value (e.g. integer or string),
## and the default value if the setting is missing from the file.
class Setting:
	var name:	 StringName
	var section: StringName ## If omitted, [const SectionNames.default] will be used.
	var type:	 Variant.Type
	var default: Variant

	var logName: String:
		get: return str(self, " [", section, "] ", name, ": ", type_string(type), " (default = ", default, ")")

	func _init(initName: StringName, initSection: StringName, initType: Variant.Type, initDefault: Variant) -> void:
		self.name	 = initName
		self.section = initSection
		self.type	 = initType
		self.default = initDefault

		if typeof(default) != type:
			Debug.printWarning(str("Incorrect type for default: ", default, " is not ", type_string(type)), self.logName) # TBD: Should this be an error?

#endregion


#region Initialization

func _ready() -> void:
	Debug.printLog("_ready() Loading user preferences from configuration file...", "Settings.gd")
	loadConfig()
	loadProjectUserSettings()
	loadAudioSettings()


func loadConfig() -> bool:
	printLog("loadConfig() " + configFilePath)
	self.configFile = ConfigFile.new()

	# Load data from the file.
	var error: Error = configFile.load(self.configFilePath)

	if error == Error.OK:
		return true
	else:
		Debug.printError(str("Error ", error, " — Cannot load settings file: ", self.configFilePath), self)
		return false


## Loads user settings which are counterpart to the Godot [ProjectSettings] such as window size.
func loadProjectUserSettings() -> void:
	self.get_window().size = (Vector2i(self.windowWidth, self.windowHeight))


func loadAudioSettings() -> void:
	var musicBus: int = AudioServer.get_bus_index(Global.AudioBuses.music)
	var sfxBus:   int = AudioServer.get_bus_index(Global.AudioBuses.sfx)
	AudioServer.set_bus_volume_db(musicBus,	getSetting(SettingNames.musicVolume, 0.0))
	AudioServer.set_bus_volume_db(sfxBus,	getSetting(SettingNames.sfxVolume, 0.0))

#endregion


#region External Interface

## Dynamic properties
func _get_property_list() -> Array[Dictionary]:
	var propertyDictionaries: Array[Dictionary]

	for propertyName: StringName in settingsDictionary.keys():
		var setting: Setting = settingsDictionary[propertyName]
		var propertyDictionary: Dictionary[String, Variant]
		propertyDictionary["name"] = propertyName
		propertyDictionary["type"] = setting.type # TBD: What to do if type is missing?
		propertyDictionaries.append(propertyDictionary)

	return propertyDictionaries


## Handles dynamic properties.
func _get(propertyName: StringName) -> Variant:
	if shouldShowDebugInfo and not settingsDictionary.has(propertyName):
		printLog(str("_get() No Setting defined with propertyName: ", propertyName, " — Attempting to read from file"))

	# NOTE: Try reading the setting from file even if it has not been defined as a property.
	return self.getSetting(propertyName)

	# return null # Returning `null` means the property should be handled normally.


## Fetches a [Setting] matching the [param propertyName] key from the [member settingsDictionary] and reads it from the [member configFile].
## If no such [Setting] is explicitly defined, then this method will still attempt to access the file for setting with a matching key from the [const SectionNames.default] section.
func getSetting(propertyName: StringName, defaultIfUndefined: Variant = null) -> Variant:
	var setting: Setting = settingsDictionary.get(propertyName)
	if setting:
		return getSettingFromFile(setting.section, setting.name, setting.default)
	else:
		printWarning(str("getSetting() No Setting defined with propertyName: ", propertyName, " — Attempting to read from file anyway with defaultIfUndefined: ", defaultIfUndefined))
		return getSettingFromFile(SectionNames.default, propertyName, defaultIfUndefined)


## Handles dynamic properties.
func _set(propertyName: StringName, value: Variant) -> bool:
	if shouldShowDebugInfo and not settingsDictionary.has(propertyName):
		printLog(str("_set() No Setting defined with propertyName: ", propertyName, " — Saving to file anyway: ", value))

	# NOTE: Save the setting to file even if it has not been defined as a property.
	self.saveSetting(propertyName, value)
	return true

	# return false # Returning `false` means the property should be handled normally.


## Fetches a [Setting] matching the [param propertyName] key from the [member settingsDictionary] and saves it to the [member configFile].
## If no such [Setting] is explicitly defined, then this method will still attempt to access the file for setting with a matching key from the [const SectionNames.default] section.
func saveSetting(propertyName: StringName, newValue: Variant) -> void:
	var setting: Setting = settingsDictionary.get(propertyName)

	if setting:
		if newValue != getSettingFromFile(setting.section, setting.name, setting.default):
			saveSettingToFile(setting.section, setting.name, newValue)
			self.didChange.emit(setting.name, newValue)
		else:
			printLog(str("saveSetting() value already in file, not saving: ", setting.name, " == ", newValue))

	else:
		printWarning(str("saveSetting() No Setting defined with propertyName: ", propertyName, " — Saving to file anyway: ", newValue))
		saveSettingToFile(SectionNames.default, propertyName, newValue)

#endregion


#region Configuration File Management

func getSettingFromFile(section: StringName, key: StringName, default: Variant = null) -> Variant:
	if section.is_empty(): section = SectionNames.default

	if default == null: # NOTE: Do NOT check `not default` because it will cause a default value of 0 to be interpreted as a missing default!
		printWarning("No default specified for setting: " + key)

	var value: Variant = configFile.get_value(section, key, default)

	# Verify that the value retrieved from the config file is the correct type
	if not validateType(key, value):
		if default != null: value = default # NOTE: Check for `null` specifically to allow defaults of 0.
		else: return null

	if shouldShowDebugInfo:
		var textForDefault: String = "" if configFile.has_section_key(section, key) else " (default)"
		printLog(str("getSetting() [", section, "] ", key, ": ", value, textForDefault))

	return value


## Checks the [member allowedTypes] [Dictionary] to make sure that the value for a setting stored in the config file is of the correct type, such as numbers or text.
func validateType(settingName: StringName, value: Variant) -> bool:
	var setting: Setting = settingsDictionary.get(settingName)

	if not setting:
		printWarning(str("validateType() No Setting defined with name: " + settingName))
		return false

	var allowedType: Variant.Type = setting.type

	if not allowedType:
		printWarning("Setting does not specify an allowed type: " + setting.name)
		return false

	if typeof(value) == allowedType:
		return true
	else:
		printWarning(str("Incorrect value type in configuration file for setting: ", setting.name, ": ", value, " is not ", type_string(allowedType)))
		return false


func saveSettingToFile(section: String, key: String, value: Variant) -> void:
	if section.is_empty(): section = SectionNames.default
	if shouldShowDebugInfo: printLog(str("saveSetting() section: ", section, " key: ", key, " ← ", value))

	configFile.set_value(section, key, value)

	# Save the file (overwrite if already exists).
	configFile.save(self.configFilePath)

#endregion


func printLog(message: String) -> void:
	if shouldShowDebugInfo: Debug.printDebug(message, self)


func printWarning(message: String) -> void:
	Debug.printWarning(message, self)
