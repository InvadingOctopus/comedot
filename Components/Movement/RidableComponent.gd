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
@export var isEnabled: bool = true
#endregion


#region State
var isMounted: bool:
	get: return is_instance_valid(rider)
#endregion


#region Signals
signal didMount(rider: Entity)
signal didUnmount(rider: Entity)
#endregion


func mount(newRider: Entity) -> bool:
	if self.isMounted:
		return false
	else: 
		self.rider = newRider
		return true


func unmount() -> bool:
	if self.isMounted:
		self.rider = null
		return true
	else:
		return false


func _physics_process(_delta: float) -> void: # TBD: _process() or _physics_process()?
	if not isEnabled or not rider: return
	# DESIGN: Set the attachee's position to this COMPONENT's position, NOT the Entity's position,
	# so that there may be an additional constant offset.
	rider.global_position = self.global_position + offset
	if is_instance_of(rider, CollisionObject2D):
		rider.reset_physics_interpolation() # CHECK: Is this necessary?
