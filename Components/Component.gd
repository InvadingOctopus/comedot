## The core of the composition framework. A node which represents a distinct behavior or property of a game character or object.
## A parent node made up of Component child nodes is an [Entity]. The Entity is the "scaffolding" and Components do the actual work (play).
## Components may be reused in different kinds of entities, such as a [HealthComponent] used for the player's character and also the monsters.
## Components may directly modify the parent entity or interact with other components,
## such as a [DamageComponent] communicating with another Entity's [DamageReceivingComponent] which then modifies a [HealthComponent].

#@tool # Not useful because it's not inherited :(
@icon("res://Assets/Icons/Component.svg")

class_name Component
extends Node


#region Advanced Parameters

## If the parent node is not an [Entity], should all great/grandparents be checked until an [Entity] is found up the scene tree hierarchy?
## Overridden by [member allowNonEntityParent]
## WARNING: ADVANCED option! May cause bugs or decrease performance. Use only if you know what you're doing!
## @experimental
@export var shouldCheckGrandparentsForEntity: bool = false

## Let this component be added to nodes that are not an [Entity]?
## Overrides [member shouldCheckGrandparentsForEntity]
## WARNING: ADVANCED option! May cause bugs or decrease performance. Use only if you know what you're doing, or for cases like adding "payload" components to [InjectorComponent] etc.
## @experimental
@export var allowNonEntityParent: bool = false

#endregion


#region Core Properties

var parentEntity: Entity:
	set(newValue):
		if newValue != parentEntity:
			if debugMode: printDebug(str("parentEntity: ", parentEntity, " → ", newValue))
			parentEntity = newValue

## A [Dictionary] of other [Component]s in the [parentEntity]'s [member Entity.components].
## Access via the shortcut of `coComponents.ComponentClassName` or,
## TIP: Use `coComponents.get(&"ComponentClassName")` to avoid a crash if an optional component is missing, and return `null`
## NOTE: Does NOT find subclasses which inherit the specified type; use [method Entity.findFirstComponentSubclass] instead.
var coComponents: Dictionary[StringName, Component]

#endregion


#region Signals

## Emitted on [const Node.NOTIFICATION_UNPARENTED].
## May be connected to by subclasses to perform cleanup specific to each component.
## NOTE: [member parentEntity] is still assigned at this point and set to `null` after this signal is emitted.
signal willRemoveFromEntity

#endregion


#region Validation

## NOTE: Used only if `@tool` is specified at the top of this script.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if not is_instance_of(self.get_parent(), Entity):
		warnings.append("Component nodes should be added to a parent which inherits from the Entity class.")

	if not checkRequiredComponents():
		warnings.append("This component is missing a required co-component. Check the getRequiredComponents() method.")

	return warnings


## Returns: A list of other component types which this component depends on.
## Must be overridden by subclasses.
func getRequiredComponents() -> Array[Script]:
	# This is needed to be a method because properties cannot be overridden :')
	return []


func checkRequiredComponents() -> bool:
	var requiredComponentTypes: Array[Script] = self.getRequiredComponents()
	if requiredComponentTypes.is_empty(): return true # If there are no requirements, we have everything we need :)

	if not parentEntity or parentEntity.components.keys().is_empty(): return false # If there are no other components, we don't have any of our requirements :()

	var haveAllRequirements: bool = true # Start `true` then make it `false` if there is any missing requirement.

	for requirement in requiredComponentTypes:
		# DEBUG: printDebug(str(requirement))
		if not parentEntity.components.keys().has(requirement.get_global_name()): # Convert `Script` types to their `StringName` keys
			printWarning(str("Missing requirement: ", requirement.get_global_name(), " in ", parentEntity.logName))
			haveAllRequirements = false

	return haveAllRequirements

#endregion


#region Life Cycle

## Called by [method _notification] when the component receives [const NOTIFICATION_PARENTED],
## which is when the node is added as a child of any parent node. NOTE: This does not mean the node has entered the SceneTree (yet).
## If the parent node is an [Entity] then this component is registered with that Entity,
## otherwise if [member shouldCheckGrandparentsForEntity] then all grandparents will be searched until an Entity is found.
func validateParent() -> void:
	# Initialization Order: 1: This seems to be called before any other methods, via the notification, at least when creating a new instance e.g. by a GunComponent

	var newParent: Node = self.get_parent()
	if debugMode: printDebug(str("validateParent(): ", newParent))

	# If the parent node is not an Entity, print a warning if needed
	if not is_instance_of(newParent, Entity):
		var message: String = str("validateParent(): Parent node is not an Entity: ", newParent, " ／ This may prevent sibling components from finding this component.")
		if self.allowNonEntityParent:
			printLog(message + " allowNonEntityParent: true")
		else: printWarning(message)

	if not parentEntity: # Are we a new Component [or] not owned by an Entity?

		if newParent is Entity: # If our parent is an Entity, all's well and good in the world.
			self.registerEntity(newParent)

		# If our immediate parent node is not an Entity, should we search up the scene tree hierarchy for an Entity to adopt this Component?
		elif shouldCheckGrandparentsForEntity and not allowNonEntityParent:
			var grandparentEntity: Entity = self.findParentEntity(true)
			if grandparentEntity:
				self.registerEntity(grandparentEntity)

	else: # Do we already have an Entity?

		if parentEntity == newParent:
			# Warn because why are this initialization method being called again?
			printWarning(str("validateParent() called again for parentEntity that is already set: ", parentEntity))
		else: # Are we already owned by an Entity Node that is NOT the new parent?
			# CHECK: This situation should never happen, so treat it as an Error, right?
			printError(str("parentEntity already set to a different parent: ", parentEntity))


## Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	# Initialization Order: 2: After Entity._enter_tree(), before Entity.childEnteredTree()

	self.add_to_group(Global.Groups.components, true) # persistent

	# Find which Entity this Component belongs to, if not already set.
	if not self.parentEntity: registerEntity(self.findParentEntity())

	update_configuration_warnings()

	if parentEntity:
		# NOTE: DESIGN: If the entity's logging flags are true, it makes sense to adopt them by default,
		# but if the entity's logging is off and a specific component's logging is on, the component's flag should be respected.
		self.isLoggingEnabled = self.isLoggingEnabled or parentEntity.isLoggingEnabled
		self.debugMode = self.debugMode or parentEntity.debugMode
		printLog("􀈅 [b]_enter_tree() → " + parentEntity.logName + "[/b]", self.logFullName)

		self.checkRequiredComponents()
	elif not allowNonEntityParent:
		printWarning("􀈅 [b]_enter_tree() with no parentEntity![/b]")


## Search up the scene tree for a parent or grandparent node which is of type [Entity] and returns it.
## i.e. each parent node's parent is checked until an [Entity] is found.
func findParentEntity(checkGrandparents: bool = self.shouldCheckGrandparentsForEntity) -> Entity:
	var parentOrGrandparent: Node = self.get_parent()

	# If parent is null or not an Entity, check the grandparent (parent's parent) and keep searching up the tree.
	if checkGrandparents:
		while not (parentOrGrandparent is Entity) and not (parentOrGrandparent == null):
			if debugMode: printDebug(str("findParentEntity() checking parent of non-Entity node: ", parentOrGrandparent))
			parentOrGrandparent = parentOrGrandparent.get_parent()

	if parentOrGrandparent is Entity:
		if debugMode: printDebug(str("findParentEntity() result: ", parentOrGrandparent))
		return parentOrGrandparent
	elif not allowNonEntityParent:
		printWarning(str("findParentEntity() found no Entity! checkGrandparents: ", checkGrandparents))

	return null


func registerEntity(newParentEntity: Entity) -> void:
	if debugMode: printDebug(str("registerEntity(): ", newParentEntity))
	if not newParentEntity: return
	self.parentEntity = newParentEntity
	self.parentEntity.registerComponent(self) # NOTE: The COMPONENT must call this method. See Entity.childEnteredTree() notes for explanation.
	self.coComponents = parentEntity.components


## Removes this component from the parent [Entity] and frees (deletes) the component unless specified.
## Components that are only removed but not freed may be re-added to any entity,
func removeFromEntity(shouldFree: bool = true) -> void:
	if parentEntity and parentEntity == self.get_parent():
		parentEntity.remove_child(self)
	else:
		# TBD: Display a warning or would it be redundant if the component is already removed?
		pass # DEBUG: printWarning(str("Cannot removeFromEntity: ", parentEntity))
	if shouldFree: self.queue_free()


## Calls [method queue_free()] on itself if the parent entity approves. Returns `true` if removed.
## May be overridden in subclasses to check additional conditions and logic.
func requestDeletion() -> bool:
	# TBD: Ask the parent entity for approval?
	self.queue_free()
	return true


## Returns `true` if the parent [Entity] agrees to [method Entity.requestDeletion] or if there is no [member parentEntity].
func requestDeletionOfParentEntity() -> bool:
	if parentEntity:
		if debugMode: printDebug(str("requestDeletionOfParentEntity(): ", parentEntity.logName))
		if parentEntity.requestDeletion():
			return true
		else:
			if debugMode: printDebug(str("requestDeletionOfParentEntity(): requestDeletion() refused by ", parentEntity.logName))
			return false
	else:
		if debugMode: printWarning("requestDeletionOfParentEntity(): parentEntity already null!")
		return true # NOTE: DESIGN: If a code calls this function, then it wants the Entity to be gone, so if it's already gone, we should return `true` :)


## Called by [method _notification] when the component receives [const NOTIFICATION_UNPARENTED],
## which is when the parent node calls [method Node.remove_child] on the component node.
## NOTE: This does not mean the node has exited the SceneTree (yet).
func unregisterEntity() -> void:
	# Deinitialization Order: 2: After Entity._exit_tree()
	# CHECK: Is there still a parent reference available at this point?
	if debugMode: printDebug(str("unregisterEntity() ", get_parent()))
	if parentEntity:
		willRemoveFromEntity.emit()
		self.coComponents = {}
		self.parentEntity.unregisterComponent(self)
		self.parentEntity = null
		if isLoggingEnabled: printLog("[color=brown]􀆄 Unparented")


## NOTE: This method is called even when the Entity is removed from the SCENE (along with ALL its child nodes),
## so it does not necessarily mean that this Component was removed from the ENTITY.
func _exit_tree() -> void:
	# Deinitialization Order: 1: Before Entity.childExitingTree(), Entity._exit_tree()
	# AVOID: `parentEntity` must NOT be `null`ed here! nor `coComponents`!
	var entityName: String = parentEntity.logName if parentEntity else "null" # Check parentEntity since components may be freed without being children of an Entity
	printLog("[color=brown]􀈃 _exit_tree() parentEntity: " + entityName, self.logFullName)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:   validateParent()	# Received when a node is set as the child of another node,  not necessarily when the node enters the SceneTree.
		NOTIFICATION_UNPARENTED: unregisterEntity() # Received when a parent calls remove_child() on a child node, not necessarily when the node exit the SceneTree.
		NOTIFICATION_PREDELETE:  if isLoggingEnabled: printLog("[color=brown]􀆄 PreDelete") # NOTE: Cannot print [parentEntity] here because it will always be `null` (?)

#endregion


#region Family
# Join the serpent king!

## Returns a sibling [Component] from the [member coComponents] [Dictionary],
## after converting the [param type] [method Script.get_global_name] to a [StringName].
## If [param includeSubclasses] is `true` then [method Entity.findFirstComponentSubclass] is called to find the first [Component] which extends/inherits the specified type.
## ALERT: Slower performance compared to accessing the [member coComponents] [Dictionary] directly! Use this method only if a warning is needed instead of a crash, in case of a missing component.
func findCoComponent(type: Script, includeSubclasses: bool = true) -> Component:
	# TBD: Is [Script] the correct type for the argument?
	var coComponent: Component = self.coComponents.get(type.get_global_name())

	if not coComponent:

		if includeSubclasses:
			coComponent = parentEntity.findFirstComponentSubclass(type)
			printDebug(str("Searching for subclass of ", type, " in parentEntity: ", parentEntity, " — Found: ", coComponent))

		if not coComponent: # Did we still not find any match? :(
			printWarning(str("Missing co-component: ", type.get_global_name(), " in parent Entity: ", parentEntity.logName))

	return coComponent


## Asks the parent [Entity] to remove all other components of the same class as this component.
## Useful for replacing components when there should be only one component of a specific class, such as a [FactionComponent].
## Returns: The number of components removed.
func removeSiblingComponentsOfSameType() -> int:
	var removalCount := 0

	for sibling: Component in parentEntity.get_children(false): # Don't include sub-children
		# Is it us?
		if sibling == self: continue

		if is_instance_of(sibling, self.get_script().get_global_name()):
			sibling.requestDeletion()
			removalCount += 1

	return removalCount

#endregion


#region Static Methods

## Attempts to cast any Node as a Component, since the `Component.gd` script may be attached to any Node.
## If the [param node] is not an component but the node's parent/grandparent is an Entity, the Entity is searched to find the matching [param componentType] if [param findInParentEntity].
## @experimental
static func castOrFindComponent(node: Node, componentType: GDScript, findInParentEntity: bool = true) -> Component:

	# First, try casting the node itself.
	var component: Component = node.get_node(^".") as Component # HACK: Find better way to cast self?

	if not component:
		Debug.printDebug(str("Cannot cast ", node, " as ", componentType.get_global_name()), "Component.castOrFindComponent()")

		# Try to see if the node's grand/parent is an Entity
		if findInParentEntity:
			var nodeParent: Entity = Tools.findFirstParentOfType(node, Entity)
			if nodeParent:
				component = nodeParent.components.get(componentType.get_global_name())
				if not component:
					Debug.printDebug(str("node parent ", nodeParent, " has no ", componentType.get_global_name()), "Component.castOrFindComponent()")
					return null
			else:
				Debug.printDebug(str("node parent is not an Entity: ", nodeParent), "Component.castOrFindComponent()")
				return null

	return component

#endregion


#region Logging

@export_group("Debugging")

## Enables more detailed debugging information for this component, such as verbose log messages, visual indicators, the [member Debug.watchList] live property labels, or chart windows etc.
## NOTE: Subclasses may add their own information or may not respect this flag.
## Defaults to the entity's [member Entity.debugMode] if initially `false`.
## NOTE: Even though [method printDebug] also checks this flag, this flag should be checked before calls to `printDebug()` which functions such as `str()`, because that might reduce performance.
@export var debugMode:		bool

## If `true`, all calls to [method Component.printDebug] are forwarded to [method Debug.printTrace] which includes a list of the recent function calls and a highlighted color.
## This may help with quickly tracking a specific issue in specific components.
## NOTE: Suppresses `debugMode = false` i.e. [method printDebug] is always printed.
@export var debugModeTrace:	bool


## Defaults to the entity's [member Entity.isLoggingEnabled] if initially `false`.
## NOTE: Does NOT affect warnings and errors!
var isLoggingEnabled:		bool

var logName: String: # NOTE: This is a dynamic property because direct assignment would set the value before the `name` is set.
	get: return "􀥭 " + self.name

## A more detailed name including the node name, instance, and the script's `class_name`.
var logFullName: String:
	get: return str("􀥭 ", self, ":", self.get_script().get_global_name())

# [member Component.logName] + [member Entity.logName]
var logNameWithEntity: String:
	get: return self.logName + ((" " + parentEntity.logName) if parentEntity else "")


func printLog(message: String = "", object: Variant = self.logName) -> void:
	if not isLoggingEnabled: return
	Debug.printLog(message, object, "lightBlue", "cyan")


## Affected by [member debugMode], but NOT affected by [member isLoggingEnabled].
## NOTE: If [member debugModeTrace] is on, then [method Debug.printTrace] is ALWAYS called even if debugMode is off.
## TIP: Even though this method checks for [member debugMode], check for that flag before calling [method printDebug] to avoid unnecessary function calls like `str()` and improve performance.
func printDebug(message: String = "") -> void:
	# DESIGN: isLoggingEnabled is not respected for this method because we often need to disable common "bookkeeping" logs such as creation/destruction but we need debugging info when developing new features.
	if debugModeTrace: Debug.printTrace(message.split(", "), self.logNameWithEntity, 3) # Start further from the call stack to skip this method # TBD: Split into array by ", " for the common usage case?
	elif debugMode: Debug.printDebug(message, logName, "cyan")


## Calls [method Debug.printWarning]
## NOTE: Ignores [member isLoggingEnabled]
func printWarning(message: String = "") -> void:
	Debug.printWarning(message, logFullName, "cyan")


## Calls [method Debug.printError]
## NOTE: Ignores [member isLoggingEnabled]
func printError(message: String = "") -> void:
	Debug.printError(message, logFullName, "cyan")


## Prints an array of variables in a highlighted color, along with a short "stack trace" of recent functions and their filenames before [method Debug.printTrace] was called.
## TIP: Helpful for quick/temporary debugging of bugs currently under attention.
## Affected by [member debugMode] and only printed in debug builds.
func printTrace(values: Array[Variant] = []) -> void:
	Debug.printTrace(values, self.logNameWithEntity, 3) # Start further from the call stack to skip this method


## Logs an entry showing a variable's previous and new values, IF there is a change and [member debugMode].
func printChange(variableName: String, previousValue: Variant, newValue: Variant, logAsDebug: bool = true) -> void:
	if debugMode and previousValue != newValue:
		var string: String = str(variableName, ": ", previousValue, " → ", newValue)
		if not logAsDebug: printLog("[color=gray]" + string)
		else: printDebug(string)

#endregion
