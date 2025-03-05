## Keeps track of all [Area2D]s currently in collision contact with this component's area.
## Only [Area2D]s with a [CollisionObject2D.collision_layer] that matches the [CollisionObject2D.collision_mask] of this component are added.

class_name AreaCollisionComponent
extends AreaComponentBase

# TODO: PERFORMANCE: A separate class for maintaining Arrays, so this class can be a base class for components that just need to react to events but don't require a list of contacts, so they can avoid wasting memory etc.
# TBD: Add a list for [TileMapLayer]s?
# TBD: Use this as the base for DamageComponent, ZoneComponent, etc.?
# TBD: Reduce code duplication between [CollisionsArrayArea]?

# DESIGN: Do not connect signals here; specific signals should only be connected in specific subclasses when they are needed, to improve performance.


#region Parameters

## If `false`, no new areas/bodies are added.
## Also effects [member Area2D.monitorable] and [member Area2D.monitoring]
## NOTE: Does NOT affect the REMOVAL of areas/bodies that exit contact with this component.
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			if selfAsArea: selfAsArea.monitorable = isEnabled
			# selfAsArea.monitoring  = isEnabled # Should be always disabled; WHY? To detect exits?

#endregion


#region State
var areasInContact:  Array[Area2D] ## A list of [Area2D]s currently in collision contact.
var bodiesInContact: Array[Node2D] ## A list of [PhysicsBody2D]s OR [TileMapLayer]s currently in collision contact.
#endregion


#region Signals
signal didEnterArea(area: Area2D) ## This signal is also emitted for each [Area2D] that was ALREADY in contact when this component is [method _ready]
signal didExitArea(area:  Area2D)
signal didEnterBody(body: Node2D) ## This signal is also emitted for each [PhysicsBody2D] OR [TileMapLayer] that was ALREADY in contact when this component is [method _ready]
signal didExitBody(body:  Node2D)
#endregion


func _ready() -> void:
	if selfAsArea: selfAsArea.monitorable = isEnabled
	connectSignals()
	readdAllContacts()


## Clears the [member areasInContact] & [member bodiesInContact] arrays and re-adds all [Area2D]s, [PhysicsBody2D]s or [TileMapLayer]s that are currently in contact with the [Area2D] of this component.
## Only [Area2D]s with a [CollisionObject2D.collision_layer] that matches the [CollisionObject2D.collision_mask] of this component are added.
## If not [member isEnabled], the list is cleared but no areas are added.
func readdAllContacts() -> void:
	# NOTE: Clear the list but don't add new areas/bodies if not enabled.
	# Because that seems like it would be the expected behavior.
	self.areasInContact.clear()
	self.bodiesInContact.clear()
	if not isEnabled: return

	for overlappingArea in selfAsArea.get_overlapping_areas():
		self.areasInContact.append(overlappingArea)
		self.didEnterArea.emit(overlappingArea) # TBD: Should this be emitted here?

	for overlappingBody in selfAsArea.get_overlapping_bodies():
		self.bodiesInContact.append(overlappingBody)
		self.didEnterBody.emit(overlappingBody) # TBD: Should this be emitted here?


#region Events

## Connects collision signals like [signal Area2D.area_entered] & [signal Area2D.body_entered] etc.
## NOTE: NOT called by the default/superclass implementation. Must be called manually by any class that `extends` [AreaCollisionComponentBase]
## TIP: To connect only specific signal(s), override this method WITHOUT calling `super.connectSignals()`
func connectSignals() -> void:
	Tools.reconnectSignal(area.area_entered, self.onArea_areaEntered)
	Tools.reconnectSignal(area.area_exited,  self.onArea_areaExited)
	Tools.reconnectSignal(area.body_entered, self.onArea_bodyEntered)
	Tools.reconnectSignal(area.body_exited,  self.onArea_bodyExited)


func onArea_areaEntered(areaEntered: Area2D) -> void:
	if debugMode: printDebug(str("areaEntered: ", areaEntered, ", owner: ", areaEntered.owner))
	if not isEnabled or areaEntered.owner == self or areaEntered.owner == self.parentEntity: return # Avoid running into ourselves
	areasInContact.append(areaEntered) # TBD: Make sure no area is added twice?
	didEnterArea.emit(areaEntered)
	self.onCollide(areaEntered)


func onArea_bodyEntered(bodyEntered: Node2D) -> void:
	if debugMode: printDebug(str("bodyEntered: ", bodyEntered, ", owner: ", bodyEntered.owner))
	if not isEnabled or bodyEntered.owner == self or bodyEntered.owner == self.parentEntity: return # Avoid running into ourselves
	bodiesInContact.append(bodyEntered) # TBD: Make sure no area is added twice?
	didEnterBody.emit(bodyEntered)
	self.onCollide(bodyEntered)


## NOTE: This is NOT affected by `isEnabled`; areas that exit should ALWAYS be removed!
func onArea_areaExited(areaExited: Area2D) -> void:
	if debugMode: printDebug(str("areaExited: ", areaExited, ", owner: ", areaExited.owner))
	if areaExited.owner == self or areaExited.owner == self.parentEntity: return # Avoid raising a ruckus if it's just ourselves
	areasInContact.erase(areaExited)
	didExitArea.emit(areaExited)
	self.onExit(areaExited)


## NOTE: This is NOT affected by `isEnabled`; bodies that exit should ALWAYS be removed!
func onArea_bodyExited(bodyExited: Node2D) -> void:
	if debugMode: printDebug(str("bodyExited: ", bodyExited, ", owner: ", bodyExited.owner))
	if bodyExited.owner == self or bodyExited.owner == self.parentEntity: return # Avoid raising a ruckus if it's just ourselves
	didExitBody.emit(bodyExited)
	self.onExit(bodyExited)


## Called when any [Area2D] or [PhysicsBody2D] or [TileMapLayer] comes into contact.
## Abstract; Must be implemented by subclass.
@warning_ignore("unused_parameter")
func onCollide(collidingNode: Node2D) -> void:
	pass


## Called when any [Area2D] or [PhysicsBody2D] or [TileMapLayer] leaves contact.
## Abstract; Must be implemented by subclass.
@warning_ignore("unused_parameter")
func onExit(exitingNode: Node2D) -> void:
	pass

#endregion
