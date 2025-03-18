## Emits signals when an [Area2D], [PhysicsBody2D] or [TileMapLayer] collides with this component's [Area2D].
## Only nodes with a [CollisionObject2D.collision_layer] that matches the [CollisionObject2D.collision_mask] of this component are added.
## Suitable as a base class for any component that needs to react to physics collisions.
## TIP: For a class that maintains a list of all objects currently in physics contact, use [AreaContactComponent].

class_name AreaCollisionComponent
extends AreaComponentBase

# TBD: Use this as the base for DamageComponent, ZoneComponent, etc.?

# DESIGN: Do not connect signals here; specific signals should only be connected in specific subclasses when they are needed, to improve performance.


#region Parameters

## If `false`, no new areas/bodies are reported.
## Also effects [member Area2D.monitorable] and [member Area2D.monitoring]
## NOTE: Does NOT affect the EXIT signals or REMOVAL of areas/bodies which leave contact with this component.
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			if selfAsArea: selfAsArea.monitorable = isEnabled
			# selfAsArea.monitoring  = isEnabled # Should be always disabled; WHY? To detect exits?

#endregion


#region Signals
signal didEnterArea(area: Area2D) ## This signal is also emitted for each [Area2D] that was ALREADY in contact when this component is [method _ready]. NOTE: Emitted AFTER [method onCollide]
signal didExitArea(area:  Area2D) ## NOTE: Emitted AFTER [method onExit]
signal didEnterBody(body: Node2D) ## This signal is also emitted for each [PhysicsBody2D] OR [TileMapLayer] that was ALREADY in contact when this component is [method _ready]. NOTE: Emitted AFTER [method onCollide]
signal didExitBody(body:  Node2D) ## NOTE: Emitted AFTER [method onExit]
#endregion


func _ready() -> void:
	if selfAsArea: selfAsArea.monitorable = isEnabled
	# connectSignals() # TBD: PERFORMANCE: Should be opted-in by subclasses.


#region Events

## Connects collision signals like [signal Area2D.area_entered] & [signal Area2D.body_entered] etc.
## NOTE: NOT called by the default/superclass implementation. Must be called manually by any class that `extends` [AreaCollisionComponentBase]
## TIP: To connect only specific signal(s), override this method WITHOUT calling `super.connectSignals()`
func connectSignals() -> void:
	Tools.connectSignal(area.area_entered, self.onArea_areaEntered)
	Tools.connectSignal(area.area_exited,  self.onArea_areaExited)
	Tools.connectSignal(area.body_entered, self.onArea_bodyEntered)
	Tools.connectSignal(area.body_exited,  self.onArea_bodyExited)


func onArea_areaEntered(areaEntered: Area2D) -> void:
	if debugMode: printDebug(str("areaEntered: ", areaEntered, ", owner: ", areaEntered.owner))
	if not isEnabled or areaEntered.owner == self or areaEntered.owner == self.parentEntity: return # Avoid running into ourselves
	self.onCollide(areaEntered)
	didEnterArea.emit(areaEntered)


func onArea_bodyEntered(bodyEntered: Node2D) -> void:
	if debugMode: printDebug(str("bodyEntered: ", bodyEntered, ", owner: ", bodyEntered.owner))
	if not isEnabled or bodyEntered.owner == self or bodyEntered.owner == self.parentEntity: return # Avoid running into ourselves
	self.onCollide(bodyEntered)
	didEnterBody.emit(bodyEntered)


## NOTE: This is NOT affected by `isEnabled`; areas that exit should ALWAYS be removed!
func onArea_areaExited(areaExited: Area2D) -> void:
	if debugMode: printDebug(str("areaExited: ", areaExited, ", owner: ", areaExited.owner))
	if areaExited.owner == self or areaExited.owner == self.parentEntity: return # Avoid raising a ruckus if it's just ourselves
	self.onExit(areaExited)
	didExitArea.emit(areaExited)


## NOTE: This is NOT affected by `isEnabled`; bodies that exit should ALWAYS be removed!
func onArea_bodyExited(bodyExited: Node2D) -> void:
	if debugMode: printDebug(str("bodyExited: ", bodyExited, ", owner: ", bodyExited.owner))
	if bodyExited.owner == self or bodyExited.owner == self.parentEntity: return # Avoid raising a ruckus if it's just ourselves
	self.onExit(bodyExited)
	didExitBody.emit(bodyExited)


## Called when any [Area2D] or [PhysicsBody2D] or [TileMapLayer] comes into contact.
## NOTE: Called BEFORE [signal didEnterArea] or [signal didEnterBody] is emitted, to let subclasses such as [AreaContactComponent] to modify the state before signal handlers.
## Abstract; Must be implemented by subclass.
@warning_ignore("unused_parameter")
func onCollide(collidingNode: Node2D) -> void:
	pass


## Called when any [Area2D] or [PhysicsBody2D] or [TileMapLayer] leaves contact.
## NOTE: Called BEFORE [signal didExitArea] or [signal didExitBody] is emitted, to let subclasses such as [AreaContactComponent] to modify the state before signal handlers.
## Abstract; Must be implemented by subclass.
@warning_ignore("unused_parameter")
func onExit(exitingNode: Node2D) -> void:
	pass

#endregion
