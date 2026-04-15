## Comedot Plugin. Adds a custom dock ("Comedock") to the Godot Editor that provides convenience features for quickly creating [Entity] and [Component] objects.
## NOTE: This plugin is NOT necessary for using Comedot.
## Only `Entity.gd` and the scripts in the `Components` folder (and the AutoLoads etc. that they depend on) are the core functionality of Comedot.

@tool
class_name ComedotPlugin # Could be useful for accessing verifyComponent() etc.
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
	# WORKAROUND: call_deferred() because Godot seems to be loading this "too soon" and raising errors.
	# CHECK: Should we `await`?
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
	var errorMessage: String = str("Comedot:  ERROR: ", message)
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
	self.add_control_to_dock(DOCK_SLOT_LEFT_BR, componentsDock)
	self.set_dock_tab_icon(componentsDock, componentIcon)


func removeDock() -> void:
	if not is_instance_valid(componentsDock): # Make sure just in case the Dock was already destroyed somehow
		componentsDock = null
		return
	remove_control_from_docks(componentsDock)
	componentsDock.queue_free()

#endregion


#region Custom Menu Items

const componentMenuItem := "New Component in Selected Folder..."
# TBD: const newComponentInFolderShortcutPath := pluginPath + "/newComponentInFolderShortcut"
var newComponentInFolderShortcut: Shortcut


func addMenuItems() -> void:
	if not is_instance_valid(componentsDock):
		printWarning("addMenuItems(): componentsDock not valid")
		return

	self.newComponentInFolderShortcut = load("res://addons/Comedot/NewComponentInFolderShortcut.tres")
	if not newComponentInFolderShortcut:
		printWarning("Missing Shortcut resource for \"" + componentMenuItem + "\"")
		return
	
	self.add_tool_menu_item(componentMenuItem, componentsDock.createNewComponentInSelectedFolder)
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
	if not event.is_pressed() or event.is_echo() \
	or not componentsDock or not newComponentInFolderShortcut: # Make sure initialization is complete
		return

	if newComponentInFolderShortcut.matches_event(event):
		componentsDock.createNewComponentInSelectedFolder()

#endregion


#region Maintenance

static func verifyComponent(file: String) -> bool:
	# First, the initial "guard" checks without which other checks cannot be performed

	# TEST 1: Can the file be loaded?
	var scene: PackedScene = ResourceLoader.load(file)
	if not scene:
		printError("verifyComponent(): Cannot load Scene: " + file)
		return false

	# TEST 2: Can the scene be instantiated as a node?
	var instance: Node = scene.instantiate() if scene else null # Ensure `null` if invalid
	if not instance or not is_instance_valid(instance):
		printError("verifyComponent(): Cannot instantiate Scene: " + file)
		# TBD: Should we free() the `scene`?
		return false

	# TEST 3: Is the node not a Component object?
	if not is_instance_of(instance, Component):
		printError("verifyComponent(): Node object type is not Component: " + file)
		instance.free() # Cleanup
		return false

	# After making sure we loaded a valid Component instance,
	# Now we do the secondary tests that may produce multiple warnings

	var isComponentFilename: bool = file.ends_with("Component.tscn") or file.ends_with("ComponentBase.tscn") # Check once to reuse in multiple tests
	var isAbstract:			 bool = file.ends_with("Base.tscn")
	var hasIssues:			 bool

	# TEST 4: Is it a consistent/conventional filname??
	if not isComponentFilename:
		printWarning("verifyComponent(): Filename does not end in \"Component\" or \"ComponentBase\": " + file)
		hasIssues = true

	# TEST 5: Is it in the "Components" Group?
	if not instance.is_in_group(Global.Groups.components):
		printWarning("Component root node is not in \"" + Global.Groups.components + "\" group: " + file)
		hasIssues = true

	# TEST 6: Is it a turn-based component but not in the "Turn-Based" Group?
	if  is_instance_of(instance, TurnBasedComponent) and not instance.is_in_group(Global.Groups.turnBased):
		printWarning("Component is TurnBasedComponent but root node is not in \"" + Global.Groups.turnBased + "\" group: " + file)
		hasIssues = true

	# Cleanup
	if  is_instance_valid(instance):
		# Avoid memory leaks just in case
		instance.free() # CHECK: Apparently free() is better than queue_free() here, because these nodes are temporary editor-only instances that were never added to a tree, so immediate cleanup is fine.

	return not hasIssues


## Checks all component `".tscn"` Scene files for any descrepancies or configuration mistakes.
## Returns `true` if all components are OK.
## NOTE: May not include hidden or otherwise inaccessible files.
## @experimental
static func verifyAllComponents(rootPath: String = "res://Components") -> bool:
	# Verify that the root folder is valid, becasue FileSystemTools.findAllSubfolders() returns [] on failure which is indistinguishable from a valid but empty folder.
	if rootPath.is_empty():
		printWarning("verifyAllComponents(): Missing rootPath")
		return false

	var rootDirectory: DirAccess = DirAccess.open(rootPath)
	if not rootDirectory:
		printError("verifyAllComponents(): Cannot open root path: " + rootPath)
		return false

	var subfoldersToScan:	PackedStringArray
	var hasIssues:			bool

	printLog("Scanning for all Component .tscn Scene files from \"res://\"…")
	subfoldersToScan = FileSystemTools.findAllSubfolders(rootPath) # NOTE: Returns [] or [rootPath] on failure

	# Create variables here once, instead of in every loop iteration
	var count: int

	for folder in subfoldersToScan:
		for file in DirAccess.get_files_at(folder):

			# If it's not a scene file there's nothing else to check
			if not file.ends_with(".tscn"): continue

			count += 1
			file   = folder.path_join(file) # Append the folder path because Godon't; path_join() may be better than `+ "/" +` on Windows etc.
			
			if not verifyComponent(file): hasIssues = true

	if not hasIssues: printLog(str("verifyAllComponents(): ", count, " components checked. All OK."))
	else: printWarning(str("verifyAllComponents(): ", count, " components checked. SOME TESTS FAILED!"))
	return not hasIssues

#endregion
