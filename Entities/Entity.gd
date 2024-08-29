## The core of the composition framework. Represents a game character or object made up of standalone and reusable behaviors provided by [Component] child nodes.
## Provides methods for managing components and other common tasks.
## NOTE: This script may be attached to ANY DESCENDANT of [Node2D].
## TIP: If the entity is a [CharacterBody2D] then a [CharacterBodyComponent] must be added as the last child, so other motion-manipulating components may queue their updates through it.

@icon("res://Assets/Icons/Entity.svg")

class_name Entity
extends Node2D # An "entity" would always have a visual presence, so it cannot be just a [Node].


#region Parameters

## The primary [Area2D] represented by this [Entity] for child [Component]s to manipulate.
## If left `null`, the [Entity] [Node] itself may be used if it's a [Area2D],
## otherwise it will be the first matching child node.
## Call [method getArea] to automatically set this value.
@export var area: Area2D

## The primary [CharacterBody2D] represented by this [Entity] for child [Component]s to manipulate.
## If left `null`, the [Entity] [Node] itself may be used if it's a [CharacterBody2D],
## otherwise it will be the first matching child node.
## Call [method getBody] to automatically set this value.
@export var body: CharacterBody2D

## If `false`, suppresses log messages from this entity and its child [Component]s.
@export var isLoggingEnabled:		bool = true

## Enables more detailed debugging information for this entity, such as verbose log messages. Subclasses may add their own information or may not respect this flag.
@export var shouldShowDebugInfo:	bool = false

#endregion


#region State

## A dictionary of {StringName:Component} where the key is the `class_name` of each component.
## Updated by the [signal Node.child_entered_tree] signal.
## Used by components to quickly find other sibling components, without a dynamic search at runtime.
var components: Dictionary = {}

## A dictionary of functions that should be called only once per frame, for example move_and_slide() on a CharacterBody2D
var functionsAlreadyCalledOnceThisFrame: Dictionary = {}

#endregion


#region Life Cycle

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	# NOTE: This should not be `_ready()` because `_ready()` is called AFTER child nodes are loaded from the packed scene,
	# so signals like `child_entered_tree` will be missed for the initial components.
	self.add_to_group(Global.Groups.entities, true) # persistent
	printLog("􀈅 [b]_enter_tree() → parent: " + str(self.get_parent()) + "[/b]", self.logFullName)
	connectSignals()


func connectSignals() -> void:
	self.child_entered_tree.connect(childEnteredTree)
	self.child_exiting_tree.connect(childExitingTree)


func _process(_delta: float) -> void:
	# Clear the list of functions that are supposed to be called once per frame,
	# so they can be called again in the next frame.
	# TBD: Assess performance impact
	functionsAlreadyCalledOnceThisFrame.clear()


## May be called by a child component such as a [HealthComponent] when this parent [Entity] is supposed to be removed from the scene.
## May be overridden in subclasses to check additional conditions and logic.
func requestDeletion() -> bool: # TBD: Should this be renamed to `requestDeletionOfEntity()`?
	self.queue_free()
	return true


func _exit_tree() -> void:
	printLog("􀈃 _exit_tree() parent: " + str(self.get_parent()), self.logFullName)

#endregion


#region Internal Component Management Functions

func childEnteredTree(node: Node) -> void:
	# Herd components into the [components] dictionary.
	if is_instance_of(node, Component):
		registerComponent(node as Component)


func registerComponent(newComponent: Component) -> void:
	var componentType: StringName = newComponent.get_script().get_global_name() # CHECK: Is there a better way to get the actual "class_name"?

	# Do we already have a component of the same type?
	var existingComponent: Component = self.components.get(componentType)
	if existingComponent:
		printLog(str("Replacing: ", existingComponent, " → ", newComponent))

	newComponent.parentEntity = self # TBD: Is this useful?
	self.components[componentType] = newComponent

	# DEBUG: printDebug(str(componentType, " ← ", newComponent))


func childExitingTree(node: Node) -> void:
	# Remove components from the [components] dictionary.
	if is_instance_of(node, Component):
		unregisterComponent(node as Component)


func unregisterComponent(componentToRemove: Component) -> void:
	var componentType: StringName = componentToRemove.get_script().get_global_name() # CHECK: Is there a better way to get the actual "class_name"?

	# Does the dictionary have a component of the same type?
	var existingComponent: Component = self.components.get(componentType)

	# NOTE: Make sure the component in the dictionary which matches the same type, is the same one that is being removed.

	if existingComponent == componentToRemove:
		printLog(str("Unregistering ", existingComponent))
		self.components.erase(componentType)
	else:
		printError(str("Component of type ", componentType, " already in dictionary: ", existingComponent, " but not the same as componentToRemove: ", componentToRemove))
		# NOTE: TBD: This is a weird situation which should not happen, so it must be considered an error.

#endregion


#region External Component Management Interface

## Checks the [member Entity.components] dictionary after converting the [param type] to a [StringName] key.
## NOTE: Does NOT find subclasses which inherit the specified type; use [method Entity.findFirstComponentSublcass] instead.
func getComponent(type: Script) -> Component:
	# NOTE: The function is named "get" instead of "find" because "find" may imply a slower search of all children.
	var typeName: StringName = type.get_global_name()
	var foundComponent: Component = self.components.get(typeName)
	return foundComponent


## Adds an existing [Component] [Node] to this entity.
## The component must not already be a child of another parent node. 
## This is a convenience method for adding components created and configured in code during runtime.
func addComponent(component: Component) -> void:
	self.add_child(component)
	component.owner = self


## Creates a copy of the specified component's scene and adds it as a child node of this entity.
## Shortcut for [load] and [method PackedScene.instantiate].
func addNewComponent(type: Script) -> Component:
	## NOTICE: This is needed because adding components with `.new()` adds the script ONLY, NOT the scene!
	## and instantiating a scene is a lot of boilerplate code each time. :(

	## NOTICE: This cannot be a static function on [Component],
	## because then GDScript will always run it on the [Component] script, not the subclasses we need. :(

	# First, construct the scene name from the script's name.

	var scenePath: String = Tools.getScenePathFromClass(type)

	# Load and instantiate the component scene.

	return Tools.loadSceneAndAddInstance(scenePath, self)


## Searches all child nodes and returns an array of all nodes which inherit from [Component].
## NOTE: Does NOT include children of children.
## WARNING: This may be slow. Use the [member Entity.components] dictionary instead.
func findChildrenComponents() -> Array[Component]:
	# This duplicates most code from `getChildrenOfType` because of ensuring strong typing.
	var childrenNodes: Array[Node] = self.get_children()
	var childrenComponents: Array[Component] = []

	var filter := func isComponent(node: Node) -> bool:
		return is_instance_of(node, Component)

	childrenComponents.assign(childrenNodes.filter(filter))
	printLog("getComponents(): " + str(childrenComponents))
	return childrenComponents


## Checks all components in the [member Entity.components] dictionary and returns the first matching component which inherits from the specified [param type].
## NOTE: Slower than [method Entity.getComponent]
func findFirstComponentSublcass(type: Script) -> Component:
	for component: Component in self.components.values():
		if is_instance_of(component, type):
			return component
	return null


## Removes a component that has been registered in the [member components] Dictionary and frees (deletes) the component unless specified.
## NOTE: Removes only a SINGLE component of the specified type. To remove multiple children of the same type, use [method removeChildrenOfType].
func removeComponent(componentType: Script, shouldFree: bool = true) -> bool:
	var componentToRemove := self.getComponent(componentType)
	
	if not componentToRemove:
		return false
	else:
		componentToRemove.removeFromEntity(shouldFree)
		return true


## Calls [method removeComponent] on each of the component types passed in the array.
## Returns: The number of components that were found and removed.
func removeComponents(componentTypes: Array[Script]) -> int:
	var removalCount: int = 0
	for componentType in componentTypes:
		if self.removeComponent(componentType): removalCount += 1
	return removalCount

#endregion


#region General Child Node Management

## NOTE: Also returns any subclasses which inherit from the specified [param type].
## WARNING: [method Entity.findFirstComponentSublcass] is faster when searching for components including subclasses, as it only searches the [member Entity.components] dictionary.
func findFirstChildOfType(type: Variant) -> Node:
	var result: Node = Tools.findFirstChildOfType(self, type)
	# DEBUG: printDebug("findFirstChildOfType(" + str(type) + "): " + str(result))
	return result


## NOTE: Does NOT search children of children.
func findChildrenOfType(type: Variant) -> Array: # TODO: Return type?
	var children: Array[Node] = self.get_children()
	var childrenFiltered: Array[Node] = []

	var filter := func matchesType(node: Node) -> bool:
		return is_instance_of(node, type)

	childrenFiltered.assign(children.filter(filter))
	printDebug("getChildrenOfType(" + str(type) + "): " + str(childrenFiltered))
	return childrenFiltered


## Instantiates a new copy of the specified scene path and adds it as a child node of this entity.
## Shortcut for [load] and [method PackedScene.instantiate].
func addSceneCopy(path: String) -> Node:
	return Tools.loadSceneAndAddInstance(path, self)


## Removes all child nodes of the specified type and frees (deletes) them if [param free] is `true`.
## Returns: The number of children that were removed (0 means none were found).
func removeChildrenOfType(type: Variant, shouldFree: bool = true) -> int: # TODO: Return type?
	var childrenToRemove: Array[Node] = self.findChildrenOfType(type)
	var childrenRemoved := 0
	for child: Node in childrenToRemove:
		self.remove_child(child)
		if shouldFree: child.queue_free()
		childrenRemoved += 1

	printLog("removeChildrenOfType(" + str(type) + "): " + str(childrenRemoved))
	return childrenRemoved


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


#endregion


## Used to call any function only once during a single frame, such as [method CharacterBody2D.move_and_slide] on the [Entity]'s [CharacterBody2D].
## This ensures that multiple components which interact with the same node do not perform excessive updates, such as a [PlatformerControlComponent[ and a [JumpControlComponent].
## The `Callable` is added to the [member functionsAlreadyCalledOnceThisFrame] dictionary, which is cleared during each [method _physics_process] of this entity.
func callOnceThisFrame(function: Callable, arguments: Array = []) -> void:
	# Has the function already been called this frame?
	if not functionsAlreadyCalledOnceThisFrame.has(str(function)):
		# DEBUG: printDebug("callOnceThisFrame(" + str(function) + ")")
		# First add it to the list so it doesn't get called again; this should avoid any recursion.
		self.functionsAlreadyCalledOnceThisFrame[str(function)] = function
		function.callv(arguments)


## Uses a [LabelComponent], if available, to display the specified text.
func displayLabel(text: String, animation: StringName = Animations.blink) -> void:
	var labelComponent: LabelComponent = self.getComponent(LabelComponent)
	if not labelComponent: return
	labelComponent.display(text, animation)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			if isLoggingEnabled: printLog("􀆄 PreDelete")


#region Logging

var logName: String: # Static assignment would set the property before the `name` is set.
	# Entities just need to show their name as they're almost always the same type/eclass.
	get: return "􀕽 " + self.name

## A more detailed name including the node name, instance, and the script's `class_name`.
var logFullName: String:
	get: return str("􀕽 ", self, ":", self.get_script().get_global_name())


func printLog(message: String = "", objectName: String = self.logName) -> void:
	if not isLoggingEnabled: return
	Debug.printLog(message, "lightGreen", objectName, "green")


## Affected by [member shouldShowDebugInfo], but not affected by [member isLoggingEnabled].
func printDebug(message: String = "") -> void:
	# DESIGN: isLoggingEnabled is not respected for this method because we often need to disable common "bookkeeping" logs such as creation/destruction but we need debugging info when developing new features.
	if not shouldShowDebugInfo: return
	Debug.printDebug(message, logName, "green")


func printWarning(message: String = "") -> void:
	if not isLoggingEnabled: return
	Debug.printWarning(message, logFullName, "green")


func printError(message: String = "") -> void:
	if not isLoggingEnabled: return
	Debug.printError(message, logFullName, "green")


## Logs an entry showing a variable's previous and new values, IF there is a change and [member shouldShowDebugInfo].
func printChange(variableName: String, previousValue: Variant, newValue: Variant, logAsDebug: bool = true) -> void:
	if shouldShowDebugInfo and previousValue != newValue:
		var string: String = str(variableName, ": ", previousValue, " → ", newValue)
		if not logAsDebug: printLog("[color=gray]" + string)
		else: printDebug(string)

#endregion
