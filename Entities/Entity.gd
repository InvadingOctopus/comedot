## The core of the composition framework. Represents a game character or object made up of modular and reusable behaviors provided by [Component] child nodes.
## Provides methods for managing components and other common tasks. The Entity is the "scaffolding" and Components do the actual work (play).
## NOTE: This script may be attached to ANY DESCENDANT of [Node2D].
## TIP: If the entity is a [CharacterBody2D] then a [CharacterBodyComponent] must be added as the last child, so other motion-manipulating components may queue their physics updates through it.

@icon("res://Assets/Icons/Entity.svg")

class_name Entity
extends Node2D # Any "entity" would almost always have a visual presence, so it cannot be just a [Node].


#region Core State

## A [Dictionary] of {StringName:Component} where the key is the `class_name` of each Component, as discovered via [method Script.get_global_name]
## Updated by [method installComponent] which is called by [method onComponent_parented] after the component's [constant Node.NOTIFICATION_PARENTED]
## PERFORMANCE: Used by components to quickly find other sibling components, to avoid requiring a dynamic search at runtime.
## ALERT: Does NOT resolve subclasses! i.e. a [ShieldedHealthComponent] will not be found if searching for a [HealthComponent]
## TIP: Call [method getComponent] with `findSubclasses` or [method findFirstComponentSubclass] to include subclasses.
var components:	Dictionary[StringName, Component]

## Set AFTER [method Entity._ready] finishes → [constant Entity.NOTIFICATION_READY]
## Used for notifying [Component]s via [method Component.onEntityDidReady]
## NOTE: This extra flag is necessary because [method Node.is_node_ready] is `true` BEFORE [method Node._ready] finishes.
var didReady:	bool # TBD: @export_storage?

## A [Dictionary] of functions that should be called only once per frame, for example [method CharacterBody2D.move_and_slide] on a [CharacterBody2D]
var functionsAlreadyCalledOnceThisFrame: Dictionary[StringName, Callable]

#endregion


#region Parameters
# PERFORMANCE: Not using `get`ters for the properties below to avoid extra calls on every access etc.
# Don't initialize these properties until they are needed, or it may slow performance when lots of entities are being created.

## The primary [Area2D] represented by this [Entity] for [Component]s to monitor or manipulate.
## If `null`, the [Entity] node itself will be used if it's an [Area2D],
## otherwise it will be the first matching child node.
## Call [method getArea] to set.
@export var area:	Area2D

## The primary [CharacterBody2D] represented by this [Entity] for [Component]s to monitor or manipulate.
## If `null`, the [Entity] node itself will be used if it's a [CharacterBody2D],
## otherwise it will be the first matching child node.
## Call [method getBody] to set.
@export var body:	CharacterBody2D

## The primary visual representation of this [Entity] for [Component]s to manipulate.
## If `null`, the [Entity] node itself will be used if it's an [AnimatedSprite2D] or [Sprite2D],
## otherwise it will be the first matching child node.
## Call [method getSprite] to set.
@export var sprite:	Node2D

#endregion


#region Signals

## Emitted after the [Entity] Node receives the [constant NOTIFICATION_PREDELETE] in [method _notification]
## Used by components and other scripts that must react to the imminent removal of the entity itself,
## e.g. when a [CameraComponent] wants to detach itself if [member CameraComponent.shouldAttachToGrandparentOnEntityRemoval] to preserve the current viewing location on screen.
## NOTE: This does NOT always mean that the node has exited the [SceneTree] (yet). Godot may send it on [method queue_free] which may happen BEFORE [constant NOTIFICATION_UNPARENTED] and the [signal Node.tree_exiting] signal etc.
signal preDelete # DESIGN: Named in camelCase to match the `willDo`/`didDo` etc. convention

#endregion


#region Life Cycle
# INFO: Godot Node Life Cycle:
# Initialization: [Parented] → [Enter Tree] → [Ready]
# Deletion: [Exit Tree] → [Unparented]
# Each of these phases may include multiple events such as _notification(), function callbacks, and signals.

# Entity Init: Entity.NOTIFICATION_PARENTED → Entity._enter_tree() → Component._enter_tree() → Component._ready() → Entity._ready() (excluding Component installation events) → Component.onEntityDidReady() if Component.shouldNotifyOnEntityReady
# Entity.queue_free(): Entity.NOTIFICATION_PREDELETE → Component._exit_tree() → Entity._exit_tree() → Entity.NOTIFICATION_UNPARENTED → Component.NOTIFICATION_PREDELETE → Component.NOTIFICATION_UNPARENTED … (component deinit & uninstallation)


## Godot Engine notifications.
## ALERT: Subclasses should NOT call `super._notification()` because unlike other virtual methods, Godot calls inherited [method Object._notification] automatically, usually the base class first.
func _notification(what: int) -> void:
	# Init Order: 1
	# Deinit Order: 1/3
	match what:
		NOTIFICATION_READY: # AFTER _ready() and BEFORE the `ready` Signal
			self.didReady = true # TBD: Set on [signal ready]?

		# Make sure Debug exists to avoid crash at shutdown
		NOTIFICATION_PREDELETE: # Sent after queue_free() or free() or scene/game shutdown. ALERT: May happen BEFORE "UNPARENTED" and before OR after _exit_tree() depending on whether the node itself or a parent is being queue_free()'ed etc.
			if isLoggingEnabled and Debug: printLog("[color=brown]" + Debug.deleteLogSymbol + " PreDelete")
			preDelete.emit()

		NOTIFICATION_UNPARENTED: # Sent when a node is removed from its parent or after _exit_tree() ALERT: May happen before OR after "PREDELETE"!
			if isLoggingEnabled and Debug: printLog("[color=brown]" + Debug.deleteLogSymbol + " Unparented")
			# UNUSED: unparented.emit() # Not needed yet


## Called whenever the Entity Node enters the Scene Tree. May be called multiple times.
## NOTE: Called BEFORE Components and child nodes enter the Scene.
func _enter_tree() -> void:
	# NOTE: This should not be `_ready()` because `_ready()` is called AFTER child nodes are loaded from the packed scene,
	# so signals like `child_entered_tree` will be missed for the initial components.
	initializeLog()
	if debugMode: printDebug("_enter_tree()")
	if not self.is_in_group(Global.Groups.entities): self.add_to_group(Global.Groups.entities, true) # persistent
	printLog(Debug.initLogSymbol + " [b]_enter_tree() → " + str(self.get_parent()) + "[/b]", self.logFullName)
	connectSignals()


## WARNING: When overriding in a subclass, call `super.connectSignals()`,
## but do NOT call [method Entity.connectSignals] manually from [method _enter_tree] or [method _ready], to ensure that all signals are connected and ONLY ONCE.
func connectSignals() -> void:
	if debugMode: printDebug("connectSignals()")
	pass
	# TBD: UNUSED: Unneeded for now
	# printDebug("connectSignals()")
	# Tools.connectSignal(self.child_entered_tree, self.onChildEnteredTree)
	# Tools.connectSignal(self.child_exiting_tree, self.onChildExitingTree)


## Stub that does nothing by default.
func _ready() -> void:
	# Init Order: ? After Component._ready()
	if debugMode: printDebug("_ready()")


## NOTE: Any subclass calling `super._physics_process()` must be aware that this method disables the per-frame processing by calling `set_physics_process(false)`
func _physics_process(_delta: float) -> void:
	# DEBUG: if debugMode: printDebug(str("_physics_process() delta: ", delta))
	# Clear the list of functions that are supposed to be called once per frame,
	# so they can be called again in the next frame.
	# NOTE: Use _physics_process() because it is called before _process() each frame: https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html
	# and callOnceThisFrame() is mostly used for physics anyway.
	# TBD: PERFORMANCE: Assess impact
	# if not functionsAlreadyCalledOnceThisFrame.is_empty(): # TBD: PERFORMANCE: Clear without checking?
	functionsAlreadyCalledOnceThisFrame.clear() # PERFORMANCE: Faster than = []
	self.set_physics_process(false) # No need to check every frame again. CHECK: Does this mess up anything unexpected?


## May be called by a child component such as a [HealthComponent] when this parent [Entity] is supposed to be removed from the scene.
## May be overridden in subclasses to check additional conditions and logic.
func requestDeletion() -> bool: # TBD: Should this be renamed to `requestDeletionOfEntity()`?
	if debugMode: printDebug("requestDeletion()")
	self.queue_free()
	return true


func _exit_tree() -> void:
	# Deinit Order: ?
	if Debug: # Make sure Debug exists to avoid crash at shutdown
		if debugMode: printDebug("_exit_tree()")
		printLog("[color=brown]" + Debug.exitLogSymbol + " _exit_tree() parent: " + str(self.get_parent()), self.logFullName)

#endregion


#region Component Life Cycle
# DESIGN: The Entity should perform and manage all of a Component's life cycle related tasks, to keep the base Component script lightweight.
# See `Life Cycle` in `Component.gd` for related information.

# PLAN: A child Node is added to the Entity Node → Is it a Component? → 
# 	→ Add the Component to the `components` Dictionary,
#	& Set the Component's `entity` reference to the parent Entity Node,
#	& Set the Component's `coComponents` reference to the Entity's `components` Dictionary. → 
#	→ Emit signals & call event hooks.


## A simple relay from [method Component.onParented] → [method Entity.installComponent]
## To be called from a [Component]'s [method Component._notification] on [constant Component.NOTIFICATION_PARENTED]
## INFO: This is a workaround for Godot's lack of a direct way for parent nodes to react to the addition of a child node.
func onComponent_parented(component: Component) -> bool:
	if debugMode: printDebug(str("onComponent_parented(): ", component))
	# First make sure the Component is a child of this Entity
	# TBD: Allow grandchildren and use is_ancestor_of()?
	var componentParent := component.get_parent()
	if  componentParent != self:
		printWarning(str("onComponent_parented(): ", component.logFullName, " has a different parent node that is not this Entity: ", componentParent))
		return false

	return installComponent(component)


## A simple relay from [method Component.onUnparented] → [method Entity.uninstallComponent]
## To be called from a [Component]'s [method Component._notification] on [constant Component.NOTIFICATION_UNPARENTED]
## INFO: This is a workaround for Godot's lack of a direct way for parent nodes to react to the removal of a child node.
func onComponent_unparented(component: Component) -> bool:
	if debugMode: printDebug(str("onComponent_unparented(): ", component))
	return uninstallComponent(component, false)


## Verifies a [Component] to check if it may be registered/installed into this [Entity]
## On success, returns an [Array] of [true, class_name, isDescendant, isKeyRegistered, isInstalled] so these values do not need to be recalculated by the caller.
## On failure, returns a single-element [Array] containing `false`
func validateComponent(component: Component) -> Array[Variant]:
	if debugMode: printDebug(str("validateComponent(): ", component))
	# TBD: PERFORMANCE: Are some of these checks excessive and liable to slow performance if many components are added in a short time?

	# DESIGN: Let a `null` reference cause a crash, because that's a serious error
	# if not is_instance_valid(component):
	# 	printWarning(str("validateComponent(): Invalid Component instance: ", component))
	# 	return [false]

	# DESIGN: Let a missing script cause a crash, cause that shit aint right
	# var script: Script = component.get_script()
	# if not script:
	# 	printWarning(str("validateComponent(): Component has no script: ", component.logFullName))
	# 	return [false]

	var className:	  StringName = component.get_script().get_global_name()
	if  className.is_empty():
		printWarning(str("validateComponent(): Component has no `class_name`: ", component.logFullName, " • script: ", component.get_script()))
		return [false]

	var isDescendant:		bool = component.get_parent() == self # TBD: Allow components that are not immediate child nodes? # self.is_ancestor_of(component)
	var isKeyRegistered:	bool = self.components.has(className)
	var isInstalled:		bool = isKeyRegistered and self.components[className] == component
	var componentParent:	Node = component.get_parent()

	# First, check for invalid or "corrupted" cases & states

	if not isDescendant:
		# If the Component is already installed but NOT a descendant, then that is an invalid state which should not have occurred; treat it as an error
		if isInstalled: printError(str("validateComponent(): ", component.logFullName, " is ALREADY registered in this Entity but has a DIFFERENT parent/grandparent Node: ", componentParent))
		else: printWarning(str("validateComponent(): ", component.logFullName, " has a different parent/grandparent Node that is not this Entity: ", componentParent))
		return [false]

	# PERFORMANCE: Return the commonly queried values so installComponent() etc. don't have to recheck
	return [true, className, isDescendant, isKeyRegistered, isInstalled] # TBD: BUGRISK: Is this too hacky? PERFORMANCE: A Dictionary would be less ambiguous but slower


## "Install" or "register" a [Component] into this [Entity]
## Called by [method onComponent_parented] after a [Component]'s [constant Component.NOTIFICATION_PARENTED]
## Adds a [Component] to the [member components] [Dictionary] for quicker access afterwards, with the component's `class_name` as the key.
## ALERT: Disallows duplicate components: A new component of the same type as a previously-registered component uninstalls and replaces the previous component!
## Returns `true` if successfully registered. ALERT: A component with missing dependencies counts as a successful installation but may not work as expected.
func installComponent(component: Component) -> bool:
	if debugMode: printDebug(str("installComponent(): ", component))

	# Validate
	var validationResult:  Array = validateComponent(component)
	if  validationResult.is_empty() or validationResult[0] == false: return false

	var className:	  StringName = validationResult[1]
	# var isDescendant:		bool = validationResult[2] # Not needed yet, rechecked later
	var isKeyRegistered:	bool = validationResult[3]
	var isInstalled:		bool = validationResult[4]

	# Handle duplicates: Do we already have a component of the same type/key?
	if isKeyRegistered and not isInstalled:
		# Do we already have a different component installed with the same class/key?
		# DESIGN: If the new component fails installation, the previous component should not be restored, because the intent and expected result of this installComponent() call is to install the new component anyway.
		# TBD: Implement an option for allowing multiple components of the same type?
		var conflictingComponent: Component = self.components.get(className)
		if is_instance_valid(conflictingComponent):
			printLog(str("installComponent(): Replacing previous component of the same type: ", conflictingComponent.logFullName, " ← ", component.logFullName))
			# CHECK: Will removal be refused if called while adding other children?
			self.uninstallComponent(conflictingComponent, true) # shouldFree
			isKeyRegistered = self.components.has(className) # Confirm just in case
			if isKeyRegistered: # Still around?
				printWarning(str("installComponent(): Could not uninstall conflicting component: ", conflictingComponent))
				return false
		else:
			if debugMode: printWarning(str("installComponent(): Key already registered for an invalid instance: ", className))
			self.components.erase(className)

	# If already installed, just resync the state, log flags and recheck dependencies
	elif isInstalled:
		if debugMode: printDebug(str("installComponent(): components[&\"", className, "\"] already == ", component.logFullName))
		# UNUSED: TBD: PERFORMANCE: Let's not reapply everything until we've seen a case where it's necessary
		# component.entity			= self # Just in case
		# component.coComponents	= self.components
		# component.isLoggingEnabled= component.isLoggingEnabled or self.isLoggingEnabled
		# component.debugMode		= component.debugMode or self.debugMode
		# component.checkRequiredComponents()
		return true

	# Register this component's type/key

	# DESIGN: TRIED: Do NOT register the superclass of the component, such as &"HealthComponent" for [ShieldedHealthComponent].
	# REASON: This is too complicated to implement elegantly/reliably,
	# because many components share common base classes such as `Component`, `CharacterBodyDependentComponentBase`, `CooldownComponent` etc.
	# WORKAROUND: Use findFirstComponentSubclass() or getComponent() with `findSubclasses`

	self.components[className] = component
	if debugMode: printDebug(str("installComponent(): components[&\"", className, "\"] ← ", component.logFullName))

	# Recheck conditions to make sure the component was added successfully
	# UNUSED: TBD: PERFORMANCE: Is this necessary or is there a better way around this?
	# var isDescendant:  bool = component.get_parent() == self # PERFORMANCE: Try the faster check first
	# isKeyRegistered			= self.components.has(className)
	# isInstalled		 		= isKeyRegistered and self.components[className] == component

	## All OK?
	# if isDescendant and isInstalled:

	# Set the Component's properties
	component.entity		= self
	component.coComponents	= self.components

	# NOTE: DESIGN: If the entity's logging flags are `true`, it makes sense to also enable all its component's logging by default,
	# but if the entity's logging is off and a specific component's logging is on, the component's flag should be respected.
	# TBD: Should this behavior be an additional option?
	component.isLoggingEnabled	= component.isLoggingEnabled or self.isLoggingEnabled
	component.debugMode			= component.debugMode or self.debugMode

	# Let the component perform its on-installation setup if any
	# DESIGN: Call onDidInstall() before onEntityDidReady() to allow per-component initialization before setup that depends on all other sibling nodes being ready.
	# DESIGN: Allow components with missing requirements, as they may still perform fallback/alternative behavior
	# UNUSED: Let Component._enter_tree() call component.checkRequiredComponents() # Ignore return; only called for logging
	component.onDidInstall()
	if component.shouldNotifyOnEntityReady: connectComponentSignals(component) # PERFORMANCE: Connect only if needed

	return true

	# TBD: PERFORMANCE: Revalidate all other checks like is_ancestor_of() etc? component.entity == self # Just in case it got mutated during onDidInstall()
	# else:
	# 	printWarning(str("installComponent(): ", component.logFullName, " failed. isDescendant: ", isDescendant, ", isInstalled: ", isInstalled))
	# 	return false


## @experimental
func connectComponentSignals(component: Component) -> void:
	# TBD: PERFORMANCE: if component.entity != self: return
	# PERFORMANCE: Connect signals directly here instead of calling Tools.connectSignal()
	# NOTE: Used a "proxy" method to make sure the `Component.entity` is still this entity before calling Component.onEntityDidReady()
	var readyHandler: Callable = self.notifyComponentOnEntityReady.bind(component)

	if self.didReady:
		# Is this entity already _ready() & the component is also _ready() (i.e. an existing component added at runtime)?
		if component.is_node_ready():
			self.notifyComponentOnEntityReady(component) # TBD: .call_deferred() to ensure that Component._ready() finishes before calling Component.onEntityDidReady()?

		# Otherwise, wait for the component to finish running its _ready()
		# then let it know that the entity is _ready() too.
		elif not component.ready.is_connected(readyHandler):
			component.ready.connect(readyHandler, CONNECT_ONE_SHOT)

	# If this entity has not run _ready() yet (i.e. the scene is still being loaded),
	# let the component know later when this entity is ready.
	elif not self.ready.is_connected(readyHandler):
		self.ready.connect(readyHandler, CONNECT_ONE_SHOT)


## Calls [method Component.onEntityDidReady] to let a new [Component] know if/when this [Entity] has finished its [method Entity._ready]
## The entity is ready after ALL scene-loaded components and other child nodes are ready,
## so [method Component.onEntityDidReady] is ideal for any setup that depends on other components/nodes,
## such as validating node order or connecting with dependencies etc.
## NOTE: This is used as a "proxy" method instead of calling [method Component.onEntityDidReady] directly,
## so that every [method Component.onEntityDidReady] implementation doesn't have to perform entity verification etc.
## @experimental
func notifyComponentOnEntityReady(component: Component) -> void:
	if  component.entity == self: # NOTE: Make sure the component is still installed, in case it was removed/uninstalled before it finished _ready() etc.
		component.onEntityDidReady()


## Unregisters a [Component] from this [Entity] and frees (deletes) the Component [Node] if [param shouldFree] (`true` by default)
## NOTE: If [param shouldFree] is `false`, the Component's [Node] is NOT removed from the parent in the Scene Tree; a caller such as [method Component.removeFromEntity] must manually call [method Node.remove_child] on the [Entity] [Node].
## Called by [method onComponent_unparented] after a [Component]'s [constant Component.NOTIFICATION_UNPARENTED]
## Clears the `class_name` key from the [member components] [Dictionary]
## TIP: If [param shouldFree] is `false` the component is only removed but not freed and may be re-added to any other entity.
## Returns `true` if the component was found and successfully uninstalled.
func uninstallComponent(componentToRemove: Component, shouldFree: bool = true) -> bool:
	if isLoggingEnabled: printLog(str("[color=brown]uninstallComponent(): ", (componentToRemove.logFullName if componentToRemove else "null"), " • shouldFree: ", shouldFree))

	# Validate arguments & state

	if not is_instance_valid(componentToRemove):
		printWarning("uninstallComponent(): Invalid Component instance")
		return false

	# DESIGN: Let a missing script cause a crash
	var className:	  StringName = componentToRemove.get_script().get_global_name()
	if  className.is_empty():
		printWarning(str("uninstallComponent(): Component has no `class_name`, cannot remove from `components` Dictionary: ", componentToRemove.logFullNameWithEntity, " • script: ", componentToRemove.get_script()))
		# If can't unregister the key, can still remove if needed
		if not shouldFree: return false

	# UNUSED:
	# var isDescendant:		bool = componentToRemove.get_parent() == self or self.is_ancestor_of(componentToRemove) # PERFORMANCE: Try the faster check first
	# var isKeyRegistered:	bool = self.components.has(className)
	# var isInstalled:		bool = isKeyRegistered and self.components[className] == componentToRemove
	# var componentParent:	Node = componentToRemove.get_parent()

	# Does the dictionary have a component of the same type?
	# NOTE: Make sure the component in the dictionary which matches the same type, is also the same INSTANCE that has been requested to be removed.

	var existingComponent: Component = self.components.get(className)

	if  existingComponent == null:
		printWarning(str("uninstallComponent(): Key not found in `components` Dictionary: \"", className, "\""))
		# NOTE: Don't leave yet, continue with the remaining cleanup

	elif existingComponent == componentToRemove:
		# This is where the unmagic happens
		componentToRemove.willRemoveFromEntity.emit()
		componentToRemove.onWillUninstall()
		self.components.erase(className)
		# The rest of the cleanup will happen below regardless of whether the key is registered or not

	else:
		printError(str("uninstallComponent(): Component type key \"", className, "\" in `components` Dictionary but value: ", existingComponent.logFullNameWithEntity, " is not the same as componentToRemove: ", componentToRemove.logFullNameWithEntity))
		# NOTE: TBD: This is a weird situation which should not happen, so it must be considered an error.
		return false

	# DESIGN: Even if the component is not fully installed, clear its state anyway,
	# because the intent and expected behavior of calling uninstallComponent() would be to unlink a component from an entity
	if componentToRemove.shouldNotifyOnEntityReady: disconnectComponentSignals(componentToRemove) # TBD: Disconnect always? BUGRISK: If `shouldNotifyOnEntityReady` becomes `false` AFTER connectComponentSignals() then signals will remain connected!
	componentToRemove.coComponents	= {} # Unlink the reference, NOT .clear() because that clears the Entity's Dictionary too!
	componentToRemove.entity		= null # TBD: Use .set_deferred()?

	# TBD: Add a `shouldRemoveFromParent` option?
	# UNUSED: Let the caller remove the Node: self.remove_child.call_deferred(componentToRemove) # .call_deferred() to avoid "Parent node is busy adding/removing children, `remove_child()` can't be called at this time."
	if shouldFree: componentToRemove.queue_free()

	return true


## @experimental
func disconnectComponentSignals(component: Component) -> void:
	# TBD: Find and remove all `Entity.preDelete` connections too?
	# PERFORMANCE: Connect signals directly here instead of calling Tools.connectSignal()
	var readyHandler: Callable = self.notifyComponentOnEntityReady.bind(component)
	if  self.ready.is_connected(readyHandler):
		self.ready.disconnect(readyHandler)
	if  component.ready.is_connected(readyHandler):
		component.ready.disconnect(readyHandler)


# ## @experimental
# func onChildEnteredTree(node: Node) -> void:
# 	# UNUSED: Not necessary yet
# 	# NOTE: A child node will `_enter_tree()` even when this Entity is added to the SCENE,
# 	# so this method does not necessarily mean that a Component was added to the ENTITY.
# 	pass


# ## @experimental
# func onChildExitingTree(node: Node) -> void:
# 	# UNUSED: Not necessary yet
#	# NOTE: A child node will [method Node._exit_tree] even when this Entity is removed from the SCENE,
#	# so this method does not necessarily mean that a Component was removed from the ENTITY.
# 	pass

#endregion


#region External Component Management Interface

## Checks the [member Entity.components] [Dictionary] for a key matching the [param type] [Script]'s [method Script.get_global_name] `class_name`.
func hasComponent(type: Script) -> bool:
	return self.components.keys().has(type.get_global_name())


## Returns a [Component] from the [member Entity.components] [Dictionary] after converting the [param type] to a [StringName] key.
## Returns `null` if there is no matching key. NOTE: Unlike a direct [Dictionary] lookup, this method does not crash if a component/key does not exist.
## TIP: To include subclasses such as [ShieldedHealthComponent] when searching for [HealthComponent], set [param findSubclasses] to `true` to use [method Entity.findFirstComponentSubclass] when an exact match isn't found.
func getComponent(type: Script, findSubclasses: bool = false) -> Component:
	# NOTE: The function is named "get" instead of "find" because "find" may imply a slower search of all children.
	var typeName:		StringName = type.get_global_name()
	var foundComponent:	Component  = self.components.get(typeName)
	if not foundComponent and findSubclasses:
		if debugMode: printDebug(str("getComponent(): ", typeName, " not found, trying findFirstComponentSubclass()"))
		foundComponent = self.findFirstComponentSubclass(type)
	# If no match, return `null` & let the caller handle crashing or logging a warning etc.
	return foundComponent


## Adds an EXISTING [Component] [Node] instance to this entity.
## The component must not already be a child of another parent node.
## This is a convenience method for adding components created and configured in code during runtime.
func addComponent(component: Component) -> void:
	self.add_child(component, self.debugMode) # PERFORMANCE: force_readable_name is slow so use only if debugging
	component.owner = self # For persistence in Save/Load


## Calls [method addComponent] on each of the component instances passed in the array.
## ATTENTION: Components must be added in order of dependencies! A component which depends on another must be listed after the required component in the array.
## Returns: The size of the [param componentsToAdd] array.
func addComponents(componentsToAdd: Array[Component]) -> int:
	for componentToAdd in componentsToAdd:
		self.addComponent(componentToAdd)
	return componentsToAdd.size()


## Creates a NEW copy of the specified component TYPE's scene and adds and returns an INSTANCE of it as a child node of this entity.
## Shortcut for [method load] + [method PackedScene.instantiate].
## ALERT: Some situations, such as adding a new component while the entity is being initialized, may cause the error: "Parent node is busy setting up children, `add_child()` failed. Consider using `add_child.call_deferred(child)` instead."
func createNewComponent(type: Script) -> Component:
	## NOTE: This is needed because adding components with `.new()` adds the script ONLY, NOT the scene!
	## and instantiating a scene is a lot of boilerplate code each time. :(

	## NOTE: This cannot be a static function on [Component],
	## because then GDScript will always run it on the [Component] script, not the subclasses we need. :(

	# First, construct the scene name from the script's name.
	var componentScenePath: String = SceneManager.getScenePathFromClass(type)
	if debugMode: printDebug(str("createNewComponent(", type, "): ", componentScenePath))

	# Load and instantiate the component scene.
	var newComponent := SceneManager.loadSceneAndAddInstance(componentScenePath, self)
	if debugMode: printDebug(str(newComponent))

	return newComponent


## Calls [method createNewComponent] on each of the component TYPES passed in the array.
## ATTENTION: Components must be added in order of dependencies! A component which depends on another must be listed after the required component in the array.
## Returns: An array of all the component INSTANCES that were successfully created and added.
func createNewComponents(componentTypesToCreate: Array[Script]) -> Array[Component]:
	var newComponents: Array[Component]
	for componentTypeToAdd in componentTypesToCreate:
		var newComponent := self.createNewComponent(componentTypeToAdd)
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
	printLog("findChildrenComponents(): " + str(childrenComponents))
	return childrenComponents


## Checks all components in the [member Entity.components] dictionary and returns the first matching component which inherits from the specified [param type].
## NOTE: Slower than [method Entity.getComponent]
func findFirstComponentSubclass(type: Script) -> Component:
	for component: Component in self.components.values():
		if is_instance_of(component, type):
			return component
	return null


## Removes the [param component] [Node] if it's a child of this entity, and frees (deletes) the component if [param shouldFree]
## Components that are only removed but not freed may be re-added to any entity.
func removeComponent(component: Component, shouldFree: bool = true) -> void:
	if debugMode: printDebug(str("removeComponent(): ", component, " • shouldFree: ", shouldFree))
	var componentParent: Node = component.get_parent()
	if  componentParent == self:
		self.remove_child(component) # This also eventually leads to uninstallComponent()
	else:
		if debugMode: printWarning(str("removeComponent(): ", component, " has a different parent Node that is not this Entity: ", componentParent))
	# If the caller requested obliteration, delete the Node even if it's not our child
	if shouldFree: component.queue_free()


## Removes a component that has been registered in the [member components] [Dictionary] and frees (deletes) the component unless [param shouldFree] is `false`  (useful for temporarily swapping components).
## NOTE: Removes only a SINGLE component of the specified type. To remove multiple children of the same type, use [method removeChildrenOfType]
func removeComponentType(componentType: Script, shouldFree: bool = true) -> bool:
	var component: Component = self.getComponent(componentType)

	if  component:
		self.removeComponent(component, shouldFree)
		return true
	else:
		return false


## Calls [method removeComponentType] on each of the component types passed in the array.
## [method Node.queue_free] will be called on each matching instance unless [param shouldFree] is `false` (useful for temporarily swapping components).
## Returns: The number of components that were found and removed.
func removeComponentTypes(componentTypes: Array[Script], shouldFree: bool = true) -> int:
	var removalCount: int = 0
	for componentType in componentTypes:
		if self.removeComponentType(componentType, shouldFree): removalCount += 1
	return removalCount


## Moves components from this entity to another and returns an array of all components that were successfully reparented.
func transferComponents(componentTypesToTransfer: Array[Script], newParent: Entity, keepGlobalTransform: bool = true, skipExistingComponents: bool = true) -> Array[Component]:
	if newParent == self:
		Debug.printWarning(str("transferComponents(): newParent is self!"))
		return []

	var transferredComponents: Array[Component]
	var component: Component

	for type in componentTypesToTransfer:
		component = self.getComponent(type)

		if component:

			if skipExistingComponents and newParent.getComponent(type):
				if debugMode: Debug.printDebug(str("transferComponents(): skipExistingComponents: ", component.logFullName, " already in ", newParent.logFullName))
				continue

			component.reparent(newParent, keepGlobalTransform)
			component.owner = newParent # For persistence etc. # CHECK: Necessary?

			if component.get_parent() == newParent and component.entity == newParent:
				transferredComponents.append(component)
			else:
				Debug.printWarning(str("transferComponents(): ", component, " could not be moved from ", self.logFullName, " to ", newParent.logFullName))
				continue
		else:
			printWarning(str("transferComponents(): ", self.logFullName, " does not have ", type))
			continue

	return transferredComponents


## Calls [method Component.toggleEnabled] on each of the listed components, to set their `isEnabled` flag, if available, to its opposite or [param overrideIsEnabled] if specified.
## Components may also be optionally paused/unpaused.
## Returns: An array of components that were enabled and/or unpaused.
## TIP: Example Usage: Quickly toggle player control between different characters without adding/removing components at runtime, which reduces performance.
func toggleComponents(componentTypes: Array[Script], overrideIsEnabled: Variant = null, togglePause: bool = false) -> Array[Component]:
	var enabledComponents: Array[Component]
	var component: Component

	for type in componentTypes:
		component = self.getComponent(type)
		if not component: continue
		if component.toggleEnabled(overrideIsEnabled, togglePause): enabledComponents.append(component)

	return enabledComponents

#endregion


#region General Child Node Management

## Returns the first child node which matches the specified [param type].
## If [param includeEntity] is `true` (default) then this ENTITY ITSELF may be returned if it's a node of a matching type. Useful for [Sprite2D] or [Area2D] etc. nodes with the `Entity.gd` script.
## NOTE: Also returns any SUBCLASSES which inherit from the specified [param type].
## ALERT: TIP: PERFORMANCE: [method Entity.findFirstComponentSubclass] is faster when searching for components including subclasses, as it only searches the [member Entity.components] dictionary.
func findFirstChildOfType(type: Variant, includeEntity: bool = true) -> Node:
	var result: Node = NodeTools.findFirstChildOfType(self, type, includeEntity)
	if debugMode: printDebug(str("findFirstChildOfType(", type, "): ", result))
	return result


## Returns the first child of [param parentNode] which matches ANY of the specified [param types] (searched in the array order).
## If [param returnEntityIfNoMatches] is `true` (default) then this ENTITY ITSELF is returned AFTER none of the requested types are found.
## This may be useful for choosing certain child nodes to operate on, like an [AnimatedSprite2D] or [Sprite2D] to animate, otherwise operate on the entity itself.
## WARNING: [param returnEntityIfNoMatches] returns the entity even if it is NOT one of the [param types]!
## PERFORMANCE: Should be the same as multiple calls to [method findFirstChildOfType] in order of the desired types.
func findFirstChildOfAnyTypes(types: Array[Variant], returnEntityIfNoMatches: bool = true) -> Node:
	# TBD: Better name
	var result: Node = NodeTools.findFirstChildOfAnyTypes(self, types, returnEntityIfNoMatches)
	if debugMode: printDebug(str("findFirstChildOfAnyTypes(", types, "): ", result))
	return result


## NOTE: Does NOT search children of children.
func findChildrenOfType(type: Variant) -> Array[Node]:
	var children: Array[Node] = self.get_children()
	var childrenFiltered: Array[Node]

	var filter := func matchesType(node: Node) -> bool:
		return is_instance_of(node, type)

	childrenFiltered.assign(children.filter(filter))
	printDebug("getChildrenOfType(" + str(type) + "): " + str(childrenFiltered))
	return childrenFiltered


## Instantiates a new copy of the specified scene path and adds it as a child node of this entity.
## Shortcut for [load] and [method PackedScene.instantiate].
func addSceneCopy(path: String) -> Node:
	return SceneManager.loadSceneAndAddInstance(path, self)


## Removes all child nodes of the specified type and frees (deletes) them if [param shouldFree] is `true`
## Returns: The number of children that were removed (0 means none were found).
func removeChildrenOfType(type: Variant, shouldFree: bool = true) -> int: # TBD: Should the return be a count or an array?
	var childrenToRemove: Array[Node] = self.findChildrenOfType(type)
	var childrenRemoved:  int = 0
	for child: Node in childrenToRemove:
		self.remove_child(child)
		if shouldFree: child.queue_free()
		childrenRemoved += 1

	printLog("removeChildrenOfType(" + str(type) + "): " + str(childrenRemoved))
	return childrenRemoved

#endregion


#region Lazy Property Initialization

## Returns the [member sprite] property or searches for an [AnimatedSprite2D] (searched first) or [Sprite2D].
## The sprite may be this [Entity] node itself, or the first matching child node.
func getSprite() -> Node2D:
	if self.sprite == null:
		if is_instance_of(self, AnimatedSprite2D) or is_instance_of(self, Sprite2D): # Check ourselves first
			self.sprite = self
		else:
			self.sprite = self.findFirstChildOfAnyTypes([AnimatedSprite2D, Sprite2D], false) # not returnEntityIfNoMatches

		if self.sprite == self: printLog("getSprite(): self")
		else: printLog(str("getSprite(): ", sprite))

	if self.sprite == null: printWarning("getSprite(): No AnimatedSprite2D or Sprite2D found!")
	return self.sprite


## Returns the [member area] property or searches for an [Area2D].
## The area may be this [Entity] node itself, or the first matching child node.
func getArea() -> Area2D:
	if self.area == null:

		# First, is the entity itself an [Area2D]?
		# PERFORMANCE: Handle this here before calling Tools.gd
		var selfAsArea: Area2D = get_node(".") as Area2D # HACK: Find better way to cast self?

		if selfAsArea:
			self.area = selfAsArea
			printLog("getArea(): self")
		else:
			self.area = findFirstChildOfType(Area2D, false) # not includeEntity because it was already checked
			printLog(str("getArea(): ", area))

	if self.area == null: printWarning("getArea(): No Area2D found!")
	return self.area


## Returns the [member body] property or searches for a [CharacterBody2D].
## The body may be this [Entity] node itself, or the first matching child node.
func getBody() -> CharacterBody2D:
	if self.body == null:

		# First, is the entity itself a [CharacterBody2D]?
		# PERFORMANCE: Handle this here before calling Tools.gd
		var selfAsBody: CharacterBody2D = get_node(".") as CharacterBody2D # HACK: Find better way to cast self?

		if selfAsBody:
			self.body = selfAsBody
			printLog("getBody(): self")
		else:
			self.body = findFirstChildOfType(CharacterBody2D, false) # not includeEntity because it was already checked
			printLog(str("getBody(): ", body))

	if self.body == null: printWarning("getBody(): No CharacterBody2D found!")
	return self.body

#endregion


#region Miscellaneous Methods

## Used to call any function only once during a single frame, such as [method CharacterBody2D.move_and_slide] on the [Entity]'s [CharacterBody2D].
## This ensures that multiple components which interact with the same node do not perform excessive updates, such as a [PlatformerPhysicsComponent] and a [JumpComponent].
## The [Callable] is added to the [member functionsAlreadyCalledOnceThisFrame] dictionary, and that list is then cleared during each [method _physics_process] frame/tick of this entity.
func callOnceThisFrame(function: Callable, arguments: Array = []) -> void:
	# Has the function already been called this frame?
	if not functionsAlreadyCalledOnceThisFrame.has(function.get_method()):
		# NOTE: TBD: We're not checking if the key matches the function we got now, just that the key exists?
		# DEBUG: printDebug("callOnceThisFrame(" + str(function) + ")")
		# First add it to the list so it doesn't get called again; this should avoid any recursion.
		self.functionsAlreadyCalledOnceThisFrame[function.get_method()] = function
		function.callv(arguments)
		self.set_physics_process(true) # PERFORMANCE: Clear the dictionary on the next frame, only once.


## Loads and instantiates a Scene and adds it to this Entity's parent node at the specified offset from this Entity's position.
## Returns the new instance (Node).
func spawnPath(scenePath: String, positionOffset: Vector2 = Vector2.ZERO, copyZIndex: bool = false) -> Node:
	var entityParent: Node = self.get_parent()
	if not entityParent:
		printWarning(str("spawnPath(): This Entity has no parent: ", self.logFullName))
		return null

	var newNode: Node = SceneManager.loadSceneAndAddInstance(scenePath, entityParent, self.position + positionOffset)
	if  copyZIndex and newNode is CanvasItem: newNode.z_index = self.z_index
	return newNode


## Adds an existing node to this Entity's parent node at the specified offset from this Entity's position.
## Removes the node from any other parent. Returns the same node.
func spawnNode(node: Node, positionOffset: Vector2 = Vector2.ZERO, copyZIndex: bool = false) -> Node:
	var entityParent: Node = self.get_parent()
	if not entityParent:
		printWarning(str("spawnNode(): This Entity has no parent: ", self.logFullName))
		return null

	if debugMode: printDebug(str("spawnNode(): ", node, " @", self.position, "+", positionOffset, " in ", entityParent))

	# Kidnap it from any other parent
	var otherParent: Node = node.get_parent()
	if otherParent != entityParent:
		if is_instance_valid(otherParent):
			if debugMode: printDebug(str("Removing from other parent: ", otherParent))
			otherParent.remove_child(node)
		entityParent.add_child(node)
		node.owner = entityParent

	if node is Node2D: node.position = self.position + positionOffset
	if copyZIndex and node is CanvasItem: node.z_index = self.z_index

	return node

#endregion


#region Logging

@export_group("Debugging")

## Enables log messages from this entity and its child [Component]s.
## NOTE: Does NOT affect warnings and errors!
@export var isLoggingEnabled: bool = true

## Enables more detailed debugging information for this entity, such as verbose log messages. Subclasses may add their own information or may not respect this flag.
## NOTE: Even though [method printDebug] also checks this flag, this flag should be checked before calls to `printDebug()` with functions such as `str()` that might reduce performance.
@export var debugMode:		bool = false


var logName:				String = self.name  # Set defaults to avoid blank logs before initializeLog()
var logFullName:			String = str(self)  ## A detailed name for logging, including the node's name in the scene, instance, and the script's `class_name`.
var randomDebugColor:		Color  = Color.GRAY ## Used by logs and debugging tools etc. to distinguish different entities from each other.
var randomDebugColorCode:	String = "808080"   #  A default for pre-initializeLog()
var isLoggingInitialized:	bool


func initializeLog() -> void:
	if isLoggingInitialized: return
	if debugMode: Debug.printDebug(str("initializeLog(): ", self))
	randomDebugColor	 = Tools.getRandomQuantizedColorHue(Tools.sequenceTenths, Tools.sequenceQuarters.slice(1).pick_random()) # Prevent low saturation
	randomDebugColorCode = "[color=#" + randomDebugColor.to_html(false) + "]"
	updateLogNames()
	if not self.renamed.is_connected(self.updateLogNames): self.renamed.connect(self.updateLogNames, 0) # PERFORMANCE: Don't call Tools.connectSignal()
	isLoggingInitialized = true


func updateLogNames() -> void:
	var logSymbolWithColor: String = randomDebugColorCode + Debug.entityLogSymbol + "[/color] "
	logName		= logSymbolWithColor + self.name # Entities just need to show their name, not their type, as they're almost always the same type/class
	logFullName = str(logSymbolWithColor, self, ":", self.get_script().get_global_name())


func printLog(message: String = "", object: Variant = self.logName) -> void:
	if not isLoggingEnabled: return
	Debug.printLog(message, object, Global.Colors.logEntity, Global.Colors.logEntityName)


## Print a dim message for low priority events and superfluous tracing etc.
## Affected by [member debugMode], but NOT affected by [member isLoggingEnabled]
## TIP: PERFORMANCE: Even though this method checks for [member debugMode], check for that flag before calling [method printDebug] to avoid unnecessary function calls like [method @GlobalScope.str] and improve performance.
func printDebug(message: String = "") -> void:
	# DESIGN: isLoggingEnabled is not respected for this method because we often need to disable common "bookkeeping" logs such as creation/destruction but we need debugging info when developing new features.
	if not debugMode: return
	Debug.printDebug(message, logName, Global.Colors.logEntityName)


## Calls [method Debug.printWarning]
## NOTE: Ignores [member isLoggingEnabled]
func printWarning(message: String = "") -> void:
	Debug.printWarning(message, logFullName, Global.Colors.logEntityName)


## Calls [method Debug.printError]
## NOTE: Ignores [member isLoggingEnabled]
func printError(message: String = "") -> void:
	Debug.printError(message, logFullName, Global.Colors.logEntityName)


## Logs an entry showing a variable's previous and new values, IF there is a change and [member debugMode].
func printChange(variableName: String, previousValue: Variant, newValue: Variant, logAsDebug: bool = true) -> void:
	if debugMode and previousValue != newValue:
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
# 	if debugMode and property == "velocity":
# 		previousVelocity = velocity
# 		if previousVelocity != value:
# 			var caller: Dictionary = get_stack()[2]
# 			var callerFunction: String = caller.source.get_file() + ":" + caller.function + "()"
# 			print(str(logName, " ", callerFunction, ": velocity ", previousVelocity, " → ", value))

# 	# Access normally
# 	return false

#endregion
