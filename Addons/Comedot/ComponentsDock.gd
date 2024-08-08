## The Comedock

@tool
class_name ComponentsDock
extends Panel


#region Parameters
var shouldShowDebugInfo: bool = false
#endregion


#region State
const folderIcon    := preload("res://Assets/Icons/Godot/FolderMediumThumb.svg")
const componentIcon := preload("res://Assets/Icons/Component.svg")
const categoryColor := Color(0.235, 0.741, 0.878) # From Godot Editor's color for folders chosen to be "Blue"
const componentBackgroundColor := Color(0.051, 0.133, 0.184) # From Godot Editor's background color for folders chosen to be "Blue"
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
	print("Comedock _ready()")
	RenderingServer.canvas_item_set_clip(get_canvas_item(), true) # TBD: Why? Copied from Godot Plugin Demo sample code.
	call_deferred(&"buildComponentsDirectory") # `call_deferred` to reduce lag?


func buildComponentsDirectory() -> void:
	if shouldShowDebugInfo: print("Comedock buildComponentsDirectory()")

	# Get all first-level subfolders in the `/Components/` folder
	var componentCategories: Array[EditorFileSystemDirectory] = getSubfolders("Components")

	# Create a UI item for each category folder

	var root: TreeItem = componentsTree.create_item()
	var componentsCount: int

	componentsTree.hide_root = true

	for category in componentCategories:
		var categoryItem: TreeItem = componentsTree.create_item()
		categoryItem.set_text(0, category.get_name())

		# Customize the Tree row
		categoryItem.set_icon(0, folderIcon)
		categoryItem.set_icon_modulate(0, categoryColor)
		categoryItem.set_custom_color(0, categoryColor)
		categoryItem.set_custom_bg_color(0, componentBackgroundColor)
		categoryItem.set_expand_right(0, true)
		categoryItem.set_selectable(0, false)

		# Get the components in each category
		# TODO: Subsubfolders? :')

		for fileIndex in category.get_file_count():
			var componentName: String = category.get_file_script_class_name(fileIndex)

			# Is it a component?
			if componentName.to_lower().ends_with("component"):
				var filePath: String = category.get_file_path(fileIndex)
				var componentScript: Script
				# if shouldShowDebugInfo: print(componentName + " " + filePath)

				# Add the component to the Tree
				var componentItem: TreeItem = componentsTree.create_item(categoryItem)
				componentItem.set_text(0, componentName)
				componentItem.set_metadata(0, filePath)
				componentsCount += 1

				# Customize the Tree row
				# NOTE: PERFORMANE: Adding icons here seems to slow things down
				#componentItem.set_icon(1, componentIcon)
				#componentItem.set_icon_modulate(1, Color.CORNFLOWER_BLUE) # I am Jack's buggy code :')
				#componentItem.set_icon_max_width(1, 32)
				componentItem.set_expand_right(0, true)

	#if shouldShowDebugInfo:
	print(str(componentsCount, " Components found & added to Comedock"))


func updateComponentsTree() -> void:
	buildComponentsDirectory()


func addComponentToSelectedNode(componentPath: String) -> void:
	if componentPath.is_empty(): return
	if shouldShowDebugInfo: print("Comedock addComponentToSelectedNode() " + componentPath)

	var editorSelection: EditorSelection = editorInterface.get_selection()
	var selectedNodes: Array[Node] = editorSelection.get_selected_nodes()

	# TBD: Support adding components to more than 1 selected Node?

	if selectedNodes.is_empty() or selectedNodes.size() != 1:
		#if shouldShowDebugInfo:
		print("Cannot add Components to more than 1 selected Node")
		return

	var parentNode: Node = selectedNodes.front()

	if not parentNode is Entity:
		# If the selection is a Component, try to select its parent Entity
		if parentNode is Component:
			parentNode = parentNode.get_parent()
		else:
			#if shouldShowDebugInfo:
			print("Cannot add Component to a non-Entity Node")
			return

	# Create a new instance of the component
	var newComponentNode: Node = load(componentPath).instantiate()
	newComponentNode.name = (newComponentNode.get_script() as Script).get_global_name()

	if shouldShowDebugInfo: print(newComponentNode)

	# Add the component to the selected Entity
	editorInterface.edit_node(parentNode)
	parentNode.add_child(newComponentNode)
	newComponentNode.owner = editorInterface.get_edited_scene_root() # NOTE: For some reason, using `parentNode` directly does not work; the component is added to the SCENE but not to the scene TREE dock.

	# Select the new component in the Editor, so the user can quickly modify it in the Inspector.
	editorSelection.clear()
	editorSelection.add_node(newComponentNode)
	editorInterface.edit_node(newComponentNode)


#region UI Events

func onComponentsTree_itemActivated() -> void:
	var componentName: String = componentsTree.get_selected().get_text(0)
	var componentPath: String = componentsTree.get_selected().get_metadata(0)

	if shouldShowDebugInfo:
		print(str("Comedock onComponentsTree_itemActivated() ", componentName, " ", componentPath))

	if componentPath.to_lower().ends_with(".gd"):
		componentPath = componentPath.replace(".gd", ".tscn")

	addComponentToSelectedNode(componentPath)


func onRefreshButton_pressed() -> void:
	componentsTree.clear()
	call_deferred(&"buildComponentsDirectory") # `call_deferred` to reduce lag?


func onEditButton_pressed() -> void:
	var selectedComponent: TreeItem = componentsTree.get_selected()
	if not selectedComponent: return

	var componentPath: String = selectedComponent.get_metadata(0)
	if componentPath.is_empty(): return

	# Open the scene in the editor as that would be more intuitive and also allow editing of the script.

	var scenePath:  String
	var scriptPath: String

	if componentPath.to_lower().ends_with(".tscn"):
		scenePath  = componentPath
		scriptPath = componentPath.replace(".tscn", ".gd")
	elif componentPath.to_lower().ends_with(".gd"):
		scenePath  = componentPath.replace(".gd", ".tscn")
		scriptPath = componentPath

	editorInterface.open_scene_from_path(scenePath)
	#editorInterface.edit_script(load(scriptPath)) # NOTE: Causes lag # TBD: CHECK: Is this the best way to tell the Script Editor to open a script?

#endregion


#region File System Functions

func getSubfolders(path: String) -> Array[EditorFileSystemDirectory]:
	# TODO: Move this to a general tools script, for the good of all :)

	if shouldShowDebugInfo: print("getSubfolders() " + path)
	if not fileSystem: print("fileSystem not initialized"); return []

	var parentFolder: EditorFileSystemDirectory = fileSystem.get_filesystem_path(path)
	if not parentFolder: print("Invalid parentFolder: " + path); return []

	# Get each subfolder in the parent folder

	var subfolders: Array[EditorFileSystemDirectory]

	for subfolderIndex in parentFolder.get_subdir_count():
		var subfolder: EditorFileSystemDirectory = parentFolder.get_subdir(subfolderIndex)
		subfolders.append(subfolder)

	return subfolders

#endregion
