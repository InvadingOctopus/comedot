## Monitors an [Area2D] and emits signals when it collides with another [Area2D], [PhysicsBody2D] or [TileMapLayer].
## Only nodes with a [CollisionObject2D.collision_layer] matching the [CollisionObject2D.collision_mask] of this component are detected.
## Suitable as a base class for any component that needs to react to physics collisions.
## TIP: To maintain a list of all nodes currently in physics contact, use [AreaContactComponent]

class_name AreaCollisionComponent
extends AreaComponentBase

# TODO: Disconnect signals when flags disabled
# TBD: Use this as the base for DamageComponent etc.?


#region Parameters

## If `false`, no new areas/bodies are reported.
## Also effects [member Area2D.monitorable] but NOT [member Area2D.monitoring]
## NOTE: Does NOT affect the EXIT signals or REMOVAL of areas/bodies which leave contact with this component.
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			if selfAsArea: selfAsArea.monitorable = isEnabled
			# selfAsArea.monitoring = isEnabled # Should be always enabled, to detect exits.

@export var shouldMonitorAreas:  bool = true ## If `false` no [Area2D]s are monitored when entering or exiting.
@export var shouldMonitorBodies: bool = true ## If `false` no [PhysicsBody2D]s or [TileMapLayer]s are monitored when entering or exiting.
@export var shouldConnectSignalsOnReady: bool = false ## TIP: PERFORMANCE: Enable physics monitoring only needed, or connect signals in a subclass or via other scripts which depend on the events.

#endregion


#region Signals
signal didEnterArea(area: Area2D) ## This signal is also emitted for each [Area2D] that was ALREADY in contact when this component is [method _ready]. NOTE: Emitted AFTER [method onCollide]
signal didExitArea(area:  Area2D) ## NOTE: Emitted AFTER [method onExit]
signal didEnterBody(body: Node2D) ## This signal is also emitted for each [PhysicsBody2D] OR [TileMapLayer] that was ALREADY in contact when this component is [method _ready]. NOTE: Emitted AFTER [method onCollide]
signal didExitBody(body:  Node2D) ## NOTE: Emitted AFTER [method onExit]
#endregion


func _ready() -> void:
	if selfAsArea: selfAsArea.monitorable = isEnabled
	if shouldConnectSignalsOnReady: connectSignals()


#region Events

## Connects collision signals like [signal Area2D.area_entered] & [signal Area2D.body_entered] etc.
## NOTE: NOT called by the default/superclass implementation. Must be called manually by any class that `extends` [AreaCollisionComponent]
## TIP: To connect only specific signal(s), override this method WITHOUT calling `super.connectSignals()`
func connectSignals() -> void:
	if shouldMonitorAreas:
		Tools.connectSignal(area.area_entered, self.onAreaEntered)
		Tools.connectSignal(area.area_exited,  self.onAreaExited)
	if shouldMonitorBodies:
		Tools.connectSignal(area.body_entered, self.onBodyEntered)
		Tools.connectSignal(area.body_exited,  self.onBodyExited)


# DESIGN: All functions below: Ignore collisions when the node is the parent Entity or any of its children.
# TBD: Should removals skip the parent check?

func onAreaEntered(areaEntered: Area2D) -> void:
	if debugMode: printDebug(str("areaEntered: ", areaEntered, ", owner: ", areaEntered.owner))
	if not isEnabled or not shouldMonitorAreas or areaEntered == self.parentEntity or areaEntered.owner == self.parentEntity: return 
	self.onCollide(areaEntered)
	didEnterArea.emit(areaEntered)


func onBodyEntered(bodyEntered: Node2D) -> void:
	if debugMode: printDebug(str("bodyEntered: ", bodyEntered, ", owner: ", bodyEntered.owner))
	if not isEnabled or not shouldMonitorBodies or bodyEntered == self.parentEntity or bodyEntered.owner == self.parentEntity: return
	self.onCollide(bodyEntered)
	didEnterBody.emit(bodyEntered)


## NOTE: This is NOT affected by [member isEnabled] but IS affected by [member shouldMonitorAreas]
func onAreaExited(areaExited: Area2D) -> void:
	if debugMode: printDebug(str("areaExited: ", areaExited, ", owner: ", areaExited.owner))
	if not shouldMonitorAreas or areaExited == self.parentEntity or areaExited.owner == self.parentEntity: return
	self.onExit(areaExited)
	didExitArea.emit(areaExited)


## NOTE: This is NOT affected by [member isEnabled] but IS affected by [member shouldMonitorBodies]
func onBodyExited(bodyExited: Node2D) -> void:
	if debugMode: printDebug(str("bodyExited: ", bodyExited, ", owner: ", bodyExited.owner))
	if not shouldMonitorBodies or bodyExited == self.parentEntity or bodyExited.owner == self.parentEntity: return
	self.onExit(bodyExited)
	didExitBody.emit(bodyExited)

#endregion


#region Abstract Methods

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
