## Base class for components which depend on an [Area2D].
## The [Component] or its parent [Entity] ITSELF may BE an [Area2D] node, or a different [Area2D] that already exists may be specified.

class_name AreaManipulatingComponentBase
extends Component

# TBD: Better name? :')
# DESIGN: Do not connect signals here; specific signals should only be connected in specific subclasses when they are needed, to improve performance.


#region Parameters
## A specific [Area2D] to use. If unspecified, then this Component is used if it itself is an [Area2D] node, otherwise [member Entity.area] is used.
@export var areaOverride: Area2D

@export var isEnabled: bool = true: ## Also effects [member Area2D.monitorable] and [member Area2D.monitoring]
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			selfAsArea.monitorable = isEnabled
			# selfAsArea.monitoring  = isEnabled # Should be always disabled
#endregion


#region State
var area: Area2D ## The actual [Area2D] in use.

var selfAsArea: Area2D: # TBD: PERFORMANCE: Should this be set once in _ready()?
	get:
		if not selfAsArea: selfAsArea = self.get_node(^".") as Area2D
		return selfAsArea

var selfAscollisionObject: CollisionObject2D: # TBD: PERFORMANCE: Should this be set once in _ready()?
	get:
		if not selfAscollisionObject: selfAscollisionObject = self.get_node(^".") as CollisionObject2D
		return selfAscollisionObject
#endregion


#region Signals
signal didCollide ## Emitted when the [Area2D] monitored by this component collides with another [Area2D] or [PhysicsBody2D] or [TileMapLayer]
#endregion


func _enter_tree() -> void:
	self.area = self.areaOverride

	# DESIGN: A Component as Area2D should override the Entity as Area2D, because a Component is an explicit addition to an Entity.

	# If no override is specified, first, try using this Component itself as an Area2D
	if not self.area:
		if debugMode: printDebug(str("No areaOverride specified. Casting self as Area2D"))
		self.area = selfAsArea
	
	# If this Component is not an Area2D, try using the area specified on the Entity.
	if not self.area:
		self.area = parentEntity.getArea()
		if debugMode: printDebug(str("Cannot cast self as Area2D. parentEntity.getArea(): ", area))

	# Still nothing? :(
	if not self.area:
		printWarning("Missing area. Cannot cast self as Area2D and cannot get area from parent Entity: " + parentEntity.logFullName)


#region Signals

## Connects collision signals like [signal Area2D.area_entered] & [signal Area2D.body_entered] etc.
## NOTE: NOT called by the default/superclass implementation. Must be called manually by any class that `extends` [AreaManipulatingComponentBase]
func connectSignals() -> void:
	Tools.reconnectSignal(area.area_entered, onArea_areaEntered)
	Tools.reconnectSignal(area.body_entered, onArea_bodyEntered)


func onArea_areaEntered(areaEntered: Area2D) -> void:
	if debugMode: printDebug(str("areaEntered: ", areaEntered, ", owner: ", areaEntered.owner))
	if not isEnabled or areaEntered.owner == self or areaEntered.owner == self.parentEntity: return # Avoid running into ourselves
	didCollide.emit(areaEntered)
	self.onCollide(areaEntered)


func onArea_bodyEntered(bodyEntered: Node2D) -> void:
	if debugMode: printDebug(str("bodyEntered: ", bodyEntered, ", owner: ", bodyEntered.owner))
	if not isEnabled or bodyEntered.owner == self or bodyEntered.owner == self.parentEntity: return # Avoid running into ourselves
	didCollide.emit(bodyEntered)
	self.onCollide(bodyEntered)


## Abstract; Must be implemented by subclass.
@warning_ignore("unused_parameter")
func onCollide(collidingNode: Node2D) -> void:
	pass

#endregion

