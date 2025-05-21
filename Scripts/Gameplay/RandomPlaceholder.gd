## A subclass of [InstancePlaceholder] that may or may not be loaded (spawned) at runtime based on a specified chance, for nodes with `Load as Placeholder` enabled in the Godot Editor.
## Useful for placing predetermined random objects in a map or level at design time, such as monsters/chests/doors/etc.
## TIP: To use this with other scripts, such as [Entity], enclose the actual node in a container [Node2D] and use that as the placeholder.
## TIP: To replace any node with another scene, see [ReplaceWithRandomScene].gd

class_name RandomPlaceholder
extends InstancePlaceholder


#region Parameters

## The chance percentage of loading (spawning) the instance.
@export_range(0, 100, 1) var chance: int = 100

## An optional group to add the instantiated nodes to.
## May be used with [member maximumLimitInGroup] e.g. to make sure only 1 instance is created from a set of variants.
@export var groupToAddTo: StringName

## Stops loading instances if [member groupToAddTo] has the specified amount of members.
## If this value is -1 or any other negative number, then it is ignored.
## NOTE: If 0, then NO instances will be loaded EVEN IF [member groupToAddTo] has not been set.
@export var maximumLimitInGroup: int = -1

@export var debugMode: bool = false

#endregion


#region Signals
signal didCreateInstance(node: Node)
#endregion


func _ready() -> void:
	# NOTE: Not using call_deferred() does not work
	createInstance.call_deferred(true) # replace


## NOTE: Godot does not allow overriding native class methods such as [method create_instance] so it has to be a different name :(
func createInstance(replace: bool = true, customScene: PackedScene = null) -> Node:
	if chance <= 0:
		if debugMode: Debug.printDebug(str("chance: ", chance), self)
		return null

	# DESIGN: If 0 then don't load anything, even if there is no group.
	if maximumLimitInGroup == 0:
		if debugMode: Debug.printDebug("maximumLimitInGroup: 0", self)
		return null

	# Check the group limit

	if not groupToAddTo.is_empty() and maximumLimitInGroup > 0:
		var nodesInGroup: int = self.get_tree().get_node_count_in_group(groupToAddTo)
		if nodesInGroup >= maximumLimitInGroup:
			if debugMode: Debug.printDebug(str("nodes in group `", groupToAddTo, "`: ", nodesInGroup, " >= maximumLimitInGroup: ", maximumLimitInGroup), self)
			return null

	# Check the chance

	if chance < 100 and randi_range(1, 100) > chance: # i.e. if the chance is 10%, then any number from 1-10 should succeed. If 99% then 1% may fail.
		if debugMode: Debug.printDebug(str("Failed to roll <= chance: ", chance), self)
		return null

	# Roota Voota Zoot! Pull a live rabbit!

	var node := self.create_instance(replace, customScene)
	if not groupToAddTo.is_empty():
		node.add_to_group(groupToAddTo)

	if debugMode: Debug.printDebug(str("createInstance() → ", node, " → Group: ", groupToAddTo, " (", node.get_tree().get_node_count_in_group(groupToAddTo), ")"), self)
	self.didCreateInstance.emit(node)
	return node
