## A subclass of [AreaContactComponent] that only monitors [Area2D]s and adds them to separate "zones" list if they belong to the "zones" group.
## NOTE: The zone [Area2D]s must also have a [CollisionObject2D.collision_layer] matching the [CollisionObject2D.collision_mask] of this component to be detected.
## Intended to be subclassed for game-specific functionality.
## Examples: A "home zone" which heals the player, or a hazardous region of fire or poison which causes damage.

class_name ZoneComponent
extends AreaContactComponent

# TODO: Option to choose any Group name.
# TBD:  Replace ZoneComponent with AreaContactComponent + Group-filtering parameter?


#region Signals
signal didEnterZone(zoneArea: Area2D) ## Emitted BEFORE [signal AreaCollisionComponent.didEnterArea]
signal didExitZone(zoneArea:  Area2D) ## Emitted BEFORE [signal AreaCollisionComponent.didExitArea]
signal didUpdateZones ## Emitted when the [member currentZones] array is updated, BEFORE [signal didEnterZone] or [signal didExitZone]
#endregion


#region State
var currentZones: Array[Area2D] ## The list of [Area2D]s which belong to the "zones" group and overlap this component's area.
#endregion


func _ready() -> void:
	self.shouldMonitorAreas  = true
	self.shouldMonitorBodies = false
	self.shouldConnectSignalsOnReady = true
	super._ready()


func readdAllContacts() -> void:
	# Clear our list.
	currentZones.clear()
	super.readdAllContacts() # This will call onCollide() to add zones.
	return currentZones.size() # CHECK: How does this work if super is `-> void` lol?


#region Events 

func onCollide(collidingNode: Node2D) -> void:
	if debugMode: printDebug(str("onCollide(): ", collidingNode, ", currentZones: ", currentZones.size()))
	if collidingNode is Area2D and collidingNode.is_in_group(Global.Groups.zones) and self.currentZones.count(collidingNode) <= 0: # Add it to the [currentZones] array if it isn't already in it.
		currentZones.append(collidingNode)
		didUpdateZones.emit()
		didEnterZone.emit(collidingNode)


func onExit(exitingNode: Node2D) -> void:
	# TBD: Check group during removal too? What if group changes after adding?
	if exitingNode is Area2D and exitingNode.is_in_group(Global.Groups.zones) and self.currentZones.count(exitingNode) >= 1:
		if debugMode: printDebug(str("onExit(): ", exitingNode, ", currentZones: ", currentZones.size()))
		currentZones.erase(exitingNode)
		didUpdateZones.emit()
		didExitZone.emit(exitingNode)

#endregion


#region Debug

func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList[str("\n —", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.currentZones = self.currentZones

#endregion
