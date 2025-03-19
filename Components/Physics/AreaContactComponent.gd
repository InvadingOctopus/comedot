## Keeps a list of all the [Area2D]s, [PhysicsBody2D]s or [TileMapLayer]s that are currently in collision contact with this component's area.
## Only nodes with a [CollisionObject2D.collision_layer] that matches the [CollisionObject2D.collision_mask] of this component are added.
## TIP: PERFORMANCE: For a component that only emits signals but does not maintain an array of contacts, use [AreaCollisionComponent] to improve performance.

class_name AreaContactComponent
extends AreaCollisionComponent

# TBD: Add a list for [TileMapLayer]s?
# TBD: Use this as the base for DamageComponent etc.?
# TBD: Reduce code duplication between [CollisionsArrayArea]?

# DESIGN: Do not connect signals here; specific signals should only be connected in specific subclasses when they are needed, to improve performance.


#region Parameters

@export var shouldMonitorAreas:  bool = true # If `false` no [Area2D]s are added OR removed in [member areasInContact]
@export var shouldMonitorBodies: bool = true # If `false` no [PhysicsBody2D]s or [TileMapLayer]s are added OR removed in [member bodiesInContact]
#endregion


#region State
var areasInContact:  Array[Area2D] ## A list of [Area2D]s currently in collision contact.
var bodiesInContact: Array[Node2D] ## A list of [PhysicsBody2D]s OR [TileMapLayer]s currently in collision contact.
#endregion


func _ready() -> void:
	super._ready()
	# connectSignals() # TBD: PERFORMANCE: Should be opted-in by subclasses.
	readdAllContacts()


## Clears the [member areasInContact] & [member bodiesInContact] arrays and re-adds all [Area2D]s, [PhysicsBody2D]s or [TileMapLayer]s that are currently in contact with the [Area2D] of this component.
## Only [Area2D]s with a [CollisionObject2D.collision_layer] that matches the [CollisionObject2D.collision_mask] of this component are added.
## If not [member isEnabled], the list is cleared but no areas are added. Affected by [member shouldMonitorAreas] and [member shouldMonitorBodies].
## NOTE: The [signal didEnterArea] and [signal didEnterBody] signals are emitted here to allow other scripts to react to any existing physical contact.
func readdAllContacts() -> void:
	# NOTE: Clear the list but don't add new areas/bodies if not enabled.
	# Because that seems like it would be the expected behavior.
	self.areasInContact.clear()
	self.bodiesInContact.clear()
	if not isEnabled: return

	if shouldMonitorAreas:
		for overlappingArea in selfAsArea.get_overlapping_areas():
			self.areasInContact.append(overlappingArea)
			# TBD: Also call self.onCollide()?
			self.didEnterArea.emit(overlappingArea)

	if shouldMonitorBodies:
		for overlappingBody in selfAsArea.get_overlapping_bodies():
			self.bodiesInContact.append(overlappingBody)
			# TBD: Also call self.onExit()?
			self.didEnterBody.emit(overlappingBody)


#region Events

## Called when any [Area2D] or [PhysicsBody2D] or [TileMapLayer] comes into contact, and adds the colliding node to [member areasInContact] or [member bodiesInContact].
## NOTE: Does NOT add new nodes if not [member isEnabled]
func onCollide(collidingNode: Node2D) -> void:
	if not isEnabled: return
	# TBD: Prevent duplicates? or is that done implicitly anyway via the order of enter/exit signals?
	if   collidingNode is Area2D: areasInContact.append(collidingNode)
	elif collidingNode is PhysicsBody2D or TileMapLayer: bodiesInContact.append(collidingNode)


## Called when any [Area2D] or [PhysicsBody2D] or [TileMapLayer] leaves contact, and removes the departing node from [member areasInContact] or [member bodiesInContact].
## NOTE: Removal is NOT affected by [member isEnabled] to ensure expected behavior.
func onExit(exitingNode: Node2D) -> void:
	if   exitingNode is Area2D: areasInContact.erase(exitingNode)
	elif exitingNode is PhysicsBody2D or TileMapLayer: bodiesInContact.erase(exitingNode)

#endregion


#region DEBUG

# func _physics_process(_delta: float) -> void:
# 	showDebugInfo()


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList[str("\n —", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.areasInContact  = self.areasInContact
	Debug.watchList.bodiesInContact = self.bodiesInContact

#endregion