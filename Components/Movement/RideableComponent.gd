## Allows the parent Entity to be "mounted" and "ridden" by another Entity, e.g. as a vehicle or horse etc. driven by the player character.
## Uses a [RemoteTransform2D] child node to attach the rider. Enable "Editable Children" and reposition the [RemoteTransform2D] in the Editor to set the offset of the rider's node in relation to this component.
## For more basic "attachment" of any node to an Entity, see [AttachmentComponent].

class_name RideableComponent
extends Component

# NOTE: The component node has to be a [Node2D] to have a position and reposition child nodes etc.
# TBD: Dismount on NOTIFICATION_PREDELETE?
# TBD: Rename to MountableComponent?


#region State

@export var rider: Entity:
	set(newValue):
		if newValue != rider:
			if debugMode: Debug.printChange("rider", rider, newValue)
			var previousRider: Entity = rider if rider is Entity else null
			rider = newValue # Set the new rider before the dismount signal, so handlers can see who it is now.
			if previousRider and previousRider != rider:
				didDismount.emit(previousRider)
			if rider is Entity:
				didMount.emit(rider)
			setInternalState()

@export var riderPositionOffset: Vector2 = Vector2(0, -16)


@export_group("Control")

## The component types to temporarily DISABLE on the "rider" entities when the "mount" is mounted.
## When unmounting, the components are re-enabled on the rider.
## [method Entity.toggleComponents] is called to flip the `isEnabled` flag on each component if available, and pause the disabled components if [member shouldTogglePause].
## TIP: Use this to transfer player control from the main character to a vehicle/mount.
## TIP: Do not disable [InputComponent] on the rider, as that is required for [GunComponent] etc. Instead, disable [PlatformerPhysicsComponent] & [JumpComponent] etc.
@export var componentsToDisableOnRider: Array[Script] = [JumpComponent, ActionsComponent, ActionControlComponent, PlatformerPhysicsComponent]

## The component types to temporarily ENABLE on this "mount/vehicle" entity when mounted.
## When unmounting, the components are disabled on the mount.
## [method Entity.toggleComponents] is called to flip the `isEnabled` flag on each component if available, and pause the disabled components if [member shouldTogglePause].
## TIP: Use this to temporarily transfer player control from the main character to a vehicle/mount.
@export var componentsToEnableOnMount:  Array[Script] = [JumpComponent, ActionsComponent, ActionControlComponent, InputComponent]


## If `true` then [method Entity.toggleComponents] also pauses each component in [member componentsToDisableOnRider] & [member componentsToEnableOnMount] when it is disabled.
@export var shouldTogglePause: bool = false

## An optional [InputEventAction] name to let the player manually dismount.
@export var dismountInputEventName: StringName = "":
	set(newValue):
		if newValue != dismountInputEventName:
			dismountInputEventName = newValue
			self.set_process_unhandled_input(not dismountInputEventName.is_empty() and rider and isEnabled) # setInternalState() not needed because this flag only affects input.

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			setInternalState()

#endregion


#region State

@onready var riderPlaceholder: RemoteTransform2D = $RiderPlaceholder

var isMounted: bool:
	get: return is_instance_valid(rider)

# Sprite2D or AnimatedSprite2D
var mountSprite: Node2D
var riderSprite: Node2D

#endregion


#region Signals
signal didMount(newRider: Entity)
signal didDismount(previousRider: Entity)
#endregion


#region Interface

## Returns `true` if there is no current rider and the [param newRider] has been set as the [member rider] of this component.
func mount(newRider: Entity) -> bool:
	if self.isMounted:
		return false
	else:
		self.rider = newRider # Signal will be emitted by property setter
		return true


## Returns `true` if there is a valid current [member rider] and is successfully removed.
func dismount() -> bool:
	if self.isMounted:
		self.rider = null # Signal will be emitted by property setter
		return true
	else:
		return false


func _unhandled_input(event: InputEvent) -> void:
	if self.isMounted and isEnabled \
	and not dismountInputEventName.is_empty() \
	and event.is_action(dismountInputEventName) and Input.is_action_just_pressed(dismountInputEventName): # Check conditions in the order of most-likely to change
		self.dismount()
		self.get_viewport().set_input_as_handled()


## Copies the [member Sprite2D.flip_h] of this mount Entity's [Sprite2D] or [AnimatedSprite2D] to the rider Entity's sprite.
## Returns the [member Sprite2D.flip_h] of the mount sprite, if any.
func syncSpriteFlip() -> bool:
	# TODO: A better global/generic/shared way to sync the flip of 2 sprites
	if self.mountSprite and self.riderSprite:
		riderSprite.flip_h = mountSprite.flip_h
	return mountSprite.flip_h if mountSprite else false

#endregion


#region Events

func _ready() -> void:
	# Cache a reference to our sprite to synchronize the flip direction between mount and rider.
	self.parentEntity.getSprite()
	self.mountSprite = parentEntity.sprite

	Tools.connectSignal(self.didMount,    self.onSelf_didMount)
	Tools.connectSignal(self.didDismount, self.onSelf_didDismount)
	setInternalState() # Apply setters because Godot doesn't on initialization


func setInternalState() -> void:
	# PERFORMANCE: Set once instead of every frame
	# UNUSED: self.set_physics_process(isEnabled and rider) # Not needed with RemoteTransform2D
	self.set_process_unhandled_input(not dismountInputEventName.is_empty() and rider and isEnabled) # Flags that will change rarely checked last
	# TBD: Is there any point to setting RemoteTransform2D flags instead of just the `remote_path`?
	riderPlaceholder.update_position = isEnabled and rider
	riderPlaceholder.update_rotation = isEnabled and rider
	if is_instance_valid(rider): riderPlaceholder.remote_path = riderPlaceholder.get_path_to(rider) # CHECK: Does RemoteTransform2D only accept a relative path?
	else: riderPlaceholder.remote_path = ^""


func onSelf_didMount(newRider: Entity) -> void:
	if debugMode: printDebug(str("onSelf_didMount(): ", newRider, ", shouldTogglePause on components: ", shouldTogglePause))

	if not isEnabled: return

	# Sync sprite directions
	newRider.getSprite()
	if newRider.sprite:
		self.riderSprite = newRider.sprite
		syncSpriteFlip()
		if self.coComponents.InputComponent:
			Tools.connectSignal(self.coComponents.InputComponent.didChangeHorizontalDirection, self.onInputComponent_didChangeHorizontalDirection)

	# Toggle components on rider & mount
	if not componentsToDisableOnRider.is_empty():
		if debugMode: printDebug(str("componentsToDisableOnRider: ", componentsToDisableOnRider))
		newRider.toggleComponents(componentsToDisableOnRider,   false, shouldTogglePause)
	if not componentsToEnableOnMount.is_empty():
		if debugMode: printDebug(str("componentsToEnableOnMount: ", componentsToEnableOnMount))
		parentEntity.toggleComponents(componentsToEnableOnMount, true, shouldTogglePause)


func onSelf_didDismount(previousRider: Entity) -> void:
	# NOTE: Removals/cleanup should NOT depend on isEnabled
	if debugMode: printDebug(str("onSelf_didDisount(): ", previousRider, ", shouldTogglePause on components: ", shouldTogglePause))

	# Disconnect sprite flips
	self.riderSprite = null
	if self.coComponents.InputComponent:
		Tools.disconnectSignal(self.coComponents.InputComponent.didChangeHorizontalDirection, self.onInputComponent_didChangeHorizontalDirection)

	# Toggle components on rider & mount
	if not componentsToDisableOnRider.is_empty():
		if debugMode: printDebug(str("Enabling componentsToDisableOnRider: ", componentsToDisableOnRider))
		previousRider.toggleComponents(componentsToDisableOnRider, true, shouldTogglePause) # Re-enable
	if not componentsToEnableOnMount.is_empty():
		if debugMode: printDebug(str("Disabling componentsToEnableOnMount: ", componentsToEnableOnMount))
		parentEntity.toggleComponents(componentsToEnableOnMount,  false, shouldTogglePause) # Disable


func onInputComponent_didChangeHorizontalDirection() -> void:
	# PERFORMANCE: Do it directly instead of calling syncSpriteFlip()
	if self.mountSprite and self.riderSprite:
		riderSprite.flip_h = mountSprite.flip_h


func unregisterEntity() -> void:
	self.dismount()
	super.unregisterEntity()


func _exit_tree() -> void:
	self.dismount()
	super._exit_tree()


# UNUSED: The [RemoteTransform2D] does all the work.
# func _physics_process(_delta: float) -> void: # TBD: _process() or _physics_process()?
# 	# DESIGN: Set the attachee's position to this COMPONENT's position, NOT the mount/vehicle Entity's position,
# 	# so that there may be an additional constant offset if needed.
# 	rider.global_position = self.global_position + riderPositionOffset
# 	if is_instance_of(rider, CollisionObject2D):
# 		rider.reset_physics_interpolation() # CHECK: Is this necessary?

#endregion
