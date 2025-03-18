## Base class for various components which depend on, monitor or manipulate an [Area2D].
## This [Component] script's node or its parent [Entity] ITSELF may BE an [Area2D] node, or a different [Area2D] that already exists may be specified.

class_name AreaComponentBase
extends Component

# TBD: Better name? :')


#region Parameters
## A specific [Area2D] to use. If unspecified, then this Component is used if it itself is an [Area2D] node, otherwise the Component's parent [member Entity.area] is used.
@export var areaOverride: Area2D
#endregion


#region State
var area: Area2D ## The actual [Area2D] currently in use.

var selfAsArea: Area2D: # TBD: PERFORMANCE: Should this be set once in _ready()?
	get:
		if not selfAsArea: selfAsArea = self.get_node(^".") as Area2D
		return selfAsArea

var selfAscollisionObject: CollisionObject2D: # TBD: PERFORMANCE: Should this be set once in _ready()?
	get:
		if not selfAscollisionObject: selfAscollisionObject = self.get_node(^".") as CollisionObject2D
		return selfAscollisionObject
#endregion


func _enter_tree() -> void:
	# DESIGN: A Component as Area2D should override the Entity as Area2D, because a Component is an explicit addition to an Entity.
	self.area = self.areaOverride

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
		printWarning("Missing area. Cannot cast self as Area2D and cannot get area from parentEntity: " + parentEntity.logFullName)
