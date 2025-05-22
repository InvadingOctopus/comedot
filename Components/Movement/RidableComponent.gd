## Allows the parent Entity to be "mounted" and ridden by another Entity, such as a vehicle or horse etc. driven by the player character.
## For more basic "attachment" of any node to an Entity, see [AttachmentComponent].

class_name RidableComponent
extends Component

# TBD: Dismount on NOTIFICATION_PREDELETE?


#region State

@export var rider: Entity:
	set(newValue):
		if newValue != rider:
			var previousRider: Entity = rider if rider is Entity else null
			rider = newValue # Set the new rider before the dismount signal, so handlers can see who it is now.
			if previousRider and previousRider != rider:
				didDismount.emit(previousRider)
			if rider is Entity:
				didMount.emit(rider)

@export var offset: Vector2

## The list of component types to toggle on the new rider Entity and this component's vehicle/mount Entity. When a rider dismounts, the components are toggled back.
## [method Entity.toggleComponents] is called to flip the `isEnabled` flag found on most components, and their
## May be used to hand over player control to a vehicle/mount.
@export var componentTypesToToggle: Array[Script] = [PlatformerControlComponent, JumpControlComponent, ActionsComponent, ActionControlComponent]

@export var isEnabled: bool = true
#endregion


#region State
var isMounted: bool:
	get: return is_instance_valid(rider)
#endregion


#region Signals
signal didMount(newRider: Entity)
signal didDismount(previousRider: Entity)
#endregion


#region Interface

func mount(newRider: Entity) -> bool:
	if self.isMounted:
		return false
	else:
		self.rider = newRider # Signal will be emitted by property setter
		return true


func dismount() -> bool:
	if self.isMounted:
		self.rider = null # Signal will be emitted by property setter
		return true
	else:
		return false

#endregion


#region Events

func _ready() -> void:
	Tools.connectSignal(self.didMount,    self.onSelf_didMount)
	Tools.connectSignal(self.didDismount, self.onSelf_didDismount)


func onSelf_didMount(newRider: Entity) -> void:
	if debugMode: printDebug(str("onSelf_didMount(): ", newRider, " componentsToToggle: ", componentTypesToToggle))
	
	if not isEnabled or componentTypesToToggle.is_empty(): return
	# Switch components from rider to mount
	newRider.toggleComponents(componentTypesToToggle, false)
	self.parentEntity.toggleComponents(componentTypesToToggle, true)


func onSelf_didDismount(previousRider: Entity) -> void:
	if debugMode: printDebug(str("onSelf_didDisount(): ", previousRider, " componentsToToggle: ", componentTypesToToggle))
	
	if not isEnabled or componentTypesToToggle.is_empty(): return
	# Switch components from mount back to previous rider
	self.parentEntity.toggleComponents(componentTypesToToggle, false)
	previousRider.toggleComponents(componentTypesToToggle, true)


func _physics_process(_delta: float) -> void: # TBD: _process() or _physics_process()?
	if not isEnabled or not rider: return
	# DESIGN: Set the attachee's position to this COMPONENT's position, NOT the Entity's position,
	# so that there may be an additional constant offset.
	rider.global_position = self.global_position + offset
	if is_instance_of(rider, CollisionObject2D):
		rider.reset_physics_interpolation() # CHECK: Is this necessary?


func unregisterEntity() -> void:
	self.dismount()
	super.unregisterEntity()


func _exit_tree() -> void:
	self.dismount()
	super._exit_tree()

#endregion
