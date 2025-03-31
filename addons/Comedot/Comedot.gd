## Comedot Plugin. Adds a custom dock ("Comedock") to the Godot Editor that provides convenience features for quickly creating [Entity] and [Component] objects.
## NOTE: This plugin is NOT necessary for using Comedot.
## Only `Entity.gd` and the scripts in the `Components` folder (and the AutoLoads etc. that they depend on) are the core functionality of Comedot.

@tool
class_name ComedotPlugin # TBD: Is this needed? Are there any side effects?
extends EditorPlugin

# TODO: Menu item shortcut customization: List it in the Editor's Command Palette
# FIXME: BUG: Menu shortcuts only work when the Scene Editor is in focus, not any other dock etc.?
# TODO: Fix the Entity & Component icons SVG


#region Constants
const pluginPath		:= "res://addons/Comedot"
const pluginsettingsPath:= "addons/Comedot"

const entityTypeName	:= &"Comedot Entity"
const entityScript		:= preload("res://Entities/Entity.gd")
const entityIcon		:= preload("res://Assets/Icons/Entity.svg")

const componentTypeName	:= &"Comedot Component"
const componentScript	:= preload("res://Components/Component.gd")
const componentIcon		:= preload("res://Assets/Icons/Component.svg")
#endregion


func _enter_tree() -> void:
	printLog("Plugin _enter_tree()")
	addCustomTypes()
	# `call_deferred` because Godot seems to be loading this "too soon" and raising errors.
	addDock.call_deferred()
	addMenuItems.call_deferred()


func _exit_tree() -> void:
	removeMenuItems()
	removeDock()
	removeCustomTypes()


func _get_plugin_icon() -> Texture2D:
	return componentIcon


static func printLog(message: String) -> void:
	print(str("Comedot:  ", message)) # Extra space to align with "Comedock: " :)


static func printWarning(message: String) -> void:
	var warningMessage: String = str("Comedot:  WARNING: ", message) 
	print(warningMessage)
	push_warning(warningMessage)


static func printError(message: String) -> void:
	var errorMessage: String = str("Comedot:  WARNING: ", message)
	print(errorMessage)
	push_error(errorMessage)


#region Custom Types

func addCustomTypes() -> void:
	# Entity
	add_custom_type(entityTypeName, "Node2D", entityScript, entityIcon)

	# Component
	add_custom_type(componentTypeName, "Node", componentScript, componentIcon)


func removeCustomTypes() -> void:
	remove_custom_type(entityTypeName)
	remove_custom_type(componentTypeName)

#endregion


#region Components Dock

var componentsDock: ComponentsDock


func addDock() -> void:
	componentsDock = preload("res://addons/Comedot/ComponentsDock.tscn").instantiate()
	componentsDock.plugin = self as EditorPlugin
	self.add_control_to_dock(DOCK_SLOT_LEFT_BR, componentsDock) #add_control_to_dock(DOCK_SLOT_LEFT_BR, componentsDock)
	self.set_dock_tab_icon(componentsDock, componentIcon)


func removeDock() -> void:
	remove_control_from_docks(componentsDock)
	componentsDock.queue_free()

#endregion


#region Custom Menu Items

const componentMenuItem := "New Component in Selected Folder..."
# TBD: const newComponentInFolderShortcutPath := pluginPath + "/newComponentInFolderShortcut"
var newComponentInFolderShortcut: Shortcut


func addMenuItems() -> void:
	self.add_tool_menu_item(componentMenuItem, componentsDock.createNewComponentInSelectedFolder)
	self.newComponentInFolderShortcut = load("res://addons/Comedot/NewComponentInFolderShortcut.tres")
	# TBD: ProjectSettings.set_setting(newComponentInFolderShortcutPath, newComponentInFolderShortcut)
	printLog(str("Added menu item: Project → Tools → ", componentMenuItem, " Shortcut: ", newComponentInFolderShortcut.get_as_text()))


func removeMenuItems() -> void:
	newComponentInFolderShortcut = null
	# TBD: ProjectSettings.clear(newComponentInFolderShortcutPath)
	# TBD: ProjectSettings.save()
	self.remove_tool_menu_item(componentMenuItem)


## Handles keyboard shortcuts for custom menu items
func _shortcut_input(event: InputEvent) -> void:
	# Handle shortcut only once, only when pressed
	if not event.is_pressed() or event.is_echo():
		return

	if newComponentInFolderShortcut.matches_event(event):
		componentsDock.createNewComponentInSelectedFolder()

#endregion


#region Maintenance

## Checks all component `".tscn"` Scene files for any descrepancies or configuration mistakes.
## Returns `true` if all components are OK.
## NOTE: May not include hidden or otherwise inaccessible files.
## @experimental
static func verifyAllComponents(rootPath: String = "res://Components") -> bool:
	var areAllComponentsOK: bool = true # Assume all is OK even if there are no components
	var subfoldersToScan: PackedStringArray

	printLog("Scanning for all Component .tscn Scene files from \"res://\"…")
	subfoldersToScan = Tools.findAllSubfolders(rootPath)

	# Create variables here once, instead of in every loop iteration
	var count:		int
	var scene:	  	PackedScene
	var instance: 	Node
	var doesFilenameEndInComponent: bool

	for folder in subfoldersToScan:
		for file in DirAccess.get_files_at(folder):
			if file.ends_with(".tscn"):
				count += 1
				file = folder + "/" + file # Append the folder path because Godon't
				doesFilenameEndInComponent = file.ends_with ("Component.tscn") # Check once to reuse in multiple tests
				
				scene = ResourceLoader.load(file) # Load the scene
				if scene: instance = scene.instantiate() # Instantiate the scene

				if doesFilenameEndInComponent:
					# TEST 1: Does the filename end in "Component" but cannot be instantiated?
					if not scene:
						printError("Cannot load Component Scene: " + file)
						areAllComponentsOK = false
						continue
					elif not instance or not is_instance_valid(instance):
						printError("Cannot instantiate Component Scene: " + file)
						areAllComponentsOK = false
						continue

					# TEST 2: Is the file named "…Component" but is not a Component object?
					elif not is_instance_of(instance, Component):
						printWarning("Filename ends in \"Component\" but Object Type is not Component: " + file)
						areAllComponentsOK = false
						continue

				# Did we load a valid Component instance?
				if is_instance_valid(instance) and is_instance_of(instance, Component):

					# TEST 3: Is it in the "Components" Group?
					if not instance.is_in_group(Global.Groups.components):
						printWarning("Component root node is not in \"" + Global.Groups.components + "\" group: " + file)
						areAllComponentsOK = false
						continue

	if areAllComponentsOK: printLog(str("verifyAllComponents(): ", count, " components checked. All OK."))
	else: printWarning(str("verifyAllComponents(): ", count, " components checked. SOME TESTS FAILED!"))
	return areAllComponentsOK

#endregion
