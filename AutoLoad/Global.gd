# AutoLoad
## Global data and code provided by the framework for all games, such as constants, flags and helper functions etc.

extends Node


#region Project-Specific Flags & Settings

## ATTENTION: This flag is set by the [Start] script which must be attached to the root node of the main scene of your game.
var hasStartScript: bool = false

var saveFilePath: StringName = &"user://ComedotSaveGame.scn"

#endregion


#region Constants

# NOTE: Classes containing a list of constants are named plural, so as to be more intuitive and not be confused with a more general type, i.e. "Actions" vs "Action".

#region Settings
## Paths to project settings
## NOTE: This is not named "Settings" to avoid any confusion that they may be the actual properties; they're just paths to the values.
class SettingsPaths:
	const gravity		:= &"physics/2d/default_gravity"
#endregion


#region Groups
class Groups:
	const components	:= &"components"
	const entities		:= &"entities"

	const players		:= &"players"
	const enemies		:= &"enemies"
	const hazards		:= &"hazards"
	const collectibles	:= &"collectibles"
	const interactions	:= &"interactions"
	const zones			:= &"zones"
#endregion Input Actions


#region Animations
class Animations: ## Animation labels
	const overlayFadeIn		:= &"overlayFadeIn"
	const overlayFadeOut	:= &"overlayFadeOut"

	const blink				:= &"blink"
#endregion


class CompassDirections: ## A list of unit vectors representing 8 compass directions.
	const none		:= Vector2i.ZERO
	const northWest	:= Vector2i(-1, -1)
	const north		:= Vector2i.UP
	const northEast	:= Vector2i(1, -1)
	const east		:= Vector2i.RIGHT
	const southEast	:= Vector2i(1, 1)
	const south		:= Vector2i.DOWN
	const southWest	:= Vector2i(-1, 1)
	const west		:= Vector2i.LEFT

#endregion


#region Scene Management

func instantiateSceneFromPath(resourcePath: String) -> Node:
	var scene: PackedScene = load(resourcePath) as PackedScene
	return scene.instantiate()


## Returns the path for a scene from a class type.
## Convenient for getting the scene for a component.
## e.g. [JumpControlComponent] returns "res://Components/Control/JumpControlComponent.tscn"
## WARNING: This assumes that the scene's name is the same as the `class_name`
func getScenePathFromClass(type: Script) -> String:
	# var className   := type.get_global_name()
	var scriptPath	:= type.resource_path
	var scenePath 	:= scriptPath.replace(".gd", ".tscn")
	return scenePath


## Instantiates a new copy of the specified scene path and adds it as a child node of this entity.
## Shortcut for [load] and [method PackedScene.instantiate].
## Returns: The new instance of the scene.
func loadSceneAndAddInstance(path: String, parent: Node, position: Vector2 = Vector2.ZERO) -> Node:
	var scene: PackedScene = load(path)
	return addSceneInstance(scene, parent, position)


## Shortcut for [method PackedScene.instantiate] and [method Node.add_child].
## Returns: The new copy of the scene.
func addSceneInstance(scene: PackedScene, parent: Node, position: Vector2 = Vector2.ZERO) -> Node:
	var newChild := scene.instantiate()
	newChild.position = position
	parent.add_child(newChild)
	newChild.owner = parent # INFO: Necessary for persistence to a [PackedScene] for save/load.
	return newChild


func transitionToScene(nextScene: PackedScene):
	get_tree().paused = true
	await GlobalOverlay.fadeIn() # Fade the overlay in, fade the game out.

	get_tree().change_scene_to_packed(nextScene)

	await GlobalOverlay.fadeOut() # Fade the overlay out, fade the game in.
	get_tree().paused = false


## Sets [member SceneTree.paused] and returns the resulting paused status.
func setPause(paused: bool) -> bool:
	get_tree().paused = paused

	if get_tree().paused: GlobalOverlay.fadeIn()
	else: GlobalOverlay.fadeOut()

	var isTreePaused := get_tree().paused # Cache? :')
	GlobalOverlay.setPauseSettingsVisibility(isTreePaused)
	return isTreePaused


## Toggles [member SceneTree.paused] and returns the resulting paused status.
func togglePause() -> bool:
	# TBD: Should this be more efficient instead of so many function calls?
	return setPause(not get_tree().paused)

#endregion



#region Node Management

func findFirstChildOfType(parentNode: Node, type) -> Node:
	var children: Array[Node] = parentNode.get_children()
	for child in children:
		if is_instance_of(child, type): return child # break
	#else
	return null


## Searches up the tree until a matching parent or grandparent is found.
func findFirstParentOfType(childNode: Node, type) -> Node:
	var parent: Node = childNode.get_parent() # parentOrGrandparent

	# If parent is null or not the matching type, get the grandparent (parent's parent) and keep searching up the tree.
	while not (is_instance_of(parent, type)) and not (parent == null):
		parent = parent.get_parent()

	return parent


## Replaces a child node with another node at the same index (order).
## NOTE: The child and its sub-children are NOT deleted. To delete a child, use [method Node.queue_free].
## Returns: `true` if [param childToReplace] was found and replaced.
func replaceChild(parentNode: Node, childToReplace: Node, newChild: Node) -> bool:
	if childToReplace.get_parent() != parentNode: return false

	# Is the new child already in another parent?
	# TODO: Option to remove new child from existing parent
	var newChildCurrentParent: Node = newChild.get_parent()
	if newChildCurrentParent != null and newChildCurrentParent != parentNode:
		Debug.printWarning("replaceChild(): newChild already in another parent: " + str(newChild, " in ", newChildCurrentParent))
		return false

	var previousChildIndex = childToReplace.get_index() # The original index
	parentNode.remove_child(childToReplace)

	parentNode.add_child(newChild)
	parentNode.move_child(newChild, previousChildIndex)
	newChild.owner = parentNode # INFO: Necessary for persistence to a [PackedScene] for save/load.

	return true


## Removes each child from the [parameter parent] then calls [method Node.queue_free] on the child.
## Returns: The number of removed children.
func removeAllChildren(parent: Node) -> int:
	var removalCount: int = 0

	for child in parent.get_children():
		parent.remove_child(child) # TBD: Is this needed? Does NOT delete nodes, unlike queue_free()
		child.queue_free()
		removalCount += 1

	return removalCount

#endregion


#region Save & Load

## A very rudimentary implementation of saving the entire game state.
## @experimental
func saveGame():
	# TODO: Implement properly :(
	# BUG: Does not save all state of all nodes
	Debug.printLog("Saving state → " + Global.saveFilePath)
	var packedSceneToSave := PackedScene.new()
	packedSceneToSave.pack(get_tree().get_current_scene())
	ResourceSaver.save(packedSceneToSave, Global.saveFilePath)


## A very rudimentary implementation of loading the entire game state.
## @experimental
func loadGame():
	# TODO: Implement properly :(
	# BUG: Does not restore all state of all nodes
	Debug.printLog("Loading state ← " + Global.saveFilePath)
	var packedSceneLoaded := ResourceLoader.load(Global.saveFilePath)
	get_tree().change_scene_to_packed(packedSceneLoaded)

#endregion


#region Area & Shape Functions

## Returns a rectangle representing the bounds of an [Area2D]'s first [CollisionShape2D] child.
## NOTE: The rectangle is in the coordinates of the [CollisionShape2D].
## Works best with areas with a single rectangle shape.
## Returns: On failure: a rectangle with size -1
func getShapeBounds(area: Area2D) -> Rect2:
	# HACK: Sigh @ Godot for making this so hard...

	# Find a CollisionShape2D child.

	var shapeNode: CollisionShape2D = findFirstChildOfType(area, CollisionShape2D)

	if not shapeNode:
		Debug.printWarning("getShapeBounds(): Cannot find a CollisionShape2D child", str(area))
		return Rect2(area.position.x, area.position.y, -1, -1) # Return a invalid negative-sized rectangle matching the area's origin.

	var shape: Shape2D = shapeNode.shape
	var shapeBounds: Rect2 = shape.get_rect()

	return shapeBounds


## Returns a rectangle representing the bounds of an [Area2D]'s first [CollisionShape2D] child.
## NOTE: The rectangle is in the coordinates of the [Area2D].
## Works best with areas with a single rectangle shape.
## Returns: On failure: a rectangle with size -1
func getShapeBoundsInArea(area: Area2D) -> Rect2:
	# TODO: More accuracy within all sorts of shapes
	# TODO: Find a more elegant and efficient way :')
	# HACK: Sigh @ Godot for making this so hard...

	# INFO: Overview: An [Area2D] has a [CollisionShape2D] child [Node], which in turn has a [Shape2D] [Resource].
	# In the parent Area2D, the CollisionShape2D's "anchor point" is at the top-left corner, so its `position` may be 0,0.
	# But inside the CollisionShape2D, the Shape2D's anchor point is at the center of the shape, so its `position` may be 16,16 for a rectangle of 32x32.
	# SO, we have to figure out the Shape2D's rectangle in the coordinate space of the Area2D.
	# THEN convert it to global coordinates.

	# First, find a CollisionShape2D child.

	var shapeNode: CollisionShape2D = findFirstChildOfType(area, CollisionShape2D)

	if not shapeNode:
		Debug.printWarning("getShapeBoundsInArea(): Cannot find a CollisionShape2D child", str(area))
		return Rect2(area.position.x, area.position.y, -1, -1) # Return a invalid negative-sized rectangle matching the area's origin.

	# Make local copies of the frequently used stuff.

	var shapeNodePositionInArea := shapeNode.position
	var shape: Shape2D = shapeNode.shape

	# The bounding rectangle of the shape. NOTE: In the coordinates of the CollisionShape2D node!
	var shapeBoundingRect: Rect2 = shape.get_rect() # TBD: Should we use `extents`? It seems to be half of the size, but it seems to be a hidden property [as of 4.3 Dev 3].

	# Because a [CollisionShape2D]'s anchor is at its center,
	# we have to get it's top-left corner,
	# by subtracting HALF the size of the actual SHAPE:

	var shapeNodeTopLeftCorner := Vector2( \
		shapeNode.position.x - shapeBoundingRect.size.x / 2, \
		shapeNode.position.y - shapeBoundingRect.size.y / 2)

	var shapeBoundsInArea := Rect2( \
		shapeNodeTopLeftCorner.x, shapeNodeTopLeftCorner.y, \
		shapeBoundingRect.size.x, shapeBoundingRect.size.y)

	#var shapeGlobalOrigin: Vector2 = shapeNode.global_position - shapeNode.shape.extents # NOTE: CHECK: `extents` seems to be the distance of the edge from the origin (center in this case), but it seems to be a hidden property?

	return shapeBoundsInArea


func getShapeGlobalBounds(area: Area2D) -> Rect2:
	var shapeGlobalBounds := getShapeBoundsInArea(area)
	shapeGlobalBounds.position = area.to_global(shapeGlobalBounds.position)
	return shapeGlobalBounds


func getRandomPositionInArea(area: Area2D) -> Vector2:

	var areaBounds := getShapeBoundsInArea(area)

	# Generate a random position within the area.

	#var isWithinArea := false
	#while not isWithinArea:

	#randomize() # TBD: Do we need this?

	var x := randf_range(areaBounds.position.x, areaBounds.end.x)
	var y := randf_range(areaBounds.position.y, areaBounds.end.y)
	var randomPosition := Vector2(x, y)

	#if shouldVerifyWithinArea: isWithinArea = ... # TODO: Cannot check if a point is within an area :( [as of 4.3 Dev 3]
	#else: isWithinArea = true

	#Debug.printDebug(str(self) + " shapeNode position: " + str(shapeNodePositionInArea) +", shapeBoundingRect: " + str(shapeBoundingRect) + ", random position: " + str(randomSpawnPosition))
	#Debug.printDebug(str(shapeNodePositionInArea))
	#Debug.printDebug(str(shapeBoundingRect))
	#Debug.printDebug(str(shapeNodeTopLeftCorner))

	return randomPosition

#endregion


#region Physics Functions

## Sets the X and/or Y components of [member CharacterBody2D.velocity] to 0 if the [method CharacterBody2D.get_last_motion()] is 0 in the respective axes.
## This prevents the "glue effect" where if the player keeps inputting a direction while the character is pushed against a wall,
## it will take a noticeable delay to move in the other direction while the velocity gradually changes from the wall's direction to away from the wall.
func resetBodyVelocityIfZeroMotion(body: CharacterBody2D) -> Vector2:
	var lastMotion = body.get_last_motion()
	if abs(lastMotion.x) < 0.1: body.velocity.x = 0
	if abs(lastMotion.y) < 0.1: body.velocity.y = 0
	return lastMotion

#endregion


#region Visual Functions

func getRectCorner(rectangle: Rect2, compassDirection: Vector2i) -> Vector2:
	var position	:= rectangle.position
	var center		:= rectangle.get_center()
	var end			:= rectangle.end

	match compassDirection:
		CompassDirections.northWest:	return Vector2(position.x, position.y)
		CompassDirections.north:		return Vector2(center.x, position.y)
		CompassDirections.northEast:	return Vector2(end.x, position.y)
		CompassDirections.east:			return Vector2(end.x, center.y)
		CompassDirections.southEast:	return Vector2(end.x, end.y)
		CompassDirections.south:		return Vector2(center.x, end.y)
		CompassDirections.southWest:	return Vector2(position.x, end.y)
		CompassDirections.west:			return Vector2(position.x, center.y)

		_: return Vector2.ZERO


func addRandomDistance(position: Vector2, \
minimumDistance: Vector2, maximumDistance: Vector2, \
xScale: float = 1.0, yScale: float = 1.0) -> Vector2:

	var randomizedPosition := position
	randomizedPosition.x += randf_range(minimumDistance.x, maximumDistance.x) * xScale
	randomizedPosition.y += randf_range(minimumDistance.y, maximumDistance.y) * yScale
	return randomizedPosition

#endregion


#region Miscellaneous Functions

func isValidArrayIndex(array: Array, index: int) -> bool:
	if array.size() > 0 and index >= 0 and index < array.size():
		return true
	else:
		return false

#endregion
