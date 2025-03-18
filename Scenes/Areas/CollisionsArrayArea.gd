## An [Area2D] which keeps track of all the other [Area2D]s that are in contact with it.
## Only [Area2D]s with a [CollisionObject2D.collision_layer] that matches the [CollisionObject2D.collision_mask] of this area are added.
## NOTE: Does NOT detect [PhysicsBody2D]s such as [CharacterBody2D] etc.
## TIP: For an [Entity], use [AreaContactComponent].

class_name CollisionsArrayArea
extends Area2D

# TODO: Update to bring in line with [AreaContactComponent]
# TODO: Handle [PhysicsBody2D] collisions
# TBD: Allow an `areaOverride` as in [ZoneComponent]?
# TBD: Reduce code duplication between [AreaContactComponent]?


#region Parameters
## If `false`, no new areas are added.
## NOTE: Does NOT affect the removal of areas that exit contact with this area.
@export var isEnabled: bool = true
@export var debugMode: bool = false
#endregion


#region State
## A list of [Area2Ds]s currently in collision contact.
var areasInContact: Array[Area2D]
#endregion


#region Signals
#endregion


func _ready() -> void:
	connectSignals()
	readdAllAreas()


func connectSignals() -> void:
	self.area_entered.connect(self.onAreaEntered)
	self.area_exited.connect(self.onAreaExited)


#region Collisions

## Clears the [member areasInContact] array and re-adds all [Area2D]s that are currently in contact with the area of this area.
## Only [Area2D]s with a [CollisionObject2D.collision_layer] that matches the [CollisionObject2D.collision_mask] of this area are added.
## If not [member isEnabled], the list is cleared but no areas are added.
func readdAllAreas() -> void:
	# Clear the list but don't add new areas if not enabled.
	self.areasInContact.clear()
	if not isEnabled: return

	for overlappingArea in self.get_overlapping_areas():
		if debugMode: Debug.printDebug(str("Adding ", overlappingArea), self)
		self.areasInContact.append(overlappingArea)


func onAreaEntered(areaEntered: Area2D) -> void:
	# TBD: Make sure no area is added twice?
	if not isEnabled: return
	if debugMode: Debug.printDebug(str("Entered ", areaEntered), self)
	areasInContact.append(areaEntered)


func onAreaExited(areaExited: Area2D) -> void:
	# NOTE: This should NOT be affected by `isEnabled`; areas that exit should ALWAYS be removed!
	if debugMode: Debug.printDebug(str("Exited ", areaExited), self)
	areasInContact.erase(areaExited)

#endregion
