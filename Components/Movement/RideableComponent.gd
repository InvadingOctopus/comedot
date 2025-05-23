## Allows the parent Entity to be "mounted" and "ridden" by another Entity, e.g. as a vehicle or horse etc. driven by the player character.
## For more basic "attachment" of any node to an Entity, see [AttachmentComponent].

class_name RideableComponent
extends Component

# TBD: Dismount on NOTIFICATION_PREDELETE?
# TBD: Rename to MountableComponent?


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

@export var riderPositionOffset: Vector2 = Vector2(0, -16)


@export_group("Control")

## The component types to toggle on the mount/vehicle and rider entities:
## On the mount: When mounted, the components are ENABLED. When dismounted, the components are DISABLED.
## On the rider: When mounted, the components are DISABLED. When the rider dismounts, the components are re-ENABLED.
## [method Entity.toggleComponents] is called to flip the `isEnabled` flag on each component if available, and pause the disabled components if [member shouldTogglePause].
## May be used to transfer player control to the vehicle/mount.
@export var componentTypesToToggle: Array[Script] = [PlatformerControlComponent, JumpControlComponent, ActionsComponent, ActionControlComponent]

## If `true` then [method Entity.toggleComponents] also pauses each component in [member componentTypesToToggle] when it is disabled.
@export var shouldTogglePause: bool = false

## An optional [InputEventAction] name to let the player manually dismount.
@export var dismountInputEventName: StringName = "":
	set(newValue):
		if newValue != dismountInputEventName:
			dismountInputEventName = newValue
			self.set_process_unhandled_input(isEnabled and not dismountInputEventName.is_empty())

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process_unhandled_input(isEnabled and not dismountInputEventName.is_empty())

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


func _unhandled_input(event: InputEvent) -> void:
	if self.isMounted and isEnabled and not dismountInputEventName.is_empty() and event.is_action(dismountInputEventName) and Input.is_action_just_pressed(dismountInputEventName): # Check conditions in the order of most-likely to change
		self.dismount()
		self.get_viewport().set_input_as_handled()

#endregion


#region Events

func _ready() -> void:
	Tools.connectSignal(self.didMount,    self.onSelf_didMount)
	Tools.connectSignal(self.didDismount, self.onSelf_didDismount)


func onSelf_didMount(newRider: Entity) -> void:
	if debugMode: printDebug(str("onSelf_didMount(): ", newRider, " componentsToToggle: ", componentTypesToToggle, ", shouldTogglePause: ", shouldTogglePause))
	
	if not isEnabled or componentTypesToToggle.is_empty(): return
	# Switch components from rider to mount
	newRider.toggleComponents(componentTypesToToggle, false, shouldTogglePause)
	self.parentEntity.toggleComponents(componentTypesToToggle, true, shouldTogglePause)


func onSelf_didDismount(previousRider: Entity) -> void:
	if debugMode: printDebug(str("onSelf_didDisount(): ", previousRider, " componentsToToggle: ", componentTypesToToggle, ", shouldTogglePause: ", shouldTogglePause))
	
	if not isEnabled or componentTypesToToggle.is_empty(): return
	# Switch components from mount back to previous rider
	self.parentEntity.toggleComponents(componentTypesToToggle, false, shouldTogglePause)
	previousRider.toggleComponents(componentTypesToToggle, true, shouldTogglePause)


func _physics_process(_delta: float) -> void: # TBD: _process() or _physics_process()?
	if not isEnabled or not rider: return
	# DESIGN: Set the attachee's position to this COMPONENT's position, NOT the mount/vehicle Entity's position,
	# so that there may be an additional constant offset if needed.
	rider.global_position = self.global_position + riderPositionOffset
	if is_instance_of(rider, CollisionObject2D):
		rider.reset_physics_interpolation() # CHECK: Is this necessary?


func unregisterEntity() -> void:
	self.dismount()
	super.unregisterEntity()


func _exit_tree() -> void:
	self.dismount()
	super._exit_tree()

#endregion
