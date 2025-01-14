## AutoLoad
## Manages transitions between different scenes via a "navigation stack".
## For visuals and sounds that must be present in every scene, see [GlobalOverlay].

# class_name SceneManager
extends Node


#region Constants
const logName: String = "SceneManager" # Because we can't have class_name :')
#endregion


#region State

## A first-in=last-out stack of scenes that can be navigated within via [method pushSceneToStack] and [method popSceneFromStack].
## NOTE: New items are "pushed" and "popped" from the END/BACK of the array (i.e. the last elements), NOT the front, to improve performance by not rearranging the rest of the array.
static var sceneStack: Array[PackedScene]

#endregion


#region Scene Management Methods

## Transitions to the specified scene with an optional animation.
## NOTE: Does NOT use the [member sceneStack]; see [method pushSceneToStack] and [method popSceneFromStack].
func transitionToScene(nextScene: PackedScene, pauseSceneTree: bool = true, animate: bool = true) -> void: # NOTE: Cannot be `static` because of `self.get_tree()`
	var sceneTree: SceneTree = self.get_tree()
	var sceneBeforeTransition: Node = sceneTree.current_scene

	Debug.printLog(str("transitionToScene(): ", sceneBeforeTransition, " → ", nextScene),  logName)

	# Pause
	sceneTree.paused = pauseSceneTree
	if animate: await GlobalOverlay.fadeIn() # Fade the overlay in, fade the game out.

	# Transition
	sceneTree.change_scene_to_packed(nextScene)

	# Unpause
	if animate: await GlobalOverlay.fadeOut() # Fade the overlay out, fade the game in.
	sceneTree.paused = false


## Transitions to a new scene, adds it to the [member sceneStack] and returns resulting stack size.
func pushSceneToStack(nextScene: PackedScene, pauseSceneTree: bool = true) -> int:  # NOTE: Cannot be `static` because of `self.get_tree()`
	# Push the current scene on the stack first
	var sceneBeforeTransition: Node = self.get_tree().current_scene
	sceneStack.push_back(sceneBeforeTransition) # NOTE: PERFORMANCE: Don't use push_front() because of slower performance.

	# Transition to the specified next scene
	self.transitionToScene(nextScene, pauseSceneTree)
	var sceneAfterTransition: Node = self.get_tree().current_scene

	if sceneAfterTransition == nextScene:	
		Debug.printLog(str("sceneStack.size: ", sceneStack.size()),  logName)
	else:
		Debug.printWarning(str("SceneTree.current_scene: ", sceneAfterTransition, " != nextScene: ", nextScene), logName)

	return sceneStack.size()


## Transitions to the PREVIOUS scene from the [member sceneStack], if any, and returns it.
## NOTE: Returns the previous scene from the stack EVEN IF the transition was NOT successful.
func popSceneFromStack(pauseSceneTree: bool = true) -> PackedScene:  # NOTE: Cannot be `static` because of `self.get_tree()`
	if sceneStack.size() <= 1: # Can't pop if there is only 1 or fewer scenes on the stack.
		Debug.printWarning(str("popSceneFromStack(): No previous scene on sceneStack! size: ", sceneStack.size()), logName)
		return null

	# Get the last scene from the stack
	var previousSceneFromStack: PackedScene = sceneStack.pop_back() # NOTE: PERFORMANCE: Don't use pop_front() because of slower performance.
	self.transitionToScene(previousSceneFromStack, pauseSceneTree)

	# Verify the transition
	
	var sceneAfterTransition: Node = self.get_tree().current_scene

	if sceneAfterTransition == previousSceneFromStack:
		Debug.printLog(str("sceneStack.size: ", sceneStack.size()),  logName)
	else:
		Debug.printWarning(str("SceneTree.current_scene: ", sceneAfterTransition, " != previousSceneFromStack: ", previousSceneFromStack), logName)
	
	return previousSceneFromStack


## Sets [member SceneTree.paused] and returns the resulting paused status.
func setPause(paused: bool) -> bool: # NOTE: Cannot be `static` because of `self.get_tree()`
	var sceneTree: SceneTree = self.get_tree()
	sceneTree.paused = paused

	GlobalOverlay.showPauseVisuals(sceneTree.paused)
	return sceneTree.paused


## Toggles [member SceneTree.paused] and returns the resulting paused status.
func togglePause() -> bool: # NOTE: Cannot be `static` because of `self.get_tree()`
	# TBD: Should this be more efficient instead of so many function calls?
	return setPause(not self.get_tree().paused)

#endregion
