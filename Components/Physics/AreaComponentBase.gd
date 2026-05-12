## Base class for various components which depend on, monitor or manipulate an [Area2D].
## The monitored area may be this component's own node, the parent [Entity] node, or another area which may be shared between multiple components.
## This component only chooses and provides an [Area2D] property.
## TIP: To receive signals about collisions, use [AreaCollisionComponent].
## TIP: To maintain a list of all nodes in physical contact, use [AreaContactComponent].

@abstract class_name AreaComponentBase
extends Component

# TBD: Better name?
# TBD: Also support monitoring RigidBody2D?


#region Parameters
## A specific [Area2D] to use. If unspecified, then this Component's node is used if it itself is an [Area2D], otherwise this Component's parent [member Entity.area] is used.
@export var areaOverride: Area2D
#endregion


#region State

@export_storage var area: Area2D ## The actual [Area2D] currently in use, which may be chosen automatically if [member areaOverride] is not valid.

var selfAsArea: Area2D ## This [Component]'s node as an [Area2D] for static typing and autocompletion etc.

var selfAscollisionObject: CollisionObject2D: # TBD: PERFORMANCE: Should this be set once in _ready()?
	get:
		if not selfAscollisionObject: selfAscollisionObject = self.get_node(^".") as CollisionObject2D
		return selfAscollisionObject

#endregion


#region Derived Properties

## The combined rectangular bounds of ALL of the [Area2D]'s [CollisionShape2D]s.
## NOTE: The vertices are in LOCAL coordinates. Use [member areaBoundsGlobal] for the GLOBAL coordinates.
## IMPORTANT: Call [member updateAreaBounds] to update this property if the area's shape changes during runtime.
var areaBounds: Rect2: # TBD: A more descriptive name like "areaShapeBounds"?
	get:
		# NOTE: FIXED: Use a separate flag to avoid an `if not` check, which would cause recursive calls to updateAreaBounds() if the area is 0
		if not didCacheAreaBounds: areaBounds = self.updateAreaBounds()
		return areaBounds

var areaBoundsGlobal: Rect2:
	get: return area.global_transform * areaBounds.abs() # Apply all transforms # TBD: PERFORMANCE: Use CollisionTools.getAllShapeGlobalBounds()?

var didCacheAreaBounds:	bool

#endregion


func _enter_tree() -> void:
	super._enter_tree()
	
	# DESIGN: A Component-as-Area2D should override the Entity-as-Area2D, because a Component is an explicit addition to an Entity.
	# Log before attempts, in case there are property getters/setters ahead
	
	selfAsArea = self.get_node(^".") as Area2D

	if self.areaOverride:
		if debugMode: printDebug(str("Using areaOverride: ", areaOverride))
		self.area = self.areaOverride

	# If no override is specified, first, try using this Component itself as an Area2D
	if not self.area:
		if debugMode: printDebug(str("No areaOverride. Casting self as Area2D"))
		self.area = selfAsArea

	# If this Component is not an Area2D, try using the area specified on the Entity.
	if not self.area:
		if debugMode: printDebug(str("Cannot cast self as Area2D. entity.getArea(): ", area))
		self.area = entity.getArea()

	# Still nothing? :(
	if not self.area: printWarning("Missing area. Cannot cast self as Area2D & cannot get area from entity: " + entity.logFullName)
	elif debugMode:   printDebug(str("area parent: ", area.get_parent()))


## Updates [member areaBounds] and returns the rectangular bounds of ALL of the [Area2D]'s [CollisionShape2D]s.
func updateAreaBounds() -> Rect2:
	areaBounds = CollisionTools.getAllShapeBounds(area)
	didCacheAreaBounds = true # Avoid recursion if area is 0
	return areaBounds
