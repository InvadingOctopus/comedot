## The Comedock :) Scans the `Components` folder and its subfolders to builds a list of the components found, and provides convenience features for quickly adding new [Entity] and [Component] objects.
## NOTE: Assumptions & Limitations: Only scene files with names ending in "Component.tscn" are added. Deeper subfolders are NOT scanned; only the 1st-level subfolders in `/Components/`.

@tool
class_name ComponentsDock
extends Panel

# TODO: More robust scanning; not just filenames ending in "Component" :')
# TODO: Update node name in help label when a selected Entity is renamed.
# TODO: Add option to duplicate an existing Component?


enum EntityTypes {
	# NOTE: MUST correspond to the ids of the Add Entity button's PopupMenu
	# DESIGN: Almost alphabetical, because Node2D has to be first.
	node2D = 0,
	area2D = 1,
	characterBody2D = 2,
	sprite2D = 3,
	}

enum TreeItemButtons {
	# NOTE: MUST correspond to the ids of the TreeItem buttons
	createNewComponent = 0,
	editComponent = 1,
	}

#region Parameters

# TBD: `load` or `preload` or just put paths here?

# NOTE: Convert strings `.to_lower()` before comparing strings
const componentsRootPath		:= "res://Components"
const entitiesRootPath			:= "res://Entities"

const acceptedFileExtension		:= ".tscn"
const acceptedFileSuffix		:= "component.tscn"

const entityBaseScene			:= "res://Entities/Entity.tscn"
const entityBaseScript			:= "res://Entities/Entity.gd"
const entityScriptTemplate		:= "res://Templates/Scripts/Entity/EntityTemplate.gd"

const areaEntityTemplate		:= "res://Templates/Entities/AreaEntityTemplate.tscn"
const bodyEntityTemplate		:= "res://Templates/Entities/CharacterBodyEntityTemplate.tscn"
const spriteEntityTemplate		:= "res://Templates/Entities/SpriteEntityTemplate.tscn"

const componentBaseScene		:= "res://Components/Component.tscn"
const componentScriptTemplate	:= "res://Templates/Scripts/Component/ComponentTemplate.gd"

const componentIcon				:= preload("res://Assets/Icons/Component.svg")
const createComponentIcon		:= preload("res://Assets/Icons/Component.svg") # EditorInterface.get_editor_theme().get_icon("Add", "EditorIcons")

# Access built-in Godot icons as per the documentation: https://docs.godotengine.org/en/stable/classes/class_editorinterface.html#class-editorinterface-method-get-editor-theme
# > When creating custom editor UI, prefer accessing theme items directly from your GUI nodes using the get_theme_* methods.
# Instead of: EditorInterface.get_editor_theme().get_icon()
@onready var folderIcon: Texture2D = self.get_theme_icon(&"Folder", &"EditorIcons")
@onready var sceneIcon:  Texture2D = self.get_theme_icon(&"InstanceOptions", &"EditorIcons")

const categoryColor				:= Color(0.235, 0.741, 0.878) # From Godot Editor's color for folders chosen to be "Blue"
const categoryBackgroundColor	:= Color(0.051, 0.133, 0.184) # From Godot Editor's background color for folders chosen to be "Blue"
const componentBackgroundColor	:= Color(0, 0, 0) # From Godot Editor's background color for folders chosen to be "Blue"
const createNewItemButtonColor	:= Color.LAWN_GREEN
const editComponentButtonColor	:= categoryColor

const defaultHelpLabelText		:= "Select an Entity node in the scene to add Components."
const defaultAddEntityTip		:= "Add a new Entity of the chosen base type to the currently selected node in the Scene Editor."
const editComponentTipPrefix	:= "Open the source scene of "

@export var debugMode: bool = false

#endregion


#region State

var selectedComponentRow: TreeItem
var selectedComponentCategory: TreeItem

var selectedComponentName: String: ## Returns the text of the first column of the selected [member componentsTree] row.
	get: return selectedComponentRow.get_text(0) if selectedComponentRow else ""

var selectedComponentPath: String: ## Returns the metadata of the first column of the selected [member componentsTree] row.
	get: return selectedComponentRow.get_metadata(0) if selectedComponentRow else ""

var selectedComponentCategoryName: String: ## Returns the text of the first column of the selected [member componentsTree] row if it is a folder/category header row..
	get: return selectedComponentCategory.get_text(0) if selectedComponentCategory else ""

# TBD: A better way to handle Dialog state?
var newComponentDialog_chosenFolderPath:	String
var newComponentDialog_chosenComponentName:	String
var newComponentDialog_parentTreeItem:		TreeItem

# var isMouseInLogo: bool # TBD: For any future animations

#endregion


#region Signals
#endregion


#region Dependencies

var plugin: EditorPlugin

var fileSystem: EditorFileSystem:
	get:
		if not fileSystem: fileSystem = EditorInterface.get_resource_filesystem()
		return fileSystem

var inspector:  EditorInspector

@onready var componentsTree: Tree = %ComponentsTree
@onready var newComponentDialog: ConfirmationDialog = $NewComponentDialog
@onready var newComponentNameTextBox: LineEdit = %NewComponentNameTextBox
@onready var newComponentFolderLabel: Label	   = %NewComponentFolderLabel

#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# NOTE: If we are not running as the actual plugin, i.e. the Dock is being edited in the Editor, then skip the setup.
	if plugin:
		printLog("_ready()")
		setupUI()


func printLog(message: String) -> void:
	print(str("Comedock: ", message))


func printError(message: String) -> void:
	var errorMessage: String = str("Comedock: ERROR: ", message)
	print(errorMessage)
	push_error(errorMessage)


func setupUI() -> void:
	%DebugReloadButton.visible = debugMode
	
	%AddEntityMenuButton.modulate = createNewItemButtonColor
	%AddEntityMenuButton.tooltip_text = defaultAddEntityTip

	$NewComponentDialog.register_text_enter(newComponentNameTextBox)
	%AddEntityMenuButton.get_popup().id_pressed.connect(self.onAddEntityMenu_idPressed)

	%HelpLabel.text = defaultHelpLabelText

	componentsTree.set_column_expand(0, true)
	componentsTree.set_column_expand(1, false) # Prevent the button column from obscuring the component names.

	# RenderingServer.canvas_item_set_clip(get_canvas_item(), true) # TBD: Why? Copied from Godot Plugin Demo sample code.

	# NOTE: The first access to the `res://Components` sometimes seems to fail,
	# so maybe we need to let the Godot Editor have some time to finish scanning the file system?
	printLog("Waiting to scan the Components folder…")
	await get_tree().create_timer(1).timeout
	buildComponentsDirectory.call_deferred() # `call_deferred` to reduce lag?

	# Hook up with Inspector Gadget
	inspector = EditorInterface.get_inspector()
	inspector.edited_object_changed.connect(self.onInspector_editedObjectChanged)

	# Handled in Comedot.gd: plugin.add_tool_menu_item("New Component in Selected Folder", self.createNewComponentInSelectedFolder)

	# TODO: Display the dock if it's hidden (like behind the FileSystem)


#region The Erdtree

func updateComponentsTree() -> void:
	# TODO: Check for changes?
	# NOTE: `call_deferred()` to try to avoid weird first-launch bugs, maybe caused by the Godot Editor scanning the file system.
	buildComponentsDirectory.call_deferred()


func buildComponentsDirectory() -> void:
	if debugMode: printLog("buildComponentsDirectory()")
	if not Engine.is_editor_hint():
		printLog("Not running in editor. Cancelling components scan.")
		return

	# Get all first-level subfolders in the `/Components/` folder
	var componentCategories: Array[EditorFileSystemDirectory] = getSubfolders("Components")
	var _root: TreeItem = componentsTree.create_item()
	var componentsCount: int = 0

	componentsTree.hide_root = true

	for categoryFolder in componentCategories:
		# Create a Tree item for each category folder
		var categoryTreeItem: TreeItem = createCategoryTreeItem(categoryFolder)

		# Get the components in each category folder
		# TODO: Subsubfolders? :')

		for fileIndex in categoryFolder.get_file_count():
			var filePath: String = categoryFolder.get_file_path(fileIndex)
			var fileName: String = categoryFolder.get_file(fileIndex)
			#var fileType: String = categoryFolder.get_file_type(fileIndex) # Not needed

			if fileName.to_lower().ends_with(acceptedFileSuffix):
				var componentName := fileName.trim_suffix(acceptedFileExtension)
				# if debugMode:#printLog(componentName + " " + filePath)

				# Add the component to the Tree
				createComponentTreeItem(filePath, componentName, categoryTreeItem)
				componentsCount += 1

	#if debugMode:
	printLog(str(componentsCount, " Components found & added to list"))

	if componentsCount <= 0:
		printLog("If the list is empty, try the \"Rescan Folders\" button or check the \"\\Components\\\" subfolder of this Godot project.")


## NOT IMPLEMENTED
## @experimental
func findCategoryTreeItemForComponentPath(componentPath: String) -> TreeItem:
	# TODO: Implement
	if componentPath.is_empty(): return null
	return null


func createCategoryTreeItem(categoryFolder: EditorFileSystemDirectory) -> TreeItem:
	var categoryRow:  TreeItem = componentsTree.create_item()
	var categoryName: String   = categoryFolder.get_name()
	var categoryPath: String   = categoryFolder.get_path()

	categoryRow.set_text(0, categoryName)
	categoryRow.set_metadata(0, categoryPath)
	categoryRow.set_tooltip_text(0, categoryPath)

	# Customize the Tree row
	categoryRow.set_icon(0, folderIcon)
	categoryRow.set_icon_modulate(0, categoryColor)
	categoryRow.set_custom_color(0, categoryColor)
	categoryRow.set_custom_bg_color(0, categoryBackgroundColor)
	categoryRow.set_expand_right(0, true)
	categoryRow.set_selectable(0, false)

	# Add a button for creating a new component
	var buttonTooltip := "Create a new Component in the " + categoryName + " folder."
	categoryRow.add_button(1, createComponentIcon, 0, false, buttonTooltip)
	categoryRow.set_text(1, "+")
	categoryRow.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
	categoryRow.set_text_overrun_behavior(1, TextServer.OVERRUN_NO_TRIMMING)
	categoryRow.set_expand_right(1, false)
	categoryRow.set_tooltip_text(1, buttonTooltip)
	categoryRow.set_custom_color(1, createNewItemButtonColor)
	categoryRow.set_button_color(1, 0, createNewItemButtonColor)
	categoryRow.set_custom_bg_color(1, categoryBackgroundColor)

	return categoryRow


func createComponentTreeItem(componentPath: String, componentName: String, categoryTreeItem: TreeItem) -> TreeItem:
	# Sanitize the component name
	# TODO: Get only the last dot "."
	var startOfExtension: int = componentName.findn(".")
	if startOfExtension >= 1: componentName = componentName.substr(0, startOfExtension)
	
	# Create the Tree row item
	var componentItem: TreeItem = componentsTree.create_item(categoryTreeItem) # CHECK: ? Does `create_item()` return existing items if they're already in the Tree?
	componentItem.set_text(0, componentName)
	componentItem.set_metadata(0, componentPath)

	# Customize the Tree row
	# NOTE: PERFORMANCE: Adding icons here seems to slow things down
		#componentItem.set_icon(1, componentIcon)
		#componentItem.set_icon_modulate(1, Color.CORNFLOWER_BLUE) # I am Jack's buggy code :')
		#componentItem.set_icon_max_width(1, 32)
	componentItem.set_expand_right(0, true)
	componentItem.set_text_overrun_behavior(0, TextServer.OVERRUN_TRIM_ELLIPSIS)

	return componentItem


func createComponentRowButtons(componentRow: TreeItem) -> void:
	if not componentRow: return
	# var tooltipText: String = editComponentTipPrefix + selectedComponentName

	componentRow.add_button(1, sceneIcon, 1, false, %EditComponentButton.tooltip_text)
	componentRow.set_text(1, "Edit")
	componentRow.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
	componentRow.set_text_overrun_behavior(1, TextServer.OVERRUN_NO_TRIMMING)
	componentRow.set_expand_right(1, false)
	componentRow.set_tooltip_text(1, %EditComponentButton.tooltip_text)
	componentRow.set_custom_color(1, editComponentButtonColor)
	componentRow.set_button_color(1, 0, editComponentButtonColor)
	#componentRow.set_custom_bg_color(1, componentBackgroundColor) # DISABLED: Makes it different from the selected row background


func removeComponentRowButtons(componentRow: TreeItem) -> void:
	if not componentRow: return
	componentRow.erase_button(1, 0)
	componentRow.set_text(1, "")
	componentRow.set_tooltip_text(1, "")

#endregion


#region UI Events

func onComponentsTree_itemSelected() -> void:
	var selection: TreeItem = componentsTree.get_selected()

	# Clear the previous selection. These values must be reset in any case.

	if selectedComponentRow: removeComponentRowButtons(selectedComponentRow) # Remove the buttons from any previous selection

	selectedComponentRow = null
	selectedComponentCategory = null
	%EditComponentButton.disabled = true
	%EditComponentButton.tooltip_text = "Select a Component in the list to edit its source scene."

	# Is a component row selected?

	if selection.get_text(0).to_lower().ends_with("component"): # TODO: A less crude way of checking for component rows :')
		selectedComponentRow = selection
		selectedComponentCategory = selection.get_parent()
		%EditComponentButton.disabled = false
		%EditComponentButton.tooltip_text = editComponentTipPrefix + selectedComponentName
		createComponentRowButtons(selectedComponentRow)


## Called when a row is double-clicked
func onComponentsTree_itemActivated() -> void:
	getSelectedComponentAndAddToSelectedNode()


func onRefreshButton_pressed() -> void:
	componentsTree.clear()
	buildComponentsDirectory.call_deferred() # `call_deferred` to reduce lag?


func onEditComponentButton_pressed() -> void:
	editSelectedComponent()


func onAddEntityMenu_idPressed(id: int) -> void:
	if debugMode: printLog(str("onAddEntityMenu_idPressed() ", id))
	addNewEntity(id)


func onComponentsTree_buttonClicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	if debugMode: printLog(str("onComponentsTree_buttonClicked() item: ", item, ", button id: ", id))

	# NOTE: Check the button ID because this signal may be emitted by different buttons in different rows
	match id:
		TreeItemButtons.createNewComponent:
			showNewComponentDialog(item.get_metadata(0), "NewComponent", item)
		
		TreeItemButtons.editComponent:
			editSelectedComponent()


func showNewComponentDialog(initialFolder: String, initialName: String = "NewComponent", parentTreeItem: TreeItem = null) -> void:
	# Reset the choices
	newComponentDialog_chosenFolderPath = initialFolder
	newComponentDialog_chosenComponentName = ""
	newComponentDialog_parentTreeItem = parentTreeItem

	newComponentFolderLabel.text = "Folder: " + initialFolder
	newComponentNameTextBox.text = initialName
	
	newComponentDialog.popup_centered()
	newComponentNameTextBox.grab_focus()
	
	# Select the text before "Component" in the name
	var startOfComponentWord: int = newComponentNameTextBox.text.findn("Component")
	if startOfComponentWord >= 1: newComponentNameTextBox.select(0, startOfComponentWord)
	else: newComponentNameTextBox.select_all()


func onNewComponentDialog_confirmed() -> void:
	# Apply the new choices (the folder choide is not modifiable)
	newComponentDialog_chosenComponentName = newComponentNameTextBox.text

	if debugMode: 
		printLog(str("onNewComponentDialog_confirmed() newComponentDialog_chosenFolderPath: ", newComponentDialog_chosenFolderPath, ", newComponentDialog_chosenComponentName: ", newComponentDialog_chosenComponentName))

	# Create the new component
	var newComponentPath: String = createNewComponentOnDisk(newComponentDialog_chosenFolderPath, newComponentDialog_chosenComponentName)
	
	# Add the new component to the Tree UI
	if newComponentDialog_parentTreeItem and not newComponentPath.is_empty():
		createComponentTreeItem(newComponentPath, newComponentPath.get_file(), newComponentDialog_parentTreeItem)


func onComponentsTree_itemEdited() -> void:
	pass #if debugMode: printLog("onComponentsTree_itemEdited()")


## Called when nodes are selected/unselected in the Scene Editor.
func onInspector_editedObjectChanged() -> void:
	var editedObject:	 Object = inspector.get_edited_object()
	var editedNode:		 Node   = editedObject as Node
	var editorSelection: EditorSelection = EditorInterface.get_selection()
	var selectedNodes:	 Array[Node]     = editorSelection.get_selected_nodes()
	# TBD: Do we need all these variables?

	# Update the entity-related UI
	# TBD: Support adding multiple new Entities to more than 1 selected Node?	

	if selectedNodes.size() > 1:
		%AddEntityMenuButton.disabled = true
		%AddEntityMenuButton.tooltip_text = "Cannot add an Entity to more than 1 selected Node in the Scene Editor."
	else:
		%AddEntityMenuButton.disabled = false
		%AddEntityMenuButton.tooltip_text = defaultAddEntityTip

	# Update the component-related UI

	if editedNode is Entity: %HelpLabel.text = str("Double-click a Component from the list to add it to ", editedNode.name)
	else: %HelpLabel.text = defaultHelpLabelText


func onDebugReloadButton_pressed() -> void:
	reloadPlugin.call_deferred() # Let it chill before reloading?


func reloadPlugin() -> void:
	printLog("reloadPlugin")
	EditorInterface.set_plugin_enabled(Global.frameworkTitle, false)
	EditorInterface.set_plugin_enabled(Global.frameworkTitle, true)

#endregion


#region Scene Editing

func addNewEntity(entityType: EntityTypes = EntityTypes.node2D) -> void:
	if debugMode: printLog("addNewEntity()")

	var editorSelection: EditorSelection = EditorInterface.get_selection()
	var selectedNodes:   Array[Node]     = editorSelection.get_selected_nodes()

	# TBD: Support adding multiple new Entities to more than 1 selected Node?

	# Get the first selected node

	if selectedNodes.is_empty():
		selectedNodes = [EditorInterface.get_edited_scene_root()]
	elif selectedNodes.size() > 1:
		printLog("Cannot add Entity to more than 1 selected Node")
		return

	var parentNode: Node = selectedNodes.front()

	# Create a new Entity

	var newEntity: Entity

	# TBD: `load` or `preload`?
	# TODO: CHECK: Is there a better way without `.instantiate()`?

	match entityType:
		EntityTypes.node2D:
			newEntity = load(entityBaseScene).instantiate()
			newEntity.name = "Entity"

		EntityTypes.area2D:
			newEntity = load(areaEntityTemplate).instantiate()
			newEntity.name = "AreaEntity"

		EntityTypes.characterBody2D:
			newEntity = load(bodyEntityTemplate).instantiate()
			newEntity.name = "CharacterBodyEntity"

		EntityTypes.sprite2D:
			newEntity = load(spriteEntityTemplate).instantiate()
			newEntity.name = "SpriteEntity"

		_: printError(str("Invalid entityType: ", entityType))

	if debugMode: printLog(str(newEntity))

	# Add the component to the selected Entity
	EditorInterface.edit_node(parentNode)
	parentNode.add_child(newEntity, true) # force_readable_name
	newEntity.owner = EditorInterface.get_edited_scene_root() # NOTE: For some reason, using `parentNode` directly does not work; the Entity is added to the SCENE but not to the scene TREE dock.

	# Select the new Entity in the Editor, so the user can quickly modify it and add Components to it.
	editorSelection.clear()
	editorSelection.add_node(newEntity)
	EditorInterface.edit_node(newEntity)
	#EditorInterface.set_script(load(entityBaseScript)) # TBD: Needed?

	printLog(str("Added Entity: ", newEntity, " → ", newEntity.get_parent()))

	# Expose the sub-nodes of the new Entity to make it easier to modify any, if needed.
	if %EditableChildrenCheckBox.button_pressed:
		newEntity.get_parent().set_editable_instance(newEntity, true)


func getSelectedComponentAndAddToSelectedNode() -> void:
	# TODO: A more robust way to verifying component files, instead of with just the name or extension.
	if not selectedComponentPath.ends_with(acceptedFileExtension): return
	if debugMode: printLog(str("onComponentsTree_itemActivated() ", selectedComponentName, " ", selectedComponentPath))

	# Convert script paths to scenes, just in case
	var componentScenePath := selectedComponentPath
	if componentScenePath.to_lower().ends_with(".gd"):
		componentScenePath = componentScenePath.replace(".gd", ".tscn")

	addComponentToSelectedNode(componentScenePath)


func addComponentToSelectedNode(componentPath: String) -> void:
	if componentPath.is_empty(): return
	if debugMode: printLog("addComponentToSelectedNode() " + componentPath)

	var editorSelection: EditorSelection = EditorInterface.get_selection()
	var selectedNodes:   Array[Node]     = editorSelection.get_selected_nodes()

	# TBD: Support adding components to more than 1 selected Entity?

	if selectedNodes.is_empty() or selectedNodes.size() != 1:
		#if debugMode:
		printLog("Cannot add Components to more than 1 selected Node")
		return

	var parentNode: Node = selectedNodes.front()

	if not parentNode is Entity:
		# If the selection is a Component, try to select its parent Entity
		if parentNode is Component:
			parentNode = parentNode.get_parent()
		else:
			#if debugMode:
			printLog("Cannot add Component to a non-Entity Node")
			return

	# Create a new instance of the Component
	var newComponentNode: Node = load(componentPath).instantiate()
	newComponentNode.name = (newComponentNode.get_script() as Script).get_global_name()

	if debugMode: printLog(str(newComponentNode))

	# Add the Component to the selected Entity
	EditorInterface.edit_node(parentNode)
	parentNode.add_child(newComponentNode, true) # force_readable_name
	newComponentNode.owner = EditorInterface.get_edited_scene_root() # NOTE: For some reason, using `parentNode` directly does not work; the Component is added to the SCENE but not to the Scene Dock TREE.

	# Select the new Component in the Editor, so the user can quickly modify it in the Inspector.
	editorSelection.clear()
	editorSelection.add_node(newComponentNode)
	EditorInterface.edit_node(newComponentNode)

	# Expose the sub-nodes of the new Component to make it easier to modify any, if needed.
	if %EditableChildrenCheckBox.button_pressed:
		newComponentNode.get_parent().set_editable_instance(newComponentNode, true)

	# Log
	printLog(str("Added Component: ", newComponentNode, " → ", newComponentNode.get_parent()))

#endregion


#region Component Editing

## Calls [method createNewComponentOnDisk] on the first selected folder in the Godot Editor's FileSystem Dock, if any.
## Returns: The selected folder path.
func createNewComponentInSelectedFolder() -> String:
	var selectedPaths: PackedStringArray = EditorInterface.get_selected_paths()	
	
	if selectedPaths.is_empty():
		printLog("No folder selected.")
		return ""
	
	var selectedFolderPath: String
	
	for path in selectedPaths:
		if DirAccess.dir_exists_absolute(path):
			selectedFolderPath = path
			break

	if selectedFolderPath.is_empty():
		printLog("No folder selected.")
		return ""
	
	showNewComponentDialog(selectedFolderPath)
	
	return selectedFolderPath


func validateNewComponentPath(folderPath: String, componentName: String) -> bool:
	# TODO: Trim whitespace
	if folderPath.is_empty() or componentName.is_empty(): return false
	elif not DirAccess.dir_exists_absolute(folderPath):
		printError("folderPath does not exist: " + folderPath)
		return false
	elif not folderPath.begins_with("res://"):
		printError("folderPath must begin with \"res://\": " + folderPath)
		return false
	elif componentName.contains(".") or componentName.contains(" ") or not componentName.is_valid_filename():
		printError("Invalid componentName — Must be alphanumeric with no space or special characters: " + componentName)
		return false
	else: return true


## Returns the path of the new component's ".tscn" scene file if successful.
func createNewComponentOnDisk(destinationFolderPath: String, newComponentName: String = "NewComponent") -> String:
	# TODO: More reliable file/path naming and operations with no room for errors. File system work is nasty business!
	# TBD:  Enforce valid & unique name

	printLog(str("createNewComponentOnDisk() destinationFolderPath: ", destinationFolderPath, ", newComponentName: ", newComponentName))
	
	# Validate

	if not validateNewComponentPath(destinationFolderPath, newComponentName): return "" # Messages will be logged by validation function.
	
	if not FileAccess.file_exists(componentBaseScene):
		printError("Missing base Component Scene: " + componentBaseScene)
		return ""

	# Get the directory manager & set the paths
	var newScenePath:		String = destinationFolderPath + newComponentName + ".tscn"
	var newScriptPath:		String = destinationFolderPath + newComponentName + ".gd"

	# ALERT: MAKE SURE NOT TO OVERWRITE ANY EXISTING FILES! Or there may be doom!
	if not ensureFileDoesNotExist(newScenePath) \
	or not ensureFileDoesNotExist(newScriptPath):
		# Error messages logged by other functions
		return ""

	# Create a new vanilla Component and save a copy of it at the new destination.
	# NOTE: Using the EditorInterface to save a new instance instead of copying the scene file prevents duplicate UID conflicts.
	EditorInterface.open_scene_from_path(componentBaseScene)
	EditorInterface.save_scene_as(newScenePath)

	# Verify that the new scene file exists.
	if not FileAccess.file_exists(newScenePath):
		printError(str("Could not save a copy of componentBaseScene: ", componentBaseScene, " at: ", newScenePath))
		return ""
	
	# Copy the script template
	if not copyFile(componentScriptTemplate, newScriptPath):
		# Error messages logged by other functions
		return ""

	# TODO: TBD: The Editor/UI operations should be in the calling function

	# Open it in the Editor
	EditorInterface.select_file(newScenePath)
	EditorInterface.open_scene_from_path(newScenePath)

	# Rename the root Node to the chosen component name
	var rootNode: Node = EditorInterface.get_edited_scene_root()
	rootNode.name = newComponentName

	# Attach the new script file
	# TODO: Find a way to hide the "parse editor" before fixing the template script
	
	var newScript:  Script = load(newScriptPath)
	var sourceCode: String = newScript.source_code
	
	sourceCode = sourceCode.replacen("# meta-default: true\n\n", "") # Replace the script template text
	sourceCode = sourceCode.replacen("class_name _CLASS_", "class_name " + newComponentName) # Use the chosen component name as the class name
	
	newScript.source_code = sourceCode
	ResourceSaver.save(newScript, newScriptPath) # TBD: CHECK: A better way to save a modified script?
	newScript.reload() # TBD: CHECK: `reload()` before or after save?

	rootNode.set_script(newScript)
	EditorInterface.set_script(newScript)

	# Save the new scene with the new script
	EditorInterface.save_scene()

	# Register the newly-created files with Godot
	fileSystem.update_file(newScriptPath)
	fileSystem.update_file(newScenePath)
	fileSystem.scan() # TBD: Is this necessary?
	# GODOT: Calling `EditorFileSystem.reimport_files()` raises error: "BUG: File queued for import, but can't be imported, importer for type '' not found."

	# Edit the new script
	EditorInterface.edit_script(newScript)

	return newScenePath


func editSelectedComponent() -> void:
	if not selectedComponentRow or selectedComponentPath.is_empty(): return
	if debugMode: printLog(str("editSelectedComponent() ", selectedComponentPath))

	var scenePath:  String
	@warning_ignore("unused_variable")
	var scriptPath: String

	# Convert the paths, just in case
	if selectedComponentPath.to_lower().ends_with(".tscn"):
		scenePath  = selectedComponentPath
		scriptPath = selectedComponentPath.replace(".tscn", ".gd")
	elif selectedComponentPath.to_lower().ends_with(".gd"):
		scenePath  = selectedComponentPath.replace(".gd", ".tscn")
		scriptPath = selectedComponentPath

	# Just open the scene in the editor as that would be more intuitive and also allow editing of the script.
	EditorInterface.open_scene_from_path(scenePath)

	# TBD: EditorInterface.edit_script(load(scriptPath)) # NOTE: Causes lag # TBD: CHECK: Is this the best way to tell the Script Editor to open a script?

#endregion


#region File System Functions

func getSubfolders(path: String) -> Array[EditorFileSystemDirectory]:
	# TODO: Move this to a general tools script, for the good of all :)

	if debugMode: printLog("getSubfolders() " + path)
	if not fileSystem: printLog("fileSystem not initialized"); return []

	var parentFolder: EditorFileSystemDirectory = fileSystem.get_filesystem_path(path)
	if not parentFolder: printLog("Cannot access parentFolder: " + path); return []

	# Get each subfolder in the parent folder

	var subfolders: Array[EditorFileSystemDirectory]

	for subfolderIndex in parentFolder.get_subdir_count():
		var subfolder: EditorFileSystemDirectory = parentFolder.get_subdir(subfolderIndex)
		subfolders.append(subfolder)

	return subfolders


func ensureFileDoesNotExist(absolutePath: String) -> bool:
	if FileAccess.file_exists(absolutePath):
		printError("File already exists: " + absolutePath)
		return false
	else:
		return true


func copyFile(sourceAbsolutePath: String, destinationAbsolutePath: String) -> bool:
	# ATTENTION: Make sure the path starts with "res://"
	# because we never want to muck with the user's file system outside the Godot project!

	#if debugMode:
	printLog("copyFile() Attempting to copy: " + sourceAbsolutePath + " → " + destinationAbsolutePath)

	# Validate

	if not sourceAbsolutePath.to_lower().begins_with("res://"):
		printError("Source path must begin with `res://`")

	if not destinationAbsolutePath.to_lower().begins_with("res://"):
		printError("Destination path must begin with `res://`")

	# Copy
	DirAccess.copy_absolute(sourceAbsolutePath, destinationAbsolutePath)

	# Verify

	if FileAccess.file_exists(destinationAbsolutePath):
		printLog("Copied: " + sourceAbsolutePath + " → " + destinationAbsolutePath)
		return true
	else:
		printError("Could not create file: " + destinationAbsolutePath)
		return false

#endregion
