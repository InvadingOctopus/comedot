## Keeps a list of all the [Area2D]s, [PhysicsBody2D]s or [TileMapLayer]s that are currently in collision contact with this component's area.
## Only nodes with a [CollisionObject2D.collision_layer] matching the [CollisionObject2D.collision_mask] of this component are added.
## TIP: PERFORMANCE: For a component that only emits signals but does not maintain an array of contacts, use [AreaCollisionComponent] to improve performance.

class_name AreaContactComponent
extends AreaCollisionComponent

# TBD: Add a list for [TileMapLayer]s?
# TBD: Reduce code duplication between [CollisionsArrayArea]?
# DESIGN: Areas cannot be shared between DamageComponent/DamageReceivingComponent etc. (why?)


#region Parameters
## If not empty, only physics nodes belonging to this group will be included in the contact lists, e.g. "zones" etc.
@export var groupToInclude: StringName # PERFORMANCE: Only 1 group is checked because comparing array-with-array "intersection" is slower.
#endregion


#region State
var areasInContact:  Array[Area2D] ## A list of [Area2D]s currently in collision contact.
var bodiesInContact: Array[Node2D] ## A list of [PhysicsBody2D]s OR [TileMapLayer]s currently in collision contact.
#endregion


func _ready() -> void:
	readdAllContacts()
	super._ready() # Start monitoring exits after adding existing overlaps
	self.set_physics_process(self.debugMode) # Disable per-frame debugging until needed


## Clears the [member areasInContact] & [member bodiesInContact] arrays and re-adds all [Area2D]s, [PhysicsBody2D]s or [TileMapLayer]s that are currently in contact with the [Area2D] of this component.
## If not [member isEnabled], the lists are cleared but no node are added. Affected by [member shouldMonitorAreas] and [member shouldMonitorBodies].
## NOTE: [signal didEnterArea], [signal didEnterBody] & [method onCollide] are called from here allow other scripts to react to any existing physical contact.
func readdAllContacts() -> void:
	# NOTE: Clear the list but don't add new areas/bodies if not enabled.
	# Because that seems like it would be the expected behavior.
	self.areasInContact.clear()
	self.bodiesInContact.clear()
	if not isEnabled: return

	# DESIGN: Arrays should be updated before signals.
	# Signals should be emitted for existing overlaps, so that other scripts can react.
	# like picking up a collectible item if we were already standing on it. (not that CollectibleComponent uses AreaContactComponent :')

	if shouldMonitorAreas:
		for overlappingArea in selfAsArea.get_overlapping_areas():
			if  (overlappingArea != parentEntity or overlappingArea.owner != parentEntity) \
			and (not groupToInclude.is_empty()  and overlappingArea.is_in_group(groupToInclude)):
				areasInContact.append(overlappingArea)
				self.onCollide(overlappingArea)
				self.didEnterArea.emit(overlappingArea)

	if shouldMonitorBodies:
		for overlappingBody in selfAsArea.get_overlapping_bodies():
			if  (overlappingBody != parentEntity or overlappingBody.owner != parentEntity) \
			and (not groupToInclude.is_empty()  and overlappingBody.is_in_group(groupToInclude)):
				bodiesInContact.append(overlappingBody)
				self.onCollide(overlappingBody)
				self.didEnterBody.emit(overlappingBody)


#region Events

# DESIGN: All functions below: Arrays should be updated before signals.
# There is code duplication from [AreaCollisionComponent] because the arrays must be updated in the middle of the functions :(
# Ignore collisions when the node is the parent Entity or any of its children.
# DESIGN: Let the methods that handle entry & addition take care of the checks; only recheck array membership during exit/removal.


func onAreaEntered(areaEntered: Area2D) -> void:
	if not isEnabled or not shouldMonitorAreas \
	or (areaEntered == parentEntity or areaEntered.owner == parentEntity) \
	or (not groupToInclude.is_empty() and not areaEntered.is_in_group(groupToInclude)): return

	if debugMode:
		printDebug(str("areaEntered: ", areaEntered, ", owner: ", areaEntered.owner))
		emitDebugBubble(str("IN:", areaEntered, "\n", areaEntered.owner), Color.YELLOW)

	areasInContact.append(areaEntered)
	self.onCollide(areaEntered)
	didEnterArea.emit(areaEntered)


func onBodyEntered(bodyEntered: Node2D) -> void:
	if not isEnabled or not shouldMonitorBodies \
	or bodyEntered == parentEntity or bodyEntered.owner == parentEntity \
	or (not groupToInclude.is_empty() and not bodyEntered.is_in_group(groupToInclude)): return

	if debugMode:
		printDebug(str("bodyEntered: ", bodyEntered, ", owner: ", bodyEntered.owner))
		emitDebugBubble(str("IN:", bodyEntered, "\n", bodyEntered.owner), Color.YELLOW)

	bodiesInContact.append(bodyEntered)
	self.onCollide(bodyEntered)
	didEnterBody.emit(bodyEntered)


## NOTE: Removals are NOT affected by [member isEnabled] but ARE affected by [member shouldMonitorAreas].
## NOTE: [method onExit] & [signal didExitArea] are only called if the exiting area is in [member areasInContact].
func onAreaExited(areaExited: Area2D) -> void:
	if not shouldMonitorAreas or not areasInContact.has(areaExited): return
	if debugMode:
		printDebug(str("areaExited: ", areaExited, ", owner: ", areaExited.owner))
		emitDebugBubble(str("OUT:", areaExited, "\n", areaExited.owner), Color.ORANGE)

	areasInContact.erase(areaExited)
	self.onExit(areaExited)
	didExitArea.emit(areaExited)


## NOTE: Removals are NOT affected by [member isEnabled] but ARE affected by [member shouldMonitorBodies].
## NOTE: [method onExit] & [signal didExitBodt] are only called if the exiting body is in [member bodiesInContact].
func onBodyExited(bodyExited: Node2D) -> void:
	if not shouldMonitorBodies or not bodiesInContact.has(bodyExited): return
	if debugMode:
		printDebug(str("bodyExited: ", bodyExited, ", owner: ", bodyExited.owner))
		emitDebugBubble(str("OUT:", bodyExited, "\n", bodyExited.owner), Color.ORANGE)

	bodiesInContact.erase(bodyExited)
	self.onExit(bodyExited)
	didExitBody.emit(bodyExited)

#endregion


#region Debug

func _physics_process(_delta: float) -> void:
	showDebugInfo()


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.addComponentWatchList(self, {
		areasInContact	= areasInContact,
		bodiesInContact	= bodiesInContact})

#endregion
