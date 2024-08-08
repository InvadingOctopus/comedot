## The Comedock

@tool
class_name ComponentsDock
extends Panel


#region Parameters
var shouldShowDebugInfo: bool = false
#endregion


#region State
#endregion


#region Signals
#endregion


#region Dependencies
var editorInterface: EditorInterface
var fileSystem: EditorFileSystem

@onready var componentsTree: Tree = %ComponentsTree
#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if shouldShowDebugInfo: 
	print("Comedock _ready()")
	fileSystem = editorInterface.get_resource_filesystem()
	RenderingServer.canvas_item_set_clip(get_canvas_item(), true) # TBD: Why? Copied from Godot Plugin Demo sample code.
	updateComponentsTree()


func buildComponentsDirectory() -> void:
	if shouldShowDebugInfo: print("Comedock buildComponentsDirectory()")
	
	# Get all first-level subfolders in the `/Components/` folder
	var componentCategories: Array[EditorFileSystemDirectory] = getSubfolders("Components")
	
	# Create a UI item for each category
	
	var root: TreeItem = componentsTree.create_item()
	var componentsCount: int
	
	componentsTree.hide_root = true
	
	for category in componentCategories:
		var categoryItem: TreeItem = componentsTree.create_item()
		categoryItem.set_text(0, category.get_name())
		
		# Get the components in each category
		# TODO: Subsubfolders? :')
		
		for fileIndex in category.get_file_count():
			var componentName: String = category.get_file_script_class_name(fileIndex)
			
			# Is it a component?
			if componentName.to_lower().ends_with("component"):
				var filePath: String = category.get_file_path(fileIndex)
				# if shouldShowDebugInfo: print(componentName + " " + filePath)
				var componentItem: TreeItem = componentsTree.create_item(categoryItem)
				componentItem.set_text(0, componentName)
				componentItem.set_metadata(0, filePath)
				componentsCount += 1 
	
	#if shouldShowDebugInfo:
	print(str(componentsCount, " Components found & added to Comedock"))


func updateComponentsTree() -> void:
	buildComponentsDirectory()


func onComponentsTree_itemActivated() -> void:
	var componentName: String = componentsTree.get_selected().get_text(0)
	var componentPath: String = componentsTree.get_selected().get_metadata(0)
	
	if shouldShowDebugInfo:
		print(str("Comedock onComponentsTree_itemActivated() ", componentName, " ", componentPath))
		
	if componentPath.to_lower().ends_with(".gd"):
		componentPath = componentPath.replace(".gd", ".tscn")
	
	addComponentToSelectedNode(componentPath)


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
	
	editorInterface.edit_node(parentNode)
	
	var newComponentNode: Node = load(componentPath).instantiate()
	newComponentNode.name = (newComponentNode.get_script() as Script).get_global_name()
	
	if shouldShowDebugInfo: print(newComponentNode)
	
	editorInterface.edit_node(parentNode)
	parentNode.add_child(newComponentNode)
	newComponentNode.owner = editorInterface.get_edited_scene_root() # NOTE: For some reason, using `parentNode` directly does not work; the component is added to the SCENE but not to the scene TREE dock.
	
	editorSelection.clear()
	editorSelection.add_node(newComponentNode)


func onRefreshButton_pressed() -> void:
	componentsTree.clear()
	buildComponentsDirectory()


#region File System Functions

func getSubfolders(path: String) -> Array[EditorFileSystemDirectory]:
	# TODO: Move this to a general tools script, for the good of all :)
	
	var parentFolder: EditorFileSystemDirectory = fileSystem.get_filesystem_path(path)
	
	# Get each subfolder in the parent folder
	
	var subfolders: Array[EditorFileSystemDirectory]
	
	for subfolderIndex in parentFolder.get_subdir_count():
		var subfolder: EditorFileSystemDirectory = parentFolder.get_subdir(subfolderIndex)
		subfolders.append(subfolder)
	
	return subfolders

#endregion
