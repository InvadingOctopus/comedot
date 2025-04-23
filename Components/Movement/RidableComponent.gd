## Allows the parent Entity to be "mounted" and ridden by another Entity, such as a vehicle or horse etc. driven by the player character.
## For more basic "attachment" of any node to an Entity, see [AttachmentComponent].

class_name RidableComponent
extends Component


#region State

@export var rider: Entity:
	set(newValue):
		if newValue != rider:
			var previousRider: Entity = rider if rider is Entity else null
			rider = newValue # Set the new rider before the unmount signal, so handlers can see who it is now.
			if previousRider and previousRider != rider:
				didUnmount.emit(previousRider)
			if rider is Entity:
				didMount.emit(rider)

@export var offset: Vector2

## The list of component types to transfer from a new rider Entity to this component's vehicle/mount Entity, e.g. to hand over player control.
## When a rider unmounts, the components are transferred back.
@export var componentTypesToTransfer: Array[Script] = [PlatformerControlComponent, JumpControlComponent, ActionsComponent, ActionControlComponent]

@export var isEnabled: bool = true
#endregion


#region State
var isMounted: bool:
	get: return is_instance_valid(rider)
#endregion


#region Signals
signal didMount(newRider: Entity)
signal didUnmount(previousRider: Entity)
#endregion


#region Interface

func mount(newRider: Entity) -> bool:
	if self.isMounted:
		return false
	else: 
		self.rider = newRider # Signal will be emitted by property setter
		return true


func unmount() -> bool:
	if self.isMounted:
		self.rider = null # Signal will be emitted by property setter
		return true
	else:
		return false

#endregion


#region Events

func _ready() -> void:
	Tools.connectSignal(self.didMount, self.onSelf_didMount)
	Tools.connectSignal(self.didUnmount, self.onSelf_didUnmount)


func onSelf_didMount(newRider: Entity) -> void:
	if not isEnabled or componentTypesToTransfer.is_empty(): return	
	newRider.transferComponents(componentTypesToTransfer, self.parentEntity) # Move components from rider to mount


func onSelf_didUnmount(previousRider: Entity) -> void:
	if not isEnabled or componentTypesToTransfer.is_empty(): return
	self.parentEntity.transferComponents(componentTypesToTransfer, previousRider) # Move components from mount back to previous rider


func _physics_process(_delta: float) -> void: # TBD: _process() or _physics_process()?
	if not isEnabled or not rider: return
	# DESIGN: Set the attachee's position to this COMPONENT's position, NOT the Entity's position,
	# so that there may be an additional constant offset.
	rider.global_position = self.global_position + offset
	if is_instance_of(rider, CollisionObject2D):
		rider.reset_physics_interpolation() # CHECK: Is this necessary?

#endregion