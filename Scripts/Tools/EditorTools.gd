## Helper functions for interacting with the Godot Editor from addons/plugins & `@tool` scripts.
## In future Godot versions these functions & types may be incorporated into the builtin API as native code or via custom extensions.

@tool
class_name EditorTools
extends Node


## Clears the Editor selection and selects a single specific node.
## TIP: Call with [method Callable.call_deferred] to avoid Godot errors when trying to select nodes that are being created etc.
static func selectNode(node: Node) -> void:
	if not is_instance_valid(node): return
	var selection: EditorSelection = EditorInterface.get_selection()
	selection.clear()
	selection.add_node(node)
	EditorInterface.edit_node(node)


## Adds a node to a parent in the Godot Scene Editor with undo/redo support.
## [param additionalDoMethods] are performed after adding the node,
## [param additionalUndoMethods] are performed before removing the node.
## TIP: Bind arguments to callables with [method Callable.bind]
## TIP: To select the new node in the Editor so the user can quickly modify it, call [method EditorTools.selectNode] with [method Callable.call_deferred] to avoid errors while the new node is being added.
static func addNodeWithUndo(
	newNode:				Node,
	parent:					Node,
	actionName:				String,
	showEditableChildren:	bool = false,
	additionalDoMethods:	Array[Callable] = [],
	additionalUndoMethods:	Array[Callable] = [],
) -> bool:

	# Validation & Setup
	# TODO: Validate `parent`
	# TBD: Check is_queued_for_deletion()?
	
	if not Engine.is_editor_hint()	\
	or not parent or not newNode	\
	or newNode.get_parent() != null: # Does the kid already have a parent?
		return false

	var sceneRoot: Node = EditorInterface.get_edited_scene_root()

	if not sceneRoot \
	or (parent != sceneRoot and not sceneRoot.is_ancestor_of(parent)): # Make sure the parent is in the currently edited scene
		return false
	
	var undoManager: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	undoManager.create_action(actionName)

	# Do then Undo in reverse order

	# Add the new node to the specified parent node
	undoManager.add_do_method(parent,	&"add_child",	newNode, true) # force_readable_name
	undoManager.add_do_method(newNode,	&"set_owner",	sceneRoot) # The owner must be the currently edited scene root

	# Expose the sub-nodes of the new node to make it easier to modify if needed
	if showEditableChildren and newNode.get_child_count() > 0:
		# NOTE: set_editable_instance() must be called on the PARENT or ancestor of the added node
		# NOTE: Use `showEditableChildren` instead of `true` or `false` so that children are hidden when that option is disabled, in case the child nodes were already automatically shown somehow.
		undoManager.add_do_method(parent, &"set_editable_instance", newNode, showEditableChildren)

	# DESIGN: Do not save/restore the list of selected nodes:
	# The Godot Editor's own built-in Create New Node etc. actions also don't preserve the previous selection.

	registerUndoRedoMethods(undoManager, &"add_do_method",	 additionalDoMethods)
	registerUndoRedoMethods(undoManager, &"add_undo_method", additionalUndoMethods)

	if showEditableChildren and newNode.get_child_count() > 0:
		undoManager.add_undo_method(parent,	&"set_editable_instance", newNode, not showEditableChildren)

	# On undo, remove the newly-added node
	undoManager.add_undo_method(newNode, &"set_owner",	  null)
	undoManager.add_undo_method(parent,  &"remove_child", newNode)

	undoManager.add_do_reference(newNode) # Make sure the newly created node CANNOT be freed while the undo history still needs it for redo
	undoManager.commit_action() # Calls all `do` methods such as add_child() etc.
	return true


## Registers [Callable]s with [EditorUndoRedoManager]
## Arguments must be attached with [method Callable.bind]
## WARNING: Invalid/misspelled method names will be silently ignored.
static func registerUndoRedoMethods(undoManager: EditorUndoRedoManager, registrationMethod: StringName, methods: Array[Callable]) -> void:
	for methodToRegister: Callable in methods:
		if not methodToRegister.is_valid(): continue

		var methodArguments: Array[Variant] = [
			methodToRegister.get_object(),
			methodToRegister.get_method()]
		methodArguments.append_array(methodToRegister.get_bound_arguments())
		undoManager.callv(registrationMethod, methodArguments)
