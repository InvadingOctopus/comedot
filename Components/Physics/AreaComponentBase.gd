## Base class for various components which depend on, monitor or manipulate an [Area2D].
## The monitored area may be this component's own node, the parent [Entity] node, or another area which may be shared between multiple components.
## This component only chooses and provides an [Area2D] property.
## TIP: To receive signals about collisions, use [AreaCollisionComponent].
## TIP: To maintain a list of all nodes in physical contact, use [AreaContactComponent].

class_name AreaComponentBase
extends Component

# TBD: Better name?
# TBD: Also support monitoring RigidBody2D?


#region Parameters
## A specific [Area2D] to use. If unspecified, then this Component's node is used if it itself is an [Area2D], otherwise this Component's parent [member Entity.area] is used.
@export var areaOverride: Area2D
#endregion


#region State

var area: Area2D ## The actual [Area2D] currently in use, which may be chosen automatically if [member areaOverride] is not valid.

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
	# DESIGN: A Component-as-Area2D should override the Entity-as-Area2D, because a Component is an explicit addition to an Entity.
	# Log before attempts, in case there are property getters/setters ahead

	if self.areaOverride: 
		if debugMode: printDebug(str("Using areaOverride: ", areaOverride))
		self.area = self.areaOverride

	# If no override is specified, first, try using this Component itself as an Area2D
	if not self.area:
		if debugMode: printDebug(str("No areaOverride. Casting self as Area2D"))
		self.area = selfAsArea
	
	# If this Component is not an Area2D, try using the area specified on the Entity.
	if not self.area:
		if debugMode: printDebug(str("Cannot cast self as Area2D. parentEntity.getArea(): ", area))
		self.area = parentEntity.getArea()

	# Still nothing? :(
	if not self.area:
		printWarning("Missing area. Cannot cast self as Area2D & cannot get area from parentEntity: " + parentEntity.logFullName)
	elif debugMode:
		printDebug(str("area parent: ", area.get_parent()))
