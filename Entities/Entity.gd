## Apply this class to a `Node2D` to designate that node as an Entity which can hold `Component` nodes.
## Although this class may be attached to ANY DESCENDANT of Node2D (such as a CharacterBody2D) it is better to use specific subclasses of Entity for those cases such as `Entity`.

@icon("res://Assets/Icons/entity.svg")

class_name Entity
extends Node2D


#region Parameters

## The primary [CharacterBody2D] represented by this [Entity] for child [Component]s to manipulate.
## If left `null`, the [Entity] [Node] itself may be used if it's a [CharacterBody2D],
## otherwise it will be the first matching child node.
@export var body: CharacterBody2D

## The primary [Area2D] represented by this [Entity] for child [Component]s to manipulate.
## If left `null`, the [Entity] [Node] itself may be used if it's a [Area2D],
## otherwise it will be the first matching child node.
@export var area: Area2D

## If `false`, suppresses log messages from this entity and its child [Component]s.
@export var isLoggingEnabled := true

#endregion


#region State
## A dictionary of functions that should be called only once per frame, for example move_and_slide() on a CharacterBody2D
var functionsAlreadyCalledOnceThisFrame = {}
#endregion


#region Logging

var logName: String: # Static assignment would set the property before the `name` is set.
	# Entities just need to show their name as they're almost always the same type/eclass.
	get: return "􀕽 " + self.name

## A more detailed name including the node name, instance, and the script's `class_name`.
var logFullName: String:
	get: return "􀕽 " + str(self) + ":" + self.get_script().get_global_name()


func printLog(message: String = "", objectName: String = self.logName):
	if not isLoggingEnabled: return
	Debug.printLog(message, "lightGreen", objectName, "green")


func printDebug(message: String = ""):
	if not isLoggingEnabled: return
	Debug.printDebug(message, logName, "green")


func printWarning(message: String = ""):
	if not isLoggingEnabled: return
	Debug.printWarning(message, logFullName, "green")


func printError(message: String = ""):
	if not isLoggingEnabled: return
	Debug.printError(message, logFullName, "green")

#endregion


#region Life Cycle

# Called when the node enters the scene tree for the first time.
func _enter_tree(): # CHECK: Should it be `_ready()`?
	self.add_to_group(Global.Groups.entities, true)
	printLog("􀈅 [b]_enter_tree() parent: " + str(self.get_parent()) + "[/b]", self.logFullName)


func _process(delta: float):
	# Clear the list of functions that are supposed to be called once per frame,
	# so they can be called again in the next frame.
	functionsAlreadyCalledOnceThisFrame = {}


## May be called by a child component such as a [HealthComponent] when this parent [Entity] is supposed to be removed from the scene.
## May be overridden in subclasses to check additional conditions and logic.
func requestRemoval() -> bool:
	self.queue_free()
	return true


func _exit_tree():
	printLog("􀈃 _exit_tree() parent: " + str(self.get_parent()), self.logFullName)

#endregion


#region Child Nodes & Components

func getComponents() -> Array[Component]:
	# This duplicates most code from `getChildrenOfType` because of ensuring strong typing.
	var childrenNodes: Array[Node] = self.get_children()
	var childrenComponents: Array[Component] = []

	var filter = func isComponent(node: Node) -> bool:
		return is_instance_of(node, Component)

	childrenComponents.assign(childrenNodes.filter(filter))
	printLog("getComponents(): " + str(childrenComponents))
	return childrenComponents


func findChildrenOfType(type) -> Array: # TODO: Return type?
	var children: Array[Node] = self.get_children()
	var childrenFiltered = []

	var filter = func matchesType(node: Node) -> bool:
		return is_instance_of(node, type)

	childrenFiltered.assign(children.filter(filter))
	printDebug("getChildrenOfType(" + str(type) + "): " + str(childrenFiltered))
	return childrenFiltered


func findFirstChildOfType(type) -> Node:
	var result = Global.findFirstChildOfType(self, type)
	# DEBUG: printDebug("findFirstChildOfType(" + str(type) + "): " + str(result))
	return result


## Creates a copy of the specified component's scene and adds it as a child node of this entity.
## Shortcut for [load] and [method PackedScene.instantiate].
func addNewComponent(type: Script) -> Component:
	## NOTICE: This is needed because adding components with `.new()` adds the script ONLY, NOT the scene!
	## and instantiating a scene is a lot of boilerplate code each time. :(

	## NOTICE: This cannot be a static function on [Component],
	## because then GDScript will always run it on the [Component] script, not the subclasses we need. :(

	# First, construct the scene name from the script's name.

	var scenePath: String = Global.getScenePathFromClass(type)

	# Load and instantiate the component scene.

	return Global.addSceneCopy(scenePath, self)


## Instantiates a new copy of the specified scene path and adds it as a child node of this entity.
## Shortcut for [load] and [method PackedScene.instantiate].
func addSceneCopy(path: String) -> Node:
	return Global.addSceneCopy(path, self)


## Removes all child nodes of the specified type and frees (deletes) them if [param free] is `true`.
## Returns: The number of children that were removed (0 means none were found).
func removeChildrenOfType(type, free: bool = true) -> int: # TODO: Return type?
	var childrenToRemove = self.findChildrenOfType(type)
	var childrenRemoved := 0
	for child in childrenToRemove:
		self.remove_child(child)
		if free: child.queue_free()
		childrenRemoved += 1

	printLog("removeChildrenOfType(" + str(type) + "): " + str(childrenRemoved))
	return childrenRemoved


## Returns the [member body] property or searches for a [CharacterBody2D].
## The body may be this [Entity] [Node] itself, or the first matching child node.
func getBody() -> CharacterBody2D:
	if self.body == null:

		# First, is the entity itself a [CharacterBody2D]?
		var selfAsBody: CharacterBody2D = get_node(".") as CharacterBody2D # HACK: TODO: Find better way to cast

		if selfAsBody:
			self.body = selfAsBody
			printLog("getBody(): self")
		else:
			self.body = findFirstChildOfType(CharacterBody2D)
			printLog("getBody(): " + str(body))

	return self.body


## Returns the [member area] property or searches for an [Area2D].
## The area may be this [Entity] [Node] itself, or the first matching child node.
func getArea() -> Area2D:
	if self.area == null:

		# First, is the entity itself an [Area2D]?
		var selfAsArea: Area2D = get_node(".") as Area2D # HACK: TODO: Find better way to cast

		if selfAsArea:
			self.area = selfAsArea
			printLog("getArea(): self")
		else:
			self.area = findFirstChildOfType(Area2D)
			printLog("getArea(): " + str(area))

	return self.area

#endregion


## Used to call any function only once during a single frame, such as [method CharacterBody2D.move_and_slide] on the [Entity]'s [CharacterBody2D].
## This ensures that multiple components which interact with the same node do not perform excessive updates, such as a [PlatformerControlComponent[ and a [JumpControlComponent].
## The `Callable` is added to the [member functionsAlreadyCalledOnceThisFrame] dictionary, which is cleared during each [method _physics_process] of this entity.
func callOnceThisFrame(function: Callable, arguments: Array = []):
	# Has the function already been called this frame?
	if not functionsAlreadyCalledOnceThisFrame.has(str(function)):
		# DEBUG: printDebug("callOnceThisFrame(" + str(function) + ")")
		# First add it to the list so it doesn't get called again; this should avoid any recursion.
		self.functionsAlreadyCalledOnceThisFrame[str(function)] = function
		function.callv(arguments)


func displayLabel(text: String, animation: StringName = Global.Animations.blink):
	var labelComponent: LabelComponent = self.findFirstChildOfType(LabelComponent)
	if not labelComponent: return
	labelComponent.display(text, animation)


func _notification(what: int):
	match what:
		NOTIFICATION_PREDELETE:
			printLog("􀆄 PreDelete")
