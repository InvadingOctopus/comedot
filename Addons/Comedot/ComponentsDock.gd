## The Comedock :) Scans the `Components` folder and its subfolders, and builds a list of the components found.
## NOTE: Assumptions & Limitations: Only scene files with names ending in "Component.tscn" are added. Deeper subfolders are NOT scanned; only the 1st-level subfolders in `/Components/`.

@tool
class_name ComponentsDock
extends Panel


#region Parameters

# NOTE: Convert strings `.to_lower()` before comparing strings
const componentsRootPath		:= "res://Components"
const entitiesRootPath		:= "res://Entities"

const acceptedFileExtension	:= ".tscn"
const acceptedFileSuffix		:= "component.tscn"

const entityBaseScene		:= "res://Entities/Entity.tscn"
const entityScriptTemplate	:= "res://Templates/Entity/EntityTemplate.gd"
const componentBaseScene		:= "res://Components/Component.tscn"
const componentScriptTemplate := "res://Templates/Component/ComponentTemplate.gd"

const folderIcon				:= preload("res://Assets/Icons/Godot/FolderMediumThumb.svg")
const componentIcon			:= preload("res://Assets/Icons/Component.svg")

const categoryColor				:= Color(0.235, 0.741, 0.878) # From Godot Editor's color for folders chosen to be "Blue"
const categoryBackgroundColor	:= Color(0.051, 0.133, 0.184) # From Godot Editor's background color for folders chosen to be "Blue"
const componentBackgroundColor	:= Color(0, 0, 0) # From Godot Editor's background color for folders chosen to be "Blue"
const createNewItemButtonColor	:= Color.LAWN_GREEN

const editComponentButtonTooltipPrefix := "Open the original source scene of "

@export var shouldShowDebugInfo: bool = false

#endregion


#region State

var selectedComponentRow: TreeItem
var selectedComponentCateogry: TreeItem

var selectedComponentName: String:
	get: return selectedComponentRow.get_text(0) if selectedComponentRow else ""

var selectedComponentPath: String:
	get: return selectedComponentRow.get_metadata(0) if selectedComponentRow else ""

var selectedComponentCategoryName: String:
	get: return selectedComponentCateogry.get_text(0) if selectedComponentCateogry else ""

# var isMouseInLogo: bool # TBD: For any future animations

#endregion


#region Signals
#endregion


#region Dependencies

var plugin: EditorPlugin

var editorInterface: EditorInterface:
	set(newValue):
		if newValue != editorInterface:
			editorInterface = newValue
			fileSystem = editorInterface.get_resource_filesystem()

var fileSystem: EditorFileSystem:
	set(newValue):
		if newValue != fileSystem:
			fileSystem = newValue
			if self.is_visible_in_tree(): call_deferred(&"updateComponentsTree")

@onready var componentsTree: Tree = %ComponentsTree

#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if shouldShowDebugInfo:
	printLog("_ready()")

	# Set the controls
	%DebugReloadButton.visible = shouldShowDebugInfo
	%AddEntityButton.modulate  = createNewItemButtonColor

	# RenderingServer.canvas_item_set_clip(get_canvas_item(), true) # TBD: Why? Copied from Godot Plugin Demo sample code.
	call_deferred(&"buildComponentsDirectory") # `call_deferred` to reduce lag?
	# TODO: Display the dock if it's hidden (like behind the FileSystem)


func printLog(text) -> void:
	print(str("Comedock: ", text))


#region The Erdtree

func updateComponentsTree() -> void:
	# TODO: Check for changes?
	buildComponentsDirectory()


func buildComponentsDirectory() -> void:
	if shouldShowDebugInfo: printLog("buildComponentsDirectory()")

	# Get all first-level subfolders in the `/Components/` folder
	var componentCategories: Array[EditorFileSystemDirectory] = getSubfolders("Components")
	var root: TreeItem = componentsTree.create_item()
	var componentsCount: int

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
				# if shouldShowDebugInfo:#printLog(componentName + " " + filePath)

				# Add the component to the Tree
				createComponentTreeItem(filePath, componentName, categoryTreeItem)
				componentsCount += 1

	#if shouldShowDebugInfo:
	printLog(str(componentsCount, " Components found & added to Comedock"))

	if componentsCount <= 0:
		printLog("If the list is empty, try the \"Rescan Folders\" button or check the \"\\Components\\\" subfolder of this Godot project.")


func createCategoryTreeItem(categoryFolder: EditorFileSystemDirectory) -> TreeItem:
	var categoryItem: TreeItem = componentsTree.create_item()
	categoryItem.set_text(0, categoryFolder.get_name())
	categoryItem.set_metadata(0, categoryFolder.get_path())

	# Customize the Tree row
	categoryItem.set_icon(0, folderIcon)
	categoryItem.set_icon_modulate(0, categoryColor)
	categoryItem.set_custom_color(0, categoryColor)
	categoryItem.set_custom_bg_color(0, categoryBackgroundColor)
	categoryItem.set_expand_right(0, true)
	categoryItem.set_selectable(0, false)

	# TODO: Add a button
	categoryItem.add_button(1, componentIcon, 0, false, "Create a new Component in this category folder.")
	categoryItem.set_text(1, "+")
	categoryItem.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
	categoryItem.set_custom_color(1, createNewItemButtonColor)
	categoryItem.set_button_color(1, 0, createNewItemButtonColor)
	categoryItem.set_custom_bg_color(1, categoryBackgroundColor)
	categoryItem.set_expand_right(1, false)

	return categoryItem


func createComponentTreeItem(componentPath: String, componentName: String, categoryTreeItem: TreeItem) -> TreeItem:
	var componentItem: TreeItem = componentsTree.create_item(categoryTreeItem)
	componentItem.set_text(0, componentName)
	componentItem.set_metadata(0, componentPath)

	# Customize the Tree row
	# NOTE: PERFORMANE: Adding icons here seems to slow things down
	#componentItem.set_icon(1, componentIcon)
	#componentItem.set_icon_modulate(1, Color.CORNFLOWER_BLUE) # I am Jack's buggy code :')
	#componentItem.set_icon_max_width(1, 32)
	componentItem.set_expand_right(0, true)

	return componentItem

#endregion


#region UI Events

func onComponentsTree_itemSelected() -> void:
	var selection: TreeItem = componentsTree.get_selected()

	# Clear the previous selection. These values must be reset in any case.
	selectedComponentRow = null
	selectedComponentCateogry = null
	%EditComponentButton.disabled = true
	%EditComponentButton.tooltip_text = "Select a Component in the list to edit its original source scene."

	# Is a component row selected?
	if selection.get_text(0).to_lower().ends_with("component"): # TODO: A less crude way of checking for component rows :')
		selectedComponentRow = selection
		selectedComponentCateogry = selection.get_parent()
		%EditComponentButton.disabled = false
		%EditComponentButton.tooltip_text = editComponentButtonTooltipPrefix + selectedComponentName


## Called when a row is double-clicked
func onComponentsTree_itemActivated() -> void:
	if not selectedComponentPath.ends_with(acceptedFileExtension): return
	if shouldShowDebugInfo: printLog(str("onComponentsTree_itemActivated() ", selectedComponentName, " ", selectedComponentPath))

	# Convert script paths to scenes, just in case
	var componentScenePath := selectedComponentPath
	if componentScenePath.to_lower().ends_with(".gd"):
		componentScenePath = componentScenePath.replace(".gd", ".tscn")

	addComponentToSelectedNode(componentScenePath)


func onRefreshButton_pressed() -> void:
	componentsTree.clear()
	call_deferred(&"buildComponentsDirectory") # `call_deferred` to reduce lag?


func onEditComponentButton_pressed() -> void:
	if not selectedComponentRow or selectedComponentPath.is_empty(): return

	# Open the scene in the editor as that would be more intuitive and also allow editing of the script.

	var scenePath:  String
	var scriptPath: String

	# Convert the paths, just in case
	if selectedComponentPath.to_lower().ends_with(".tscn"):
		scenePath  = selectedComponentPath
		scriptPath = selectedComponentPath.replace(".tscn", ".gd")
	elif selectedComponentPath.to_lower().ends_with(".gd"):
		scenePath  = selectedComponentPath.replace(".gd", ".tscn")
		scriptPath = selectedComponentPath

	editorInterface.open_scene_from_path(scenePath)
	#editorInterface.edit_script(load(scriptPath)) # NOTE: Causes lag # TBD: CHECK: Is this the best way to tell the Script Editor to open a script?


func onAddEntityButton_pressed() -> void:
	if shouldShowDebugInfo: printLog("onAddEntityButton_pressed()")
	addNewEntity()


func onComponentsTree_buttonClicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if shouldShowDebugInfo: printLog("onComponentsTree_buttonClicked() " + str(item))
	var newComponentPath: String = createNewComponentOnDisk(item.get_metadata(0))

	# Add it to the Tree
	createComponentTreeItem(newComponentPath, newComponentPath, item) # TODO: Get the shortened name


func onComponentsTree_itemEdited() -> void:
	pass #if shouldShowDebugInfo: printLog("onComponentsTree_itemEdited()")


func onDebugReloadButton_pressed() -> void:
	call_deferred(&"reloadPlugin")


func reloadPlugin() -> void:
	printLog("reloadPlugin")
	editorInterface.set_plugin_enabled(Global.frameworkTitle, false)
	editorInterface.set_plugin_enabled(Global.frameworkTitle, true)

#endregion


#region Scene Editing

func addNewEntity() -> void:
	if shouldShowDebugInfo: printLog("addNewEntity()")

	var editorSelection: EditorSelection = editorInterface.get_selection()
	var selectedNodes:   Array[Node]     = editorSelection.get_selected_nodes()

	# TBD: Support adding multiple new Entities to more than 1 selected Node?

	if selectedNodes.is_empty() or selectedNodes.size() != 1:
		#if shouldShowDebugInfo:
		printLog("Cannot add Entity to more than 1 selected Node")
		return

	var parentNode: Node = selectedNodes.front()

	# Create a new Entity
	var newEntity: Entity = preload(entityBaseScene).instantiate()
	newEntity.name = "Entity"

	if shouldShowDebugInfo: printLog(newEntity)

	# Add the component to the selected Entity
	editorInterface.edit_node(parentNode)
	parentNode.add_child(newEntity, true) # force_readable_name
	newEntity.owner = editorInterface.get_edited_scene_root() # NOTE: For some reason, using `parentNode` directly does not work; the Entity is added to the SCENE but not to the scene TREE dock.

	# Select the new Entity in the Editor, so the user can quickly modify it and add Components to it.
	editorSelection.clear()
	editorSelection.add_node(newEntity)
	editorInterface.edit_node(newEntity)


func createNewComponentOnDisk(categoryFolderPath: String) -> String:
	# TODO: More reliable file/path naming and operations with no room for errors. File system work is nasty business!
	# TODO: A dialog for naming and more settings

	# Validate

	if categoryFolderPath.is_empty(): return ""

	printLog("createNewComponent() " + categoryFolderPath)

	if not DirAccess.dir_exists_absolute(categoryFolderPath):
		printLog("Invalid path")
		return ""

	if not FileAccess.file_exists(componentBaseScene):
		printLog("ERROR: Missing base Component Scene: " + componentBaseScene)
		return ""

	# Get the directory manager & set the paths
	var componentsFolder: DirAccess = DirAccess.open(componentsRootPath)
	var newComponentName: String = "NewComponent" # TODO: Unique name
	var newComponentPath: String = categoryFolderPath + newComponentName + ".tscn"
	var newScriptPath:    String = categoryFolderPath + newComponentName + ".gd"

	# ALERT: MAKE SURE NOT TO OVERWRITE ANY EXISTING FILES! Or there may be doom!
	if not ensureFileDoesNotExist(newComponentPath) \
	or not ensureFileDoesNotExist(newScriptPath):
		# Error messages logged by other functions
		return ""

	# Make a duplicate of the base Component scene at the specified destination path
	if not copyFile(componentBaseScene, newComponentPath):
		# Error messages logged by other functions
		return ""

	# Copy the script template
	if not copyFile(componentScriptTemplate, newScriptPath):
		# Error messages logged by other functions
		return ""

	# TODO: TBD: The Editor/UI operations should be in the calling function

	# Open it in the Editor
	editorInterface.select_file(newComponentPath)
	editorInterface.open_scene_from_path(newComponentPath)

	# Attach the new script file
	var rootNode:  Node = editorInterface.get_edited_scene_root()
	var newScript: Script = load(newScriptPath)
	rootNode.set_script(newScript)
	editorInterface.set_script(newScript)

	# Save the scene with the new script
	editorInterface.save_scene()

	# Edit the new script
	editorInterface.edit_script(newScript)

	return newComponentPath


func addComponentToSelectedNode(componentPath: String) -> void:
	if componentPath.is_empty(): return
	if shouldShowDebugInfo: printLog("addComponentToSelectedNode() " + componentPath)

	var editorSelection: EditorSelection = editorInterface.get_selection()
	var selectedNodes:   Array[Node]     = editorSelection.get_selected_nodes()

	# TBD: Support adding components to more than 1 selected Entity?

	if selectedNodes.is_empty() or selectedNodes.size() != 1:
		#if shouldShowDebugInfo:
		printLog("Cannot add Components to more than 1 selected Node")
		return

	var parentNode: Node = selectedNodes.front()

	if not parentNode is Entity:
		# If the selection is a Component, try to select its parent Entity
		if parentNode is Component:
			parentNode = parentNode.get_parent()
		else:
			#if shouldShowDebugInfo:
			printLog("Cannot add Component to a non-Entity Node")
			return

	# Create a new instance of the Component
	var newComponentNode: Node = load(componentPath).instantiate()
	newComponentNode.name = (newComponentNode.get_script() as Script).get_global_name()

	if shouldShowDebugInfo: printLog(newComponentNode)

	# Add the Component to the selected Entity
	editorInterface.edit_node(parentNode)
	parentNode.add_child(newComponentNode, true) # force_readable_name
	newComponentNode.owner = editorInterface.get_edited_scene_root() # NOTE: For some reason, using `parentNode` directly does not work; the Component is added to the SCENE but not to the Scene Dock TREE.

	# Select the new Component in the Editor, so the user can quickly modify it in the Inspector.
	editorSelection.clear()
	editorSelection.add_node(newComponentNode)
	editorInterface.edit_node(newComponentNode)

	#Log
	printLog(str("Added Component: ", newComponentNode, " → ", newComponentNode.get_parent()))

#endregion


#region File System Functions

func getSubfolders(path: String) -> Array[EditorFileSystemDirectory]:
	# TODO: Move this to a general tools script, for the good of all :)

	if shouldShowDebugInfo: printLog("getSubfolders() " + path)
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
		printLog("ERROR: File already exists: " + absolutePath)
		return false
	else:
		return true


func copyFile(sourceAbsolutePath: String, destinationAbsolutePath: String) -> bool:
	# ATTENTION: Make sure the path starts with "res://"
	# because we never want to muck with the user's file system outside the Godot project!

	#if shouldShowDebugInfo:
	printLog("copyFile() Attempting to copy: " + sourceAbsolutePath + " → " + destinationAbsolutePath)

	# Validate

	if not sourceAbsolutePath.to_lower().begins_with("res://"):
		printLog("ERROR: Source path must begin with `res://`")

	if not destinationAbsolutePath.to_lower().begins_with("res://"):
		printLog("ERROR: Destination path must begin with `res://`")

	# Copy
	DirAccess.copy_absolute(sourceAbsolutePath, destinationAbsolutePath)

	# Verify

	if FileAccess.file_exists(destinationAbsolutePath):
		printLog("Copied: " + sourceAbsolutePath + " → " + destinationAbsolutePath)
		return true
	else:
		printLog("ERROR: Could not create file: " + destinationAbsolutePath)
		return false

#endregion
