#@tool
@icon("res://Assets/Icons/Component.svg")

class_name Component
extends Node


var parentEntity: Entity


#region Logging

var isLoggingEnabled: bool:
	get:
		if parentEntity: return parentEntity.isLoggingEnabled
		else: return true

var logName: String: # NOTE: This is a dynamic property because direct assignment would set the value before the `name` is set.
	get: return "􀥭 " + self.name

## A more detailed name including the node name, instance, and the script's `class_name`.
var logFullName: String:
	get: return "􀥭 " + str(self) + ":" + self.get_script().get_global_name()


func printLog(message: String = "", objectName: String = self.logName):
	if not isLoggingEnabled: return
	Debug.printLog(message, "lightBlue", objectName, "cyan")


func printDebug(message: String = ""):
	if not isLoggingEnabled: return
	Debug.printDebug(message, logName, "cyan")


func printWarning(message: String = ""):
	if not isLoggingEnabled: return
	Debug.printWarning(message, logFullName, "cyan")


func printError(message: String = ""):
	if not isLoggingEnabled: return
	Debug.printError(message, logFullName, "cyan")

#endregion


#region Life Cycle

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if not is_instance_of(self.get_parent(), Entity):
		warnings.append("Component nodes should be added to a parent which inherits from the Entity class.")

	return warnings


# Called when the node enters the scene tree for the first time.
func _enter_tree():
	self.add_to_group(Global.Groups.components, true)

	self.parentEntity = self.getParentEntity()
	update_configuration_warnings()

	if parentEntity:
		printLog("􀈅 [b]_enter_tree() parentEntity: " + parentEntity.logName + "[/b]", self.logFullName)
	else:
		printWarning("􀈅 [b]_enter_tree() with no parentEntity![/b]")


## Calls [method queue_free()] on itself if the parent entity approves. Returns `true` if removed.
## May be overridden in subclasses to check additional conditions and logic.
func requestRemoval() -> bool:
	# TODO: Ask the parent entity for approval?
	self.queue_free()
	return true


func requestRemovalOfParentEntity() -> bool:
	return parentEntity.requestRemoval()


func _exit_tree():
	# Since components may be freed without being children of an Entity:
	var entityName: String = parentEntity.logName if parentEntity else "null"
	printLog("􀈃 _exit_tree() parentEntity: " + entityName, self.logFullName)
	self.parentEntity = null


func _notification(what: int):
	match what:
		NOTIFICATION_PREDELETE:
			# NOTE: Cannot print [parentEntity] here because it will always be `null` (?)
			printLog("􀆄 PreDelete")

#endregion


#region Family

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


func findCoComponent(type: Script) -> Component:
	# CHECK: Is [Script] the correct type to accept as argument?
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
			sibling.requestRemoval()
			removalCount += 1

	return removalCount

#endregion
