## The core of the composition framework. Represents a game character or object made up of standalone and reusable behaviors provided by [Component] child nodes.
## Provides methods for managing components and other common tasks.
## NOTE: This script may be attached to ANY DESCENDANT of [Node2D].
## TIP: If the entity is a [CharacterBody2D] then a [CharacterBodyComponent] must be added as the last child, so other motion-manipulating components may queue their updates through it.

@icon("res://Assets/Icons/Entity.svg")

class_name Entity
extends Node2D # An "entity" would always have a visual presence, so it cannot be just a [Node].


#region Parameters

## If `false`, suppresses log messages from this entity and its child [Component]s.
## NOTE: Does NOT affect warnings and errors!
@export var isLoggingEnabled: bool = true

## Enables more detailed debugging information for this entity, such as verbose log messages. Subclasses may add their own information or may not respect this flag.
## NOTE: Even though [method printDebug] also checks this flag, this flag should be checked before calls to `printDebug()` which functions such as `str()`, because that might reduce performance.
@export var shouldShowDebugInfo: bool = false

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

#endregion


#region State

## A dictionary of {StringName:Component} where the key is the `class_name` of each Component, which may be discovered via [method Script.get_global_name].
## Updated by the [signal Node.child_entered_tree] signal.
## Used by components to quickly find other sibling components, without a dynamic search at runtime.
var components: Dictionary[StringName, Component]

## A dictionary of functions that should be called only once per frame, for example [member CharacterBody2D.move_and_slide] on a [CharacterBody2D].
var functionsAlreadyCalledOnceThisFrame: Dictionary[StringName, Callable]

#endregion


#region Life Cycle

func _ready() -> void:
	printDebug("_ready()")


# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	# NOTE: This should not be `_ready()` because `_ready()` is called AFTER child nodes are loaded from the packed scene,
	# so signals like `child_entered_tree` will be missed for the initial components.
	printDebug("_enter_tree()")
	self.add_to_group(Global.Groups.entities, true) # persistent
	printLog("􀈅 [b]_enter_tree() → parent: " + str(self.get_parent()) + "[/b]", self.logFullName)
	connectSignals()


## WARNING: When overriding in a subclass, do NOT call [method Entity.connectSignals] manually from [method _enter_tree] or [method _ready],
## and call `super.connectSignals()` to ensure that all signals are connected and ONLY ONCE.
func connectSignals() -> void:
	printDebug("connectSignals()")
	# TBD: Unneeded for now
	# self.child_entered_tree.connect(childEnteredTree)
	# self.child_exiting_tree.connect(childExitingTree)


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


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			if isLoggingEnabled: printLog("􀆄 PreDelete")

#endregion


#region Internal Component Management Functions

@warning_ignore("unused_parameter")
func childEnteredTree(node: Node) -> void:
	# NOTE: A child node will `_enter_tree()` even when this Entity is added to the SCENE,
	# so this method does not necessarily mean that a Component was added to the ENTITY.
	# So do not call `registerComponent()` here!
	# A Component itself should call `parentEntity.registerComponent()` when it receives its `NOTIFICATION_PARENTED` Notification.
	pass


## Adds a [Component] to the [member components] [Dictionary] for quicker access afterwards.
## May be called by a [Component] when it receives the [const Node.NOTIFICATION_PARENTED] Notification.
## Returns `true` if successfully registered.
func registerComponent(newComponent: Component) -> bool:
	var componentType: StringName = newComponent.get_script().get_global_name() # CHECK: Is there a better way to get the actual "class_name"?

	if componentType.is_empty():
		printWarning(str("Component has no class_name, cannot register in dictionary: ", newComponent.logFullName))
		return false

	# Do we already have a component of the same type?
	var existingComponent: Component = self.components.get(componentType)

	if existingComponent:
		printLog(str("Replacing: ", existingComponent.logFullName, " ← ", newComponent.logFullName))
		existingComponent.removeFromEntity(true) # shouldFree

	self.components[componentType] = newComponent
	newComponent.parentEntity = self # Is this useful? It will be done anyway by the component.

	if shouldShowDebugInfo: printDebug(str(componentType, " = ", newComponent.logName))

	# TBD: Register the superclass of the component as well, such as [HealthComponent] for [ShieldedHealthComponent],
	# to make it easier for other dependent components to access the child class via [member Component.coComponents] if they only need the parent class' features.

	# DESIGN: DISABLED: This is too complicated to implement elegantly/reliably,
	# because many components share common base classes such as `Component`, `CharacterBodyManipulatingComponentBase`, `CooldownComponent` etc.
	# WORKAROUND: Just call findFirstComponentSubclass() at the site of use.

	# var shouldRegisterSuperClass: bool = false

	# if shouldRegisterSuperClass:
	# 	var superClass: Script = newComponent.get_script().get_base_script()

	# 	if superClass:
	# 		var superType: StringName = superClass.get_global_name()

	# 		# Don't keep registering the core/base types!
	# 		if not superType.is_empty() and superType.to_upper() != "COMPONENT" and not superType.to_upper().ends_with("BASE"):
	# 			if superType not in self.components:
	# 				self.components[superType] = newComponent
	# 				printDebug(str("Superclass: ", superType, " = ", newComponent.logName))
	# 			else:
	# 				printDebug(str("Superclass: ", superType, " already registered for a different component: ", self.components.get(superType).logFullName))

	return true


@warning_ignore("unused_parameter")
func childExitingTree(node: Node) -> void:
	# NOTE: A child node will `_exit_tree()` even when this Entity is removed from the SCENE,
	# so this method does not necessarily mean that a Component was removed from the ENTITY.
	# So do not call `unregisterComponent()` here!
	# A Component itself should call `parentEntity.unregisterComponent()` when it receives its `NOTIFICATION_UNPARENTED` Notification.
	pass


## Adds a [Component] from the [member components] [Dictionary].
## May be called by a [Component] when it receives the [const Node.NOTIFICATION_UNPARENTED] Notification.
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


## Checks the [member Entity.components] [Dictionary] for a key matching the [param type] [Script]'s [method Script.get_global_name] `class_name`.
func hasComponent(type: Script) -> bool:
	return self.components.keys().has(type.get_global_name())


## Checks the [member Entity.components] [Dictionary] after converting the [param type] to a [StringName] key.
## NOTE: Does NOT find subclasses which inherit the specified type; use [method Entity.findFirstComponentSubclass] instead.
func getComponent(type: Script) -> Component:
	# NOTE: The function is named "get" instead of "find" because "find" may imply a slower search of all children.
	var typeName: StringName = type.get_global_name()
	var foundComponent: Component = self.components.get(typeName)
	return foundComponent


## Adds an existing [Component] [Node] instance to this entity.
## The component must not already be a child of another parent node.
## This is a convenience method for adding components created and configured in code during runtime.
func addComponent(component: Component) -> void:
	self.add_child(component, true) # force_readable_name
	component.owner = self # For persistence in Save/Load


## Calls [method addComponent] on each of the component instances passed in the array.
## Returns: The size of the [param componentsToAdd] array.
func addComponents(componentsToAdd: Array[Component]) -> int:
	for componentToAdd in componentsToAdd:
		self.addComponent(componentToAdd)
	return componentsToAdd.size()


## Creates a copy of the specified component TYPE's scene and adds and returns an INSTANCE of it as a child node of this entity.
## Shortcut for [method load] + [method PackedScene.instantiate].
## ALERT: Some situations, such as adding a new component while the entity is being initialized, may cause the error: "Parent node is busy setting up children, `add_child()` failed. Consider using `add_child.call_deferred(child)` instead."
func addNewComponent(type: Script) -> Component:
	## NOTE: This is needed because adding components with `.new()` adds the script ONLY, NOT the scene!
	## and instantiating a scene is a lot of boilerplate code each time. :(

	## NOTE: This cannot be a static function on [Component],
	## because then GDScript will always run it on the [Component] script, not the subclasses we need. :(

	# First, construct the scene name from the script's name.
	var componentScenePath: String = Tools.getScenePathFromClass(type)
	if shouldShowDebugInfo: printDebug(str("addNewComponent(", type, "): ", componentScenePath))

	# Load and instantiate the component scene.
	var newComponent := Tools.loadSceneAndAddInstance(componentScenePath, self)
	if shouldShowDebugInfo: printDebug(str(newComponent))

	return newComponent


## Calls [method addNewComponent] on each of the component TYPES passed in the array.
## Returns: An array of all the component INSTANCES that were successfully created and added.
func addNewComponents(componentTypesToAdd: Array[Script]) -> Array[Component]:
	var newComponents: Array[Component]
	for componentTypeToAdd in componentTypesToAdd:
		var newComponent := self.addNewComponent(componentTypeToAdd)
		if is_instance_valid(newComponent):
			newComponents.append(newComponent)
	return newComponents


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
func findFirstComponentSubclass(type: Script) -> Component:
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

## Returns the first child node which matches the specified [param type].
## If [param includeEntity] is `true` (default) then this ENTITY ITSELF may be returned if it is node of a matching type. Useful for [Sprite2D] or [Area2D] etc. nodes with the `Entity.gd` script.
## NOTE: Also returns any SUBCLASSES which inherit from the specified [param type].
## WARNING: TIP: [method Entity.findFirstComponentSubclass] is faster when searching for components including subclasses, as it only searches the [member Entity.components] dictionary.
func findFirstChildOfType(type: Variant, includeEntity: bool = true) -> Node:
	var result: Node = Tools.findFirstChildOfType(self, type, includeEntity)
	if shouldShowDebugInfo: printDebug(str("findFirstChildOfType(", type, "): ", result))
	return result


## Returns the first child of [param parentNode] which matches ANY of the specified [param types] (searched in the array order).
## If [param includeEntity] is `true` (default) then this ENTITY ITSELF is returned if none of the requested types are found.
## This may be useful for choosing certain child nodes to operate on, like an [AnimatedSprite2D] or [Sprite2D] to animate, otherwise operate on the entity itself.
## PERFORMANCE: Should be the same as multiple calls to [method ]indFirstChildOfType] in order of the desired types.
func findFirstChildOfAnyTypes(types: Array[Variant], includeEntity: bool = true) -> Node:
	# TBD: Better name
	var result: Node = Tools.findFirstChildOfAnyTypes(self, types, includeEntity)
	if shouldShowDebugInfo: printDebug(str("findFirstChildOfAnyTypes(", types, "): ", result))
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
	# TBD: Should this be a part of the base `Entity` class?
	var labelComponent: LabelComponent = self.getComponent(LabelComponent)
	if not labelComponent: return
	labelComponent.display(text, animation)


#region Logging

var logName: String: # Static assignment would set the property before the `name` is set.
	# Entities just need to show their name as they're almost always the same type/eclass.
	get: return "􀕽 " + self.name

## A more detailed name including the node name, instance, and the script's `class_name`.
var logFullName: String:
	get: return str("􀕽 ", self, ":", self.get_script().get_global_name())


func printLog(message: String = "", object: Variant = self.logName) -> void:
	if not isLoggingEnabled: return
	Debug.printLog(message, object, "lightGreen", "green")


## Affected by [member shouldShowDebugInfo], but NOT affected by [member isLoggingEnabled].
## TIP: Even though this method checks for [member shouldShowDebugInfo], check for that flag before calling [method printDebug] to avoid unnecessary function calls like `str()` and improve performance.
func printDebug(message: String = "") -> void:
	# DESIGN: isLoggingEnabled is not respected for this method because we often need to disable common "bookkeeping" logs such as creation/destruction but we need debugging info when developing new features.
	if not shouldShowDebugInfo: return
	Debug.printDebug(message, logName, "green")


# NOTE: Ignores [member isLoggingEnabled]
func printWarning(message: String = "") -> void:
	Debug.printWarning(message, logFullName, "green")


# NOTE: Ignores [member isLoggingEnabled]
func printError(message: String = "") -> void:
	Debug.printError(message, logFullName, "green")


## Logs an entry showing a variable's previous and new values, IF there is a change and [member shouldShowDebugInfo].
func printChange(variableName: String, previousValue: Variant, newValue: Variant, logAsDebug: bool = true) -> void:
	if shouldShowDebugInfo and previousValue != newValue:
		var string: String = str(variableName, ": ", previousValue, " → ", newValue)
		if not logAsDebug: printLog("[color=gray]" + string)
		else: printDebug(string)

#endregion


#region Debugging

# DEBUG: This region is for debugging [CharacterBody2D] nodes, such as monitoring changes in the [member CharacterBody2D.velocity].
# To use, temporarily uncomment this block and comment out the normal properties and methods which will be replaced.
# DONTCOMMIT the uncommented version!

## FOR DEBUGGING ONLY
## @experimental
# var body: CharacterBody2D = self

## FOR DEBUGGING ONLY
## @experimental
# var previousVelocity: Vector2 = Vector2.ZERO

## FOR DEBUGGING ONLY
## @experimental
# func _set(property: StringName, value: Variant) -> bool:
# 	# Log changes
# 	if shouldShowDebugInfo and property == "velocity":
# 		previousVelocity = velocity
# 		if previousVelocity != value:
# 			var caller: Dictionary = get_stack()[2]
# 			var callerFunction: String = caller.source.get_file() + ":" + caller.function + "()"
# 			print(str(logName, " ", callerFunction, ": velocity ", previousVelocity, " → ", value))

# 	# Access normally
# 	return false 

#endregion