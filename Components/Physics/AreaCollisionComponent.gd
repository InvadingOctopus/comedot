## Monitors an [Area2D] and emits signals when it collides with another [Area2D], [PhysicsBody2D] or [TileMapLayer].
## Only nodes with a [CollisionObject2D.collision_layer] matching the [CollisionObject2D.collision_mask] of this component are detected.
## Suitable as a base class for any component that needs to react to physics collisions.
## TIP: To maintain a list of all nodes currently in physics contact, use [AreaContactComponent]

class_name AreaCollisionComponent
extends AreaComponentBase

# TODO: Disconnect signals when flags disabled
# TBD: Use this as the base for DamageComponent etc.?
# CHECK: Use get_parent() instead of `.owner`?


#region Parameters

## If `false`, no new collisiones are reported.
## Also effects [member Area2D.monitorable] but NOT [member Area2D.monitoring]
## NOTE: Does NOT affect the EXIT signals or REMOVAL of areas/bodies which leave contact with this component.
@export var isEnabled: bool = true: # TBD: Move to AreaComponentBase?
	set = setIsEnabled # Use a separate function for the property setter so that subclasses may override it.

## Property setter for [member isEnabled] as a separate function to let subclasses override it.
## IMPORTANT: Subclasses MUST call super.setIsEnabled(newValue)
func setIsEnabled(newValue: bool) -> void:
	if newValue != isEnabled:
		isEnabled = newValue
		if  area: # TBD: Only/also use selfAsArea?
			# NOTE: Cannot set flags directly because Godot error: "Function blocked during in/out signal"
			area.set_deferred(&"monitorable", newValue)
			# area.set_deferred(&"monitoring",  newValue) # Should be always enabled, to detect exits.


@export var shouldMonitorAreas:  bool = true ## If `false` no [Area2D]s are monitored when entering or exiting.
@export var shouldMonitorBodies: bool = true ## If `false` no [PhysicsBody2D]s or [TileMapLayer]s are monitored when entering or exiting.
@export var shouldConnectSignalsOnReady: bool = false ## TIP: PERFORMANCE: Enable physics monitoring only needed, or connect signals in a subclass or via other scripts which depend on the events.

#endregion


#region Signals
signal didEnterArea(area: Area2D) ## This signal is also emitted for each [Area2D] that was ALREADY in contact when this component is [method _ready]. NOTE: Emitted AFTER [method onCollide]
signal didExitArea (area: Area2D) ## NOTE: Emitted AFTER [method onExit]
signal didEnterBody(body: Node2D) ## This signal is also emitted for each [PhysicsBody2D] OR [TileMapLayer] that was ALREADY in contact when this component is [method _ready]. NOTE: Emitted AFTER [method onCollide]
signal didExitBody (body: Node2D) ## NOTE: Emitted AFTER [method onExit]
#endregion


func _ready() -> void:
	if area: area.monitorable = isEnabled # Apply setter because Godot doesn't on initialization
	if shouldConnectSignalsOnReady: connectSignals()


#region Validation

## Checks if an [Area2D] matches the criteria for emitting [method onCollide]/[signal didEnterArea]/[signal didExitArea] for.
## Subclasses may override this function to specify different conditions.
## ALERT: PERFORMANCE: The default implementation does NOT check [member shouldMonitorAreas] or [isEnabled]
func shouldIncludeArea(areaToCheck: Area2D) -> bool:
	return not (areaToCheck == entity or entity.is_ancestor_of(areaToCheck))


## Checks if a [PhysicsBody2D] or [TileMapLayer] matches the criteria for emitting [method onCollide]/[signal didEnterBody]/[signal didExitBody] for.
## Subclasses may override this function to specify different conditions.
## ALERT: PERFORMANCE: The default implementation does NOT check [member shouldMonitorBodies] or [isEnabled]
func shouldIncludeBody(bodyToCheck: Node2D) -> bool:
	return not (bodyToCheck == entity or entity.is_ancestor_of(bodyToCheck))

#endregion


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


# DESIGN: All functions below: Ignore collisions when the node is the parent Entity or any of its sub/children.
# TBD: Should removals skip the parent check?

func onAreaEntered(areaEntered: Area2D) -> void:
	if debugMode:
		printDebug(str("areaEntered: ", areaEntered, ", owner: ", areaEntered.owner))
		emitDebugBubble(str("IN:", areaEntered, "\n", areaEntered.owner), Color.YELLOW)
	if not isEnabled or not shouldMonitorAreas or not shouldIncludeArea(areaEntered): return 
	self.onCollide(areaEntered)
	didEnterArea.emit(areaEntered)


func onBodyEntered(bodyEntered: Node2D) -> void:
	if debugMode:
		printDebug(str("bodyEntered: ", bodyEntered, ", owner: ", bodyEntered.owner))
		emitDebugBubble(str("IN:", bodyEntered, "\n", bodyEntered.owner), Color.YELLOW)
	if not isEnabled or not shouldMonitorBodies or not shouldIncludeBody(bodyEntered): return
	self.onCollide(bodyEntered)
	didEnterBody.emit(bodyEntered)


## NOTE: This is NOT affected by [member isEnabled] but IS affected by [member shouldMonitorAreas]
func onAreaExited(areaExited: Area2D) -> void:
	if debugMode:
		printDebug(str("areaExited: ", areaExited, ", owner: ", areaExited.owner))
		emitDebugBubble(str("OUT:", areaExited, "\n", areaExited.owner), Color.ORANGE)
	if not shouldMonitorAreas or not shouldIncludeArea(areaExited): return
	self.onExit(areaExited)
	didExitArea.emit(areaExited)


## NOTE: This is NOT affected by [member isEnabled] but IS affected by [member shouldMonitorBodies]
func onBodyExited(bodyExited: Node2D) -> void:
	if debugMode:
		printDebug(str("bodyExited: ", bodyExited, ", owner: ", bodyExited.owner))
		emitDebugBubble(str("OUT:", bodyExited, "\n", bodyExited.owner), Color.ORANGE)
	if not shouldMonitorBodies or not shouldIncludeBody(bodyExited): return
	self.onExit(bodyExited)
	didExitBody.emit(bodyExited)

#endregion


#region Abstract Methods
# Cannot mark as `@abstract` because they're optional, and `@abstract` functions require the class itself to also be `@abstract`, but [AreaCollisionComponent] is not abstract as it may still be used via signals.

@warning_ignore_start("unused_parameter")

## Called when any [Area2D] or [PhysicsBody2D] or [TileMapLayer] comes into contact.
## NOTE: Called BEFORE [signal didEnterArea] or [signal didEnterBody] is emitted, to let subclasses such as [AreaContactComponent] to modify the state before signal handlers.
## Abstract; To be implemented by subclasses.
func onCollide(collidingNode: Node2D) -> void:
	pass


## Called when any [Area2D] or [PhysicsBody2D] or [TileMapLayer] leaves contact.
## NOTE: Called BEFORE [signal didExitArea] or [signal didExitBody] is emitted, to let subclasses such as [AreaContactComponent] to modify the state before signal handlers.
## Abstract; To be implemented by subclasses.
func onExit(exitingNode: Node2D) -> void:
	pass

#endregion
