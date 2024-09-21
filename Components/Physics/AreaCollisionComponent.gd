## Keeps track of all [Area2D]s currently in collision with this component's area.
## Only [Area2D]s with a [CollisionObject2D.collision_layer] that matches the [CollisionObject2D.collision_mask] of this component are added.
## NOTE: Does NOT detect [PhysicsBody2D]s such as [CharacterBody2D] etc.
## Requirements: Component Node must be Area2D

class_name AreaCollisionComponent
extends AreaManipulatingComponentBase

# TBD: Handle [PhysicsBody2D] in this component or a separate component?
# TBD: Allow an `areaOverride` as in [ZoneComponent]?
# TBD: Use this as the base for DamageComponent, ZoneComponent, etc.?


#region Parameters
## If `false`, no new areas are added.
## NOTE: Does NOT affect the removal of areas that exit contact with this component.
@export var isEnabled: bool = true
#endregion


#region State
## A list of [Area2Ds]s currently in collision contact.
var areasInContact: Array[Area2D]
#endregion


#region Signals
signal didEnter(area: Area2D) ## This signal is also emitted for each [Area2D] already in contact with this component when this component is [method _ready].
signal didExit(area: Area2D)
#endregion


func _ready() -> void:
	connectSignals()
	readdAllAreas()


func connectSignals() -> void:
	area.area_entered.connect(self.onArea_areaEntered)
	area.area_exited.connect(self.onArea_areaExited)

#region Collisions

## Clears the [member areasInContact] array and re-adds all [Area2D]s that are currently in contact with the area of this component.
## Only [Area2D]s with a [CollisionObject2D.collision_layer] that matches the [CollisionObject2D.collision_mask] of this component are added.
## If not [member isEnabled], the list is cleared but no areas are added.
func readdAllAreas() -> void:
	# Clear the list but don't add new areas if not enabled.
	self.areasInContact.clear()
	if not isEnabled: return

	for overlappingArea in selfAsArea.get_overlapping_areas():
		self.areasInContact.append(overlappingArea)
		self.didEnter.emit(overlappingArea) # TBD: Should this be emitted here?


func onArea_areaEntered(areaEntered: Area2D) -> void:
	if not isEnabled: return
	# TBD: Make sure no area is added twice?
	areasInContact.append(areaEntered)
	didEnter.emit(areaEntered)


func onArea_areaExited(areaExited: Area2D) -> void:
	# NOTE: This should NOT be affected by `isEnabled`; areas that exit should ALWAYS be removed!
	areasInContact.erase(areaExited)
	didExit.emit(areaExited)

#endregion
