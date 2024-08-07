## A node which represents a distinct behavior or property of a game character or object.
## A parent node made up of component child nodes is an [Entity]. 
## Components may be reused in different kinds of entities, such as a [HealthComponent] used for the player's character and also the monsters.
## Components may directly modify the parent entity or interact with other sibling components, such as a [DamageReceivingComponent] modifying a [HealthComponent].

#@tool # Tool is not useful because it's not inherited :(
@icon("res://Assets/Icons/Component.svg")

class_name Component
extends Node


#region Core Properties
var parentEntity: Entity
#endregion


#region Life Cycle

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	self.add_to_group(Global.Groups.components, true)

	self.parentEntity = self.getParentEntity()
	update_configuration_warnings()

	if parentEntity:
		# NOTE: DESIGN: If the entity's logging flags are true, it makes sense to adopt them by default, 
		# but if the entity's logging is off and a specific component's logging is on, the component's flag should be respected.
		self.isLoggingEnabled = self.isLoggingEnabled or parentEntity.isLoggingEnabled
		self.shouldShowDebugInfo = self.shouldShowDebugInfo or parentEntity.shouldShowDebugInfo		
		printLog("􀈅 [b]_enter_tree() parentEntity: " + parentEntity.logName + "[/b]", self.logFullName)
	else:
		printWarning("􀈅 [b]_enter_tree() with no parentEntity![/b]")
	

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
	if not parentEntity or parentEntity.components.keys().is_empty(): return true # Nothing to do if there are no other components!
	
	var haveAllRequirements: bool = true # Start true then make it false if there is any missing requirement.
	var requiredComponentTypes: Array[Script] = self.getRequiredComponents()
	if requiredComponentTypes.is_empty(): return true # If there are no requirements, we have everything we need :)
	
	for requirement in requiredComponentTypes:
		# DEBUG: printDebug(str(requirement))
		if not parentEntity.components.keys().has(requirement):
			printWarning(str("? Missing requirement: ", requirement.get_global_name(), " in ", parentEntity.logName))
			haveAllRequirements = false
		
	return haveAllRequirements


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
	# TODO: Ask the parent entity for approval?
	self.queue_free()
	return true


func requestDeletionOfParentEntity() -> bool:
	return parentEntity.requestDeletion()


## Called on [const Node.NOTIFICATION_UNPARENTED]. Overridden by subclasses to perform cleanup specific to each component.
## NOTE: [member parentEntity] is still assigned at this point and `null` after this function returns.
func willRemoveFromEntity() -> void:
	# TBD: Should this be a signal?
	pass


func _exit_tree() -> void:
	# Since components may be freed without being children of an Entity:
	var entityName: String = parentEntity.logName if parentEntity else "null"
	printLog("􀈃 _exit_tree() parentEntity: " + entityName, self.logFullName)
	self.parentEntity = null


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_UNPARENTED:
			if parentEntity: 
				willRemoveFromEntity()
				self.parentEntity = null
				printLog("􀆄 Unparented")
		
		NOTIFICATION_PREDELETE:
			# NOTE: Cannot print [parentEntity] here because it will always be `null` (?)
			printLog("􀆄 PreDelete")

#endregion


#region Family
# Join the serpent king!

## Search for a parent node which is of type [Entity].
func getParentEntity() -> Entity:
	var parent: Node = self.get_parent() # parentOrGrandparent

	if not is_instance_of(parent, Entity):
		printWarning("Parent is not an Entity! This may prevent sibling components from finding this component. Parent: " + str(parent))

	# If parent is null or not an Entity, get the grandparent (parent's parent) and keep searching up the tree.
	while not (parent is Entity) and not (parent == null):
		printDebug("getParentEntity() searching non-Entity parent: " + str(parent))
		parent = parent.get_parent()

	#DEBUG printDebug("getParentEntity(): " + str(parent))
	return parent


## Searches the [member parentEntity.components] dictionary after converting the [param type] to a [StringName].
## NOTE: Does NOT find subclasses which inherit the specified type; use [method Entity.findFirstComponentSublcass] instead.
func getCoComponent(type: Script) -> Component:
	# CHECK: Is [Script] the correct type to accept as argument?
	# Duplicates code from `Entity.getComponent()` to improve performance?
	var typeName: StringName = type.get_global_name()
	var foundComponent: Component = parentEntity.components.get(typeName)
	if not foundComponent:
		printWarning("Cannot find " + typeName + " in parent Entity: " + parentEntity.logName)
	return foundComponent


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


#region Logging

## Enables more detailed debugging information for this component, such as verbose log messages, visual indicators, the [member Debug.watchList] live property labels, or chart windows etc.
## NOTE: Subclasses may add their own information or may not respect this flag.
## Defaults to the entity's [member Entity.shouldShowDebugInfo] if initially `false`.
@export var shouldShowDebugInfo: bool

## Defaults to the entity's [member Entity.isLoggingEnabled] if initially `false`.
var isLoggingEnabled: bool:
	get:
		if parentEntity: return parentEntity.isLoggingEnabled
		else: return true

var logName: String: # NOTE: This is a dynamic property because direct assignment would set the value before the `name` is set.
	get: return "􀥭 " + self.name

## A more detailed name including the node name, instance, and the script's `class_name`.
var logFullName: String:
	get: return "􀥭 " + str(self) + ":" + self.get_script().get_global_name()


func printLog(message: String = "", objectName: String = self.logName) -> void:
	if not isLoggingEnabled: return
	Debug.printLog(message, "lightBlue", objectName, "cyan")


func printDebug(message: String = "") -> void:
	if not isLoggingEnabled or not shouldShowDebugInfo: return
	Debug.printDebug(message, logName, "cyan")


func printWarning(message: String = "") -> void:
	if not isLoggingEnabled: return
	Debug.printWarning(message, logFullName, "cyan")


func printError(message: String = "") -> void:
	if not isLoggingEnabled: return
	Debug.printError(message, logFullName, "cyan")


## Logs an entry showing a variable's previous and new values, IF there is a change and [member shouldShowDebugInfo].
func printChange(variableName: String, previousValue: Variant, newValue: Variant, logAsDebug: bool = true) -> void:
	if shouldShowDebugInfo and previousValue != newValue:
		var string: String = str(variableName, ": ", previousValue, " → ", newValue)
		printLog("[color=gray]" + string) if not logAsDebug else printDebug(string)

#endregion
