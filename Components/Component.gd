## The core of the composition framework: A node+script pair which represents a distinct behavior or property of a game character or object.
## A parent node containing [Component] child nodes is an [Entity]. The Entity is the "scaffolding" and Components do the actual work/play.
## Components may be reused in different kinds of entities, such as a [HealthComponent] used for the player's character and also the monsters.
## Components may directly modify the parent [Node] or interact with other components,
## such as a [DamageComponent] communicating with another Entity's [DamageReceivingComponent] which then modifies a [HealthComponent]

#@tool # UNUSED: Not useful because @tool is not inherited :(
@icon("res://Assets/Icons/Component.svg")

@abstract class_name Component
extends Node

# DESIGN: Components should not perform Entity validation, beyond checking for dependencies and basic "sanity check" logs.
# This separation keeps the core Component script lightweight and consolidates the life cycle management and "installation" methods into the Entity script,
# and also allows edge cases such as adding basic components to any non-Entity nodes,
# if the component only performs a simple task such as a [SpinComponent] that rotates the parent node every frame.


#region Advanced Parameters

## Let this [Component] be added to nodes that are not an [Entity]?
## WARNING: ADVANCED option! May cause bugs or decrease performance. Use only if you know what you're doing, or for cases like adding "payload" components to [InjectorComponent] etc.
## @experimental
@export var allowNonEntityParent: bool = false

#endregion


#region Core Properties
# TBD: @export_storage?

var entity: Entity: # TBD: @export_storage?
	set(newValue):
		if newValue != entity:
			if debugMode: printChange("entity", entity, newValue)
			entity = newValue
			# Do a basic check, but don't verify if `null`, because during `NOTIFICATION_UNPARENTED` get_parent() will still return the about-to-unparent Entity.
			if entity \
			and (not self.get_parent() == entity and not entity.is_ancestor_of(self)): # PERFORMANCE: Try the faster check first
				printWarning(str("entity set to: ", entity.logFullName, " but it is not the actual parent or ancestor of: ", self))
			# NOTE: DESIGN: Entity-dependent flags & properties should be copied/cleared in the related life cycle methods,
			# to be in proper order with other operations such as signals etc.

## A [Dictionary] of other [Component]s in the [member entity]'s [member Entity.components], including this component itself.
## TIP: Access via the shortcut of `coComponents.ComponentClassName`
## or use [method getCoComponent] or `coComponents.get(&"ComponentClassName")` to avoid a crash if an optional component is missing and just return `null`.
## NOTE: Does NOT find subclasses which inherit the specified type; use [method Entity.getCoComponent] with `findSubclasses` or [method Entity.findFirstComponentSubclass] instead.
var coComponents: Dictionary[StringName, Component]

#endregion


#region Signals
# DESIGN: There is no `willInstallInEntity` or similar signal because Components are not intended to be "active" "outside" an Entity anyway.

## Emitted by [method Entity.uninstallComponent] before this Component is removed from the Entity.
## May be connected to by subclasses to perform cleanup specific to each component.
## NOTE: [member entity] is still assigned at this point and set to `null` after this signal is emitted.
@warning_ignore("unused_signal") # Emitted from Entity.gd
signal willRemoveFromEntity

#endregion


#region Life Cycle
# INFO: Godot Node Life Cycle:
# Initialization: [Parented] → [Enter Tree] → [Ready]
# Deletion: [Exit Tree] → [Unparented]
# Each of these phases may include multiple events such as _notification(), function callbacks, and signals.

# Init:						Component.NOTIFICATION_PARENTED  → Component.onParented() → Entity.onComponent_parented()	  → Entity.installComponent() → Component.onDidInstall()		→ Component._enter_tree()	  → Component._ready()
# Component.queue_free():	Component.NOTIFICATION_PREDELETE → Component._exit_tree() → Component.NOTIFICATION_UNPARENTED → Component.onUnparented()  → Entity.onComponent_unparented()	→ Entity.uninstallComponent() → Component.onWillUninstall()
# Entity.queue_free():		Component._exit_tree()			 → Component.NOTIFICATION_PREDELETE → …


## Godot Engine notifications.
## ALERT: Subclasses should NOT call `super._notification()` because unlike other virtual methods, Godot calls inherited [method Object._notification] automatically, usually the base class first.
## TIP: External scripts that require access to a Component's [member entity] for cleanup should connect to the component's [signal willRemoveFromEntity] which is emitted before [member entity] is set to `null`
func _notification(what: int) -> void:
	# Init Order: 1
	# Deinit Order: 1/3
	# DESIGN: HACK: Dumbdot has no straightforward way for a parent node to react to the addition/removal of specific children (there's only a moronic NOTIFICATION_CHILD_ORDER_CHANGED)
	# so child nodes must forward these notifications to a callback on the parent.
	match what:
		NOTIFICATION_PARENTED:   onParented()   # Received when a node is set as the child of another node, not necessarily when the node enters the SceneTree.
		NOTIFICATION_UNPARENTED: onUnparented() # Received when a parent calls remove_child() on a child node, not necessarily when the node exits the SceneTree.
		NOTIFICATION_PREDELETE:  if isLoggingEnabled and Debug: printLog(str("[color=brown]", Debug.deleteLogSymbol, " PreDelete", (" • Entity: " + entity.logName) if entity else "")) # Make sure Debug exists to avoid crash at shutdown
		# NOTIFICATION_PREDELETE may occur before OR after _exit_tree() depending on whether the node itself or a parent is being queue_free()'ed


## A simple relay to [method Entity.onComponent_parented] → [method Entity.installComponent]
## Called from [method Component._notification] on [constant Component.NOTIFICATION_PARENTED]
## INFO: This is a workaround for Godot's lack of a direct way for parent nodes to react to the addition of a child node.
func onParented() -> void:
	# Init Order: 2: After Component._notification() on NOTIFICATION_PARENTED
	initializeLog()
	if debugMode: printDebug("onParented()")
	var parent: Node = self.get_parent()
	if  parent is Entity: parent.onComponent_parented(self)


## May be implemented in subclasses.
func onDidInstall() -> void:
	# Init Order: 3: After Entity.installComponent()
	if debugMode: printDebug(str("onDidInstall() in entity: ", self.entity))


## Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	# Init Order: 4: After Entity._enter_tree()
	if debugMode: printDebug(str("_enter_tree() parent: ", get_parent()))

	if not self.is_in_group(Global.Groups.components): self.add_to_group(Global.Groups.components, true) # persistent # TBD: Should this [also] be done by the Entity?

	var parent:		  Node	 = self.get_parent()
	var activeEntity: Entity = entity if is_instance_valid(entity) else parent as Entity

	printLog(Debug.initLogSymbol + " [b]_enter_tree() → " + (activeEntity.logName if activeEntity else str(parent)) + "[/b]", self.logFullName)

	if not activeEntity and not allowNonEntityParent:
		printWarning(str(Debug.initLogSymbol, " [b]_enter_tree(): Parent Node is not an Entity: ", parent, "[/b]"))

	# UNUSED: update_configuration_warnings() # Only useful if @tool script

	if activeEntity:
		checkRequiredComponents() # Ignore return; only called for logging # TBD: Should this be checked by the Entity or elsewhere in the startup sequence?
		# `coComponents` & logging flags & other properties are set by Entity.installComponent()
	else:
		self.coComponents = {} # Unlink from `entity.components` # AVOID: Do NOT self.coComponents.clear() because that will also .clear() entity's `components`!


# UNUSED: Implement in subclasses only.
# func _ready() -> void:
# 	if debugMode: printDebug(str("_ready(): ", self))
# 	pass


## NOTE: This method is called even when the Entity is removed from the SCENE (along with ALL its child nodes),
## so it does not necessarily mean that this Component was removed from the ENTITY.
func _exit_tree() -> void:
	# Deinit Order: 1 if Entity.queue_free() / 2 if Component.queue_free(): Before Component.NOTIFICATION_UNPARENTED, Entity._exit_tree()
	# NOTE: AVOID: `entity` must NOT be `null`ed here! nor `coComponents`!
	# because a Component may _exit_tree() while it is still a child of an Entity, if the Entity itself _exit_tree()s
	var entityName: String = entity.logName if entity else "null" # Check entity since components may be freed without being children of an Entity
	if Debug: printLog("[color=brown]" + Debug.exitLogSymbol + " _exit_tree() entity: " + entityName, self.logFullName) # # Make sure Debug exists to avoid crash at shutdown


## A simple relay to [method Entity.onComponent_unparented] → [method Entity.uninstallComponent]
## Called from [method Component._notification] on [constant Component.NOTIFICATION_UNPARENTED]
## INFO: This is a workaround for Godot's lack of a direct way for parent nodes to react to the removal of a child node.
func onUnparented() -> void:
	# Deinit Order 4: After Component._notification() on NOTIFICATION_UNPARENTED
	if isLoggingEnabled and Debug: printLog("[color=brown]" + Debug.deleteLogSymbol + " Unparented") # Make sure Debug exists to avoid crash at shutdown
	if self.entity: entity.onComponent_unparented(self)


## May be implemented in subclasses.
func onWillUninstall() -> void:
	# Deinit Order 5: After Entity.uninstallComponent() starts
	if debugMode: printDebug(str("onWillUninstall() from entity: ", entity.logFullName if entity else "null"))

#endregion


#region Validation

## NOTE: Used only if `@tool` is specified at the top of this script.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if not allowNonEntityParent and self.get_parent() is not Entity:
		warnings.append("Component nodes should be added to a parent which inherits from the Entity class.")

	if not checkRequiredComponents():
		warnings.append("This component is missing a required co-component. Check the getRequiredComponents() method.")

	return warnings


## Returns: A list of other component types which this component depends on.
## Must be overridden by subclasses.
func getRequiredComponents() -> Array[Script]:
	# This is needed to be a method because properties cannot be overridden :')
	return []


## Verifies the presence of dependencies as returned by [method getRequiredComponents].
## NOTE: Does not include subclasses of required components.
func checkRequiredComponents() -> bool:
	var requiredComponentTypes: Array[Script] = self.getRequiredComponents()
	if  requiredComponentTypes.is_empty(): return true # If there are no requirements, we have everything we need :)
	elif not entity or entity.components.keys().is_empty(): return false # If there are no other components, we don't have any of our requirements :(

	var haveAllRequirements: bool = true # Start `true` then make it `false` if there is any missing requirement.

	for requirement in requiredComponentTypes:
		# DEBUG: printDebug(str(requirement))
		# TBD: Include subclasses?
		if not entity.components.keys().has(requirement.get_global_name()): # Convert `Script` types to their `StringName` keys
			printWarning(str("Missing requirement: ", requirement.get_global_name(), " in ", entity.logName))
			haveAllRequirements = false

	return haveAllRequirements

#endregion


#region Family
# Join the serpent king!

## Returns a sibling [Component] from the [member coComponents] [Dictionary],
## after converting the [param type] [method Script.get_global_name] to a [StringName] key.
## NOTE: Unlike a direct [Dictionary] lookup, this method does not crash if a component/key does not exist.
## TIP: To include subclasses such as [ShieldedHealthComponent] when searching for [HealthComponent], set [param findSubclasses] to `true` to use [method Entity.findFirstComponentSubclass] when an exact match isn't found.
## ALERT: PERFORMANCE: Slower performance compared to accessing the [member coComponents] [Dictionary] directly!
## TIP: Use this method only if a warning is needed instead of a crash, in case of a missing component.
func getCoComponent(type: Script, findSubclasses: bool = false, warnIfMissing: bool = true) -> Component:
	# TBD: Is [Script] the correct type for the argument?
	
	if not is_instance_valid(entity): # If there's no entity, there are no other components!
		if warnIfMissing: printWarning("getCoComponent(): No parent entity!")
		return null

	if coComponents.is_empty(): return null
	
	var coComponent: Component = coComponents.get(type.get_global_name())
	if not coComponent: # TBD: Use is_instance_valid()?

		if findSubclasses: # Try subclasses
			coComponent = entity.findFirstComponentSubclass(type)
			if debugMode: printDebug(str("Searching for subclass of ", type, " in entity: ", entity, " — Found: ", coComponent))

		if warnIfMissing and not coComponent: # Did we still not find any match? :(
			printWarning(str("Missing co-component: ", type.get_global_name(), " in parent Entity: ", entity.logName, " • findSubclasses: ", findSubclasses))

	return coComponent


## Calls [method Entity.removeComponent] on the current [member entity] if any, and frees (deletes) the component if [param shouldFree]
func removeFromEntity(shouldFree: bool = true) -> void:
	if debugMode: printDebug(str("removeFromEntity() shouldFree: ", shouldFree))
	if entity: entity.removeComponent(self, shouldFree)
	else:
		printWarning("removeFromEntity(): Component has no Entity!")
		# DESIGN: Remove & delete the Node from its parent even it's not an Entity
		# That would be the behavior expected by the caller of this method
		# TBD: Check `allowNonEntityParent`?
		var parent: Node = self.get_parent()
		if  parent: parent.remove_child(self)
		if  shouldFree: self.queue_free()


## Calls [method queue_free] on itself and returns `true` if removed.
## May be overridden in subclasses to ask the parent [Entity] for approval and check additional conditions and logic.
func requestDeletion() -> bool:
	if debugMode: printDebug("requestDeletion()")
	self.queue_free()
	return true


## Returns `true` if the parent [Entity] agrees to [method Entity.requestDeletion] or if there is no [member entity].
func requestDeletionOfEntity() -> bool:
	if debugMode: printDebug(str("requestDeletionOfEntity() entity: ", entity.logName if entity else "null"))
	if entity:
		if entity.requestDeletion():
			return true
		else:
			if debugMode: printDebug(str("requestDeletionOfEntity(): requestDeletion() refused by ", entity.logName))
			return false
	else:
		if debugMode: printWarning("requestDeletionOfEntity(): entity already null!") # TBD: Should this be a warning?
		return true # NOTE: DESIGN: If a code calls this function, then it wants the Entity to be gone, so if it's already gone, we should return `true` :)

#endregion


#region Miscellaneous Interface

## Sets the [member isEnabled] flag, if available, to its opposite or [param overrideIsEnabled] if specified.
## Also optionally pauses/unpauses the component based on the resulting `isEnabled` state, or [param overrideIsEnabled] if there is no `isEnabled` flag.
## ALERT: Changes to [member isEnabled] may NOT be accepted based on subclass-specific property setters etc.
## WARNING: Unpausing always sets the [member Node.process_mode] to [constant Node.PROCESS_MODE_INHERIT] which may NOT be the previous/default setting before the pause.
## Returns: The resulting [member isEnabled] state if there is an `isEnabled` flag, otherwise `true` if [member Node.process_mode] is NOT [constant Node.PROCESS_MODE_DISABLED].
func toggleEnabled(overrideIsEnabled: Variant = null, togglePause: bool = false) -> bool:
	# TBD: CHECK: A better way to pause/unpause and save the previous value?
	# WARNING: Does NOT restore the component's previous state if it wasn't "INHERIT"

	if debugMode: printDebug(str("toggleEnabled(): isEnabled? ", (self.isEnabled if &"isEnabled" in self else "null"), ", override: ", overrideIsEnabled, ", togglePause: ", togglePause))

	if &"isEnabled" in self: # CHECK: Should it be a StringName?
		if overrideIsEnabled != null and overrideIsEnabled is bool:
			self.isEnabled = overrideIsEnabled
		else:
			self.isEnabled = not self.isEnabled

		if togglePause:
			# NOTE: Pause/unpause based on the final `isEnabled` state
			self.process_mode = PROCESS_MODE_INHERIT if self.isEnabled else PROCESS_MODE_DISABLED

		return self.isEnabled

	elif togglePause: # If there is no `isEnabled` property
		if overrideIsEnabled != null and overrideIsEnabled is bool:
			self.process_mode = PROCESS_MODE_INHERIT if overrideIsEnabled == true else PROCESS_MODE_DISABLED
		else:
			if self.process_mode != PROCESS_MODE_DISABLED: self.process_mode = PROCESS_MODE_DISABLED
			else: self.process_mode = PROCESS_MODE_INHERIT

	return self.process_mode != PROCESS_MODE_DISABLED # If there is no `isEnabled` just return `true` for any state except disabled

#endregion


#region Static Methods

## Attempts to cast any [Node] subtype as a specific component, since the `Component.gd` script may be attached to any Node.
## If the [param node] is not a [Component] of [param componentType] but the node's parent/grandparent is an [Entity], the entity is searched to find the matching [param componentType] if [param findInEntity].
## WARNING: May not find subclasses of [param componentType].
## @experimental
static func castOrFindComponent(node: Node, componentType: GDScript, findInEntity: bool = true) -> Component:
	# First, try casting the node itself.
	var component: Component = node.get_node(^".") as Component # HACK: Find better way to cast self?

	if is_instance_of(component, componentType): # CHECK: How does this handle subclasses?
		return component
	elif findInEntity: # Try to see if the node's grand/parent is an Entity
		var nodeParent: Entity = NodeTools.findFirstParentOfType(node, Entity)
		if nodeParent:
			component = nodeParent.components.get(componentType.get_global_name())
			# Does the entity have any matching component?
			if is_instance_of(component, componentType):
				return component
			else:
				Debug.printDebug(str("Node parent ", nodeParent, " has no ", componentType.get_global_name()), "Component.castOrFindComponent()")
				return null
		else:
			Debug.printDebug(str("Node parent is not an Entity: ", nodeParent), "Component.castOrFindComponent()")
			return null
	# Fail :(
	Debug.printDebug(str("Cannot cast ", node, " as ", componentType.get_global_name()), "Component.castOrFindComponent()")
	return null

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


var logName:				String = self.name  # Set defaults to avoid blank logs before initializeLog()
var logFullName:			String = str(self)  ## A detailed name for logging, including the node's name in the scene, instance, and the script's `class_name`.
var randomDebugColor:		Color  = Color.GRAY ## Used by logs and debugging tools etc. to distinguish different entities from each other.
var randomDebugColorCode:	String = "808080"   #  A default for pre-initializeLog()
var isLoggingInitialized:	bool

var logNameWithEntity:		String: ## [member Component.logName] + [member Entity.logName] if there is a [member entity]
	get: return self.logName + ((" " + entity.logName) if entity else "")

var logFullNameWithEntity:	String: ## [member Component.logFullName] + [member Entity.logFullName] if there is a [member entity]
	get: return self.logFullName + ((" " + entity.logFullName) if entity else "")


func initializeLog() -> void:
	if isLoggingInitialized: return
	if debugMode: Debug.printDebug(str("initializeLog(): ", self))
	randomDebugColor	 = Tools.getRandomQuantizedColorHue(Tools.sequenceTenths, Tools.sequenceQuarters.slice(1).pick_random()) # Prevent low saturation
	randomDebugColorCode = "[color=#" + randomDebugColor.to_html(false) + "]"
	updateLogNames()
	if not self.renamed.is_connected(self.updateLogNames): self.renamed.connect(self.updateLogNames, 0) # PERFORMANCE: Don't call Tools.connectSignal()
	isLoggingInitialized = true


func updateLogNames() -> void:
	var logSymbolWithColor: String = randomDebugColorCode + Debug.componentLogSymbol + "[/color] "
	logName		= logSymbolWithColor + self.name
	logFullName = str(logSymbolWithColor, self, ":", self.get_script().get_global_name())


func printLog(message: String = "", object: Variant = self.logName) -> void:
	if not isLoggingEnabled: return # PERFORMANCE: Callers may also check this to avoid String constructions/conversions before calling this method
	Debug.printLog(message, object, Global.Colors.logComponent, Global.Colors.logComponentName)


## Print a dim message for low priority events and superfluous tracing etc.
## Affected by [member debugMode], but NOT affected by [member isLoggingEnabled]
## TIP: Enable [member debugModeTrace] to track function call order and ALWAYS call [method Debug.printTrace] EVEN IF [member debugMode] is off.
## TIP: PERFORMANCE: Even though this method checks for [member debugMode], check for that flag before calling [method printDebug] to avoid unnecessary function calls like [method @GlobalScope.str] and improve performance.
func printDebug(message: String = "") -> void:
	# DESIGN: isLoggingEnabled is not respected for this method because we often need to disable common "bookkeeping" logs such as creation/destruction but we need debugging info when developing new features.
	if debugModeTrace:  Debug.printTrace(message.split(", "), logNameWithEntity, 3) # Start further from the call stack to skip this method # TBD: Split into array by ", " for the common usage case?
	elif debugMode:		Debug.printDebug(message, logName, Global.Colors.logComponentName)


## Calls [method Debug.printWarning]
## NOTE: Ignores [member isLoggingEnabled]
func printWarning(message: String = "") -> void:
	Debug.printWarning(message, logFullName, Global.Colors.logComponentName)


## Calls [method Debug.printError]
## NOTE: Ignores [member isLoggingEnabled]
func printError(message: String = "") -> void:
	Debug.printError(message, logFullName, Global.Colors.logComponentName)


## Prints an array of variables in a highlighted color, along with a short "stack trace" of recent functions and their filenames before [method Debug.printTrace] was called.
## TIP: Helpful for quick/temporary debugging of bugs currently under attention.
## Affected by [member debugMode] and only printed in debug builds.
func printTrace(...values: Array[Variant]) -> void:
	Debug.printTrace(values, logNameWithEntity, 3) # Start further from the call stack to skip this method


## Logs an entry showing a variable's previous and new values, IF there is a change and [member debugMode].
func printChange(variableName: String, previousValue: Variant, newValue: Variant, logAsDebug: bool = true) -> void:
	if debugMode and previousValue != newValue:
		var string: String = str(variableName, ": ", previousValue, " → ", newValue)
		if not logAsDebug: printLog("[color=gray]" + string)
		else: printDebug(string)


## Emits a [TextBubble] if [member debugMode] or [param ignoreDebugMode].
## IMPORTANT: [param emitFromEntity] must be set if the bubble is emitted from a [Node] Component (which has no position) or during a cleanup/"destructor" function,
## because otherwise the bubble may not be visible!
func emitDebugBubble(textOrObject: Variant, color: Color = self.randomDebugColor, emitFromEntity: bool = not is_instance_of(self, Node2D), ignoreDebugMode: bool = false) -> void:
	if not ignoreDebugMode and not debugMode: return
	if textOrObject is String and textOrObject.is_empty(): textOrObject = "\"\""

	@warning_ignore("incompatible_ternary")
	var bubble: TextBubble = TextBubble.create(str(textOrObject), \
		entity if emitFromEntity else self, \
		Vector2([-16, -8, 0, +8, +16].pick_random(), [-8, 0, +8].pick_random())) # Randomize position to reduce overlap

	bubble.label.label_settings.font_color = color
	bubble.z_index = 220
	
	# Customize the animation to improve readability
	if bubble.tween: bubble.tween.kill() # Stop the default TextBubble._ready() behavior...
	bubble.cancel_free()
	bubble.tween = Animations.bubble(bubble, Vector2(0, -32), 1.0, 1.0)
	bubble.tween.tween_callback(bubble.queue_free)

#endregion
