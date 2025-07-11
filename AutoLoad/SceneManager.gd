## AutoLoad
## Manages transitions between different scenes via a "navigation stack".
## For visuals and sounds that must be present in every scene, see [GlobalUI].

# class_name SceneManager
extends Node


#region Constants
const logName: String = "SceneManager" # Because we can't have class_name :')
#endregion


#region State

## A first-in=last-out stack of scenes that can be navigated within via [method pushSceneToStack] and [method popSceneFromStack].
## Stores paths instead of [PackedScene] to save memory and improve performance.
## IMPORTANT: The END of the array (i.e. the last element) is the TOP of the "stack" and the PREVIOUS scene; [member SceneTree.current_scene] is not stored on the stack.
## New items are "pushed" and "popped" from the end/back of the array, NOT the front, to improve performance by not rearranging the rest of the array.
static var sceneStack: PackedStringArray # Better performance than Array[String]

var sceneTree: SceneTree:
	get:
		if not sceneTree: sceneTree = self.get_tree()
		return sceneTree

## Stores the scene from any previous call to [method transitionToScene] to prevent bugs from multiple calls during animations etc.
var ongoingTransitionScene: PackedScene # CHECK: PERFORMANCE: PackedScene is probably quicker to compare than String, right?

#endregion


#region Parameters
@export var animateDefault: bool = true ## The default value for the `animate` argument in [method transitionToScene] and other methods.
#endregion



#region Signals
signal willTransitionToScene(scene: PackedScene)
signal didTransitionToScene(scene:  PackedScene)

signal willPushScene(scenePath: String) ## TIP: May be used to modify the stack before a new scene is pushed.
signal didPushScene(scenePath:  String)

signal willPopScene ## TIP: May be used to modify the stack before a scene is popped, for example, pushing a scene if there is none, to make sure a "Back" Button always works.
signal didPopScene(scenePath: String)

signal willSetPause(pause: bool)	## TIP: May be used to modify visuals etc. before the game is paused.
signal didSetPause(isPaused: bool)	## TIP: May be used to modify UI such as [PauseButton.gd] after the game is paused.
#endregion


#region Transition & Stack Management

## Transitions to the specified scene with an optional animation.
## NOTE: Does NOT use the [member sceneStack]; see [method pushCurrentSceneAndTransition] and [method popSceneFromStack].
func transitionToScene(nextScene: PackedScene, pauseSceneTree: bool = true, animate: bool = animateDefault) -> void:
	if not is_instance_valid(nextScene):
		Debug.printError(str("transitionToScene(): Invalid scene: ", nextScene), logName)
		return

	GlobalInput.isPauseShortcutAllowed = false # Disable the Pause Overlay during transitions

	# Prevent multiple transitions to the same scene
	if ongoingTransitionScene == nextScene:
		Debug.printWarning(str("transitionToScene() called for the same scene during a transition: ", nextScene, " ", nextScene.resource_path), logName)
		return

	var sceneBeforeTransition: Node = sceneTree.current_scene
	Debug.printAutoLoadLog(str("transitionToScene(): ", sceneBeforeTransition, " → ", nextScene, " ", nextScene.resource_path))

	# Track the scene to prevent bugs from multiple calls to transition to the same scene during animations etc.
	ongoingTransitionScene = nextScene

	willTransitionToScene.emit(nextScene)

	# Pause
	sceneTree.paused = pauseSceneTree
	if animate: await GlobalUI.fadeInTintRect().finished # Fade the overlay in, fade the game out.

	# Transition
	sceneTree.change_scene_to_packed(nextScene)
	sceneTree.paused = true # Repause just in case the new scene unpaused before we fade-in

	# Unpause
	await sceneTree.create_timer(0.1).timeout # A little breath before showing the next scene
	sceneTree.paused = false # Unpause to begin the gameplay motion before the overlay fades-out for a smoother feel, instead of an abrupt movement.
	if animate: await GlobalUI.fadeOutTintRect().finished # Fade the overlay out, fade the game in.

	ongoingTransitionScene = null # Clear the transition tracker
	if Debug.shouldPrintDebugLogs: Debug.printDebug(str("SceneTree.current_scene: ", sceneTree.current_scene), logName)
	didTransitionToScene.emit(nextScene)

	GlobalInput.isPauseShortcutAllowed = true # Reenable the Pause Overlay


## Shortcut for calling [method pushCurrentSceneToStack] then [method transitionToScene].
## Call [method popSceneFromStack] from the [param nextScene] to return to the previous scene.
func pushCurrentSceneAndTransition(nextScene: PackedScene, pauseSceneTree: bool = true, animate: bool = animateDefault) -> void:
	self.pushCurrentSceneToStack()
	await self.transitionToScene(nextScene, pauseSceneTree, animate) # IMPORTANT: await for animations


## Adds a scene path to the [member sceneStack] and returns the resulting stack size.
func pushSceneToStack(scenePath: String) -> int:
	if scenePath.is_empty():
		Debug.printWarning("pushSceneToStack(): Path empty!", logName)
		return sceneStack.size()

	willPushScene.emit(scenePath)

	# Check if we're pushing the same scene more than once
	if not sceneStack.is_empty() and sceneStack[sceneStack.size() - 1] == scenePath:
		Debug.printWarning("pushSceneToStack(): Scene already on top of stack: " + scenePath, logName)

	sceneStack.append(scenePath) # NOTE: PERFORMANCE: Don't use push_front() because of slower performance.

	if Debug.shouldPrintDebugLogs:
		Debug.printDebug(str("pushSceneToStack(): ", scenePath, " → ", sceneStack.size(), ": ", sceneStack), logName)

	didPushScene.emit(scenePath)
	return sceneStack.size()


## Pushes the current scene's path to [member sceneStack] and returns the stack size.
func pushCurrentSceneToStack() -> int:
	var currentScene: Node = sceneTree.current_scene

	if not is_instance_valid(currentScene):
		Debug.printWarning("pushCurrentSceneToStack(): No valid current scene", logName)
		return sceneStack.size()

	var currentScenePath: String = currentScene.scene_file_path

	if not currentScenePath.is_empty():
		pushSceneToStack(currentScenePath)
	else:
		Debug.printWarning("pushCurrentSceneToStack(): Cannot get path for current scene", logName)

	return sceneStack.size()


## Transitions to the PREVIOUS scene from the top/end of the [member sceneStack], if any, and returns it.
## NOTE: Returns the previous scene from the stack EVEN IF the transition was NOT successful.
func popSceneFromStack(pauseSceneTree: bool = true, animate: bool = animateDefault) -> PackedScene:

	if sceneStack.is_empty(): # Can't pop if there are no scenes on the stack.
		Debug.printWarning("popSceneFromStack(): sceneStack is empty!", logName)
		return null

	# Get the previous scene from the top of the stack

	willPopScene.emit()

	# GODOT: Why is there no pop_back() for PackedArrays??
	# PERFORMANCE: Don't use pop_front() because of slower performance.
	var previousScenePathFromStack: String  = sceneStack[sceneStack.size() - 1]
	sceneStack.remove_at(sceneStack.size() - 1)

	var previousSceneFromStack: PackedScene = load(previousScenePathFromStack)

	if previousSceneFromStack:
		Debug.printAutoLoadLog(str("popSceneFromStack() → ", previousScenePathFromStack, " → stack size: ", sceneStack.size()))
	else:
		Debug.printError("popSceneFromStack(): Cannot load path: " + previousScenePathFromStack, logName)
		return null

	await self.transitionToScene(previousSceneFromStack, pauseSceneTree, animate)# IMPORTANT: await for animations

	# Verify the transition

	# Make sure there IS a scene after the transition.
	# TODO: BUG: Because if `animate` is false, `current_scene` is `null` here?
	if sceneTree.current_scene:
		var scenePathAfterTransition: String = sceneTree.current_scene.scene_file_path
		if not scenePathAfterTransition == previousScenePathFromStack:
			Debug.printWarning(str("SceneTree.current_scene.scene_file_path: ", scenePathAfterTransition, " != previousScenePathFromStack: ", previousScenePathFromStack), logName)

	didPopScene.emit(previousScenePathFromStack)
	return previousSceneFromStack

#endregion


#region Pause/Unpause

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED:
			didSetPause.emit(sceneTree.paused)


## Sets [member SceneTree.paused] and returns the resulting paused status.
func setPause(shouldPause: bool) -> bool:
	# TBD: Emit signal only if changing?
	willSetPause.emit(shouldPause)
	sceneTree.paused = shouldPause

	GlobalUI.showPauseVisuals(sceneTree.paused)
	# NOTE: Do not emit didSetPause here; let _notification() handle pause/unpause from ANY source.
	return sceneTree.paused


## Toggles [member SceneTree.paused] and returns the resulting paused status.
func togglePause() -> bool:
	# TBD: Should this be more efficient instead of so many function calls?
	return setPause(not sceneTree.paused)

#endregion


#region General Functions


## Returns the path for a scene from a class type.
## Convenient for getting the scene for a component.
## e.g. [JumpComponent] returns "res://Components/Control/JumpComponent.tscn"
## WARNING: This assumes that the scene's name is the same as the `class_name`
func getScenePathFromClass(type: Script) -> String:
	# var className: String = type.get_global_name()
	var scriptPath:	String = type.resource_path
	var scenePath:	String = scriptPath.replace(".gd", ".tscn")
	return scenePath


## Returns a new instance (Node) of a scene from the specified path.
## Shortcut for [method @GDScript.load] + [method PackedScene.instantiate]
func instantiateSceneFromPath(path: String) -> Node:
	var scene: PackedScene = load(path) as PackedScene

	if is_instance_valid(scene):
		var instance := scene.instantiate()
		if is_instance_valid(instance): return instance
		else:
			Debug.printWarning(str("SceneManager.instantiateSceneFromPath(): Cannot instantiate ", scene, " from ", path))
	else:
		Debug.printWarning("SceneManager.instantiateSceneFromPath(): Cannot load " + path)

	return null


## Loads the specified Scene path and adds a new copy of it as a child node of the specified parent.
## Shortcut for [load] and [method addSceneInstance].
## Returns: The new instance.
func loadSceneAndAddInstance(path: String, parent: Node, position: Vector2 = Vector2.ZERO) -> Node:
	var scene: PackedScene = load(path)
	return addSceneInstance(scene, parent, position)


## Instantiates a new copy of the specified Scene and adds it as a child node of the specified parent.
## Shortcut for [method PackedScene.instantiate] and [method Node.add_child].
## ALERT: Some situations may cause the error: "Parent node is busy setting up children". To solve, use `addSceneInstance.call_deferred(…)`
## Returns: The new instance.
func addSceneInstance(scene: PackedScene, parent: Node, position: Vector2 = Vector2.ZERO) -> Node:
	if scene == null:
		Debug.printWarning(str("SceneManager.addSceneInstance(): scene is null!"))
		return null

	var newChild := scene.instantiate()

	if not is_instance_valid(newChild):
		Debug.printWarning(str("SceneManager.addSceneInstance(): Cannot instantiate ", scene))
		return null

	if newChild is Node2D or newChild is Control: newChild.position = position
	Tools.addChildAndSetOwner(newChild, parent) # Ensure persistence
	return newChild

#endregion
