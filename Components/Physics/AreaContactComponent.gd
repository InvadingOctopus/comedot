## Keeps a list of all the [Area2D]s, [PhysicsBody2D]s or [TileMapLayer]s that are currently in collision contact with this component's area.
## Only nodes with a [CollisionObject2D.collision_layer] matching the [CollisionObject2D.collision_mask] of this component are added.
## TIP: PERFORMANCE: For a component that only emits signals but does not maintain an array of contacts, use [AreaCollisionComponent] to improve performance.

class_name AreaContactComponent
extends AreaCollisionComponent

# TODO: Disconnect signals when flags disabled
# TBD: Move signal flags to AreaCollisionComponent?
# TBD: Add a list for [TileMapLayer]s?
# TBD: Use this as the base for DamageComponent etc.?
# TBD: Reduce code duplication between [CollisionsArrayArea]?


#region Parameters
@export var shouldMonitorAreas:  bool = true ## If `false` no [Area2D]s are added OR removed in [member areasInContact]
@export var shouldMonitorBodies: bool = true ## If `false` no [PhysicsBody2D]s or [TileMapLayer]s are added OR removed in [member bodiesInContact]
@export var shouldConnectSignalsOnReady: bool = true ## TIP: PERFORMANCE: Connect signals in subclasses or via other scripts, to enable physics monitoring only needed.
#endregion


#region State
var areasInContact:  Array[Area2D] ## A list of [Area2D]s currently in collision contact.
var bodiesInContact: Array[Node2D] ## A list of [PhysicsBody2D]s OR [TileMapLayer]s currently in collision contact.
#endregion


func _ready() -> void:
	super._ready()
	readdAllContacts()
	if shouldConnectSignalsOnReady: connectSignals() # Start monitoring exits after adding existing overlaps
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
			areasInContact.append(overlappingArea)
			self.onCollide(overlappingArea)
			self.didEnterArea.emit(overlappingArea)

	if shouldMonitorBodies:
		for overlappingBody in selfAsArea.get_overlapping_bodies():
			bodiesInContact.append(overlappingBody)
			self.onCollide(overlappingBody)
			self.didEnterBody.emit(overlappingBody)


#region Events

## Connects collision signals like [signal Area2D.area_entered] & [signal Area2D.body_entered] etc.
## NOTE: NOT called by the default/superclass implementation. Must be called manually by any class that `extends` [AreaCollisionComponentBase]
## TIP: To connect only specific signal(s), override this method WITHOUT calling `super.connectSignals()`
func connectSignals() -> void:
	if shouldMonitorAreas:
		Tools.connectSignal(area.area_entered, self.onAreaEntered)
		Tools.connectSignal(area.area_exited,  self.onAreaExited)
	if shouldMonitorBodies:
		Tools.connectSignal(area.body_entered, self.onBodyEntered)
		Tools.connectSignal(area.body_exited,  self.onBodyExited)


# DESIGN: All functions below: Arrays should be updated before signals.
# There is code duplication from [AreaCollisionComponent] because the arrays must be updated in the middle of the functions :(


func onAreaEntered(areaEntered: Area2D) -> void:
	if not isEnabled or not shouldMonitorAreas or areaEntered.owner == self or areaEntered.owner == self.parentEntity: return
	if debugMode: printDebug(str("areaEntered: ", areaEntered, ", owner: ", areaEntered.owner))
	
	areasInContact.append(areaEntered)
	self.onCollide(areaEntered)
	didEnterArea.emit(areaEntered)


func onBodyEntered(bodyEntered: Node2D) -> void:
	if not isEnabled or not shouldMonitorBodies or bodyEntered.owner == self or bodyEntered.owner == self.parentEntity: return
	if debugMode: printDebug(str("bodyEntered: ", bodyEntered, ", owner: ", bodyEntered.owner))
	
	bodiesInContact.append(bodyEntered)
	self.onCollide(bodyEntered)
	didEnterBody.emit(bodyEntered)


## NOTE: Removals are NOT affected by [member isEnabled] but ARE affected by [member shouldMonitorAreas]
func onAreaExited(areaExited: Area2D) -> void:
	if not shouldMonitorAreas or areaExited.owner == self or areaExited.owner == self.parentEntity: return
	if debugMode: printDebug(str("areaExited: ", areaExited, ", owner: ", areaExited.owner))
	
	areasInContact.erase(areaExited)
	self.onExit(areaExited)
	didExitArea.emit(areaExited)


## NOTE: Removals are NOT affected by [member isEnabled] but ARE affected by [member shouldMonitorBodies]
func onBodyExited(bodyExited: Node2D) -> void:
	if not shouldMonitorBodies or bodyExited.owner == self or bodyExited.owner == self.parentEntity: return
	if debugMode: printDebug(str("bodyExited: ", bodyExited, ", owner: ", bodyExited.owner))
	
	bodiesInContact.erase(bodyExited)
	self.onExit(bodyExited)
	didExitBody.emit(bodyExited)

#endregion


#region Debug

func _physics_process(_delta: float) -> void:
	showDebugInfo()


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList[str("\n —", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.areasInContact  = self.areasInContact
	Debug.watchList.bodiesInContact = self.bodiesInContact

#endregion
