## Represents a weapon which does not emit "bullets" or other projectiles, instead causes instant damage at a target position.
## Other components/scripts may be used to draw "fake" projectiles as a visual indicator of the weapon firing.
## IMPORTANT: This is NOT a standalone component; it must used with other components such as [DamageComponent] to represent the area of attack,
## and an [AimingCursorComponent] to control the targetting (or a [TetherComponent] + [PositionControlComponent]).
## Those components may be combined to make a specialized "GunEntity" etc.
## Requirements: [DamageComponent]. BEFORE [InputComponent]
## @experimental

class_name BulletlessGunComponent
extends CooldownComponent


#region Parameters

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			if not isEnabled: isFiring = false
			self.set_physics_process(isEnabled and is_instance_valid(targetingNode))

## The node to reposition the [DamageComponent] to on each frame.
## If unspecified, an [AimingCursorComponent] is used, if available.
@export var targetingNode: Node2D:
	set(newValue):
		if newValue != targetingNode:
			targetingNode = newValue
			self.set_physics_process(isEnabled and is_instance_valid(targetingNode))

## If `true` then [method fire] fails if [member DamageComponent.damageReceivingComponentsInContact] is empty.
@export var dontShootIfNoTargets: bool = false


@export_group("Ammo")
@export var ammo: Stat ## The [Stat] Resource to use as the ammo. If omitted, no ammo is required to fire the gun.
@export var ammoCost: int = 1 ## The ammo used when initating the firing and then per tick of the [member DamageRepeatingComponent.timer]. 0 == Unlimited ammo. NOTE: A negative number will INCREASE the ammo when firing.
@export var ammoDepletedMessage: String = "AMMO DEPLETED" ## The text to display as a [TextBubble] when the [member ammo] [Stat] reaches 0 AFTER firing.

#endregion


#region State
var isFiring: bool = false:
	set(newValue):
		if newValue != isFiring:
			if debugMode:
				Debug.printChange("isFiring", isFiring, newValue, self.debugModeTrace) # logAsTrace
				emitDebugBubble("isFiring" if newValue else "!isFiring", randomDebugColor, true) # emitFromEntity
			isFiring = newValue
			# UNUSED: damageComponent.isEnabled = self.isFiring # Don't disable Area2D events
			if isFiring and cooldownTimer.is_stopped() and not is_zero_approx(cooldownTimer.time_left):
				cooldownTimer.start()
#endregion


#region Signals
signal didFire(damageReceivingComponentsInContact: Array[DamageReceivingComponent])
signal didDepleteAmmo  ## Emitted when [member ammo] goes below 1 after firing the gun.
signal ammoInsufficient ## Emitted when attempt to fire the gun while [member ammo] is < 1
#endregion


#region Dependencies
@onready var damageComponent: DamageComponent = coComponents.DamageComponent # TBD: Include subclasses?
@onready var inputComponent:  InputComponent  = parentEntity.findFirstComponentSubclass(InputComponent)

func getRequiredComponents() -> Array[Script]:
	return [DamageComponent, InputComponent]
#endregion


func _ready() -> void:
	if not targetingNode:
		targetingNode = coComponents.AimingCursorComponent.get_node(^".") as Node2D
		if not targetingNode: printWarning("targetingNode not set!")

	self.isFiring = isEnabled and inputComponent.inputActionsPressed.has(GlobalInput.Actions.fire)

	# Apply setters because Godot doesn't on _ready()

	# UNUSED: damageComponent.isEnabled = self.isFiring # Don't disable Area2D events
	damageComponent.shouldDamageOnCollision = false # Damage only when isFiring

	if isFiring and cooldownTimer.is_stopped():
		cooldownTimer.start()

	self.set_physics_process(isEnabled and is_instance_valid(targetingNode))

	Tools.connectSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput)
	Tools.connectSignal(damageComponent.didCollideReceiver, self.onDamageComponent_didCollideReceiver)


#region Input

func onInputComponent_didProcessInput(event: InputEvent) -> void:
	if event.is_action(GlobalInput.Actions.fire):
		self.isFiring = isEnabled and event.is_action_pressed(GlobalInput.Actions.fire)
		if self.isFiring and not self.isOnCooldown: fire() # Fire when clicking.


func _physics_process(_delta: float) -> void:
	damageComponent.global_position = targetingNode.global_position
	damageComponent.reset_physics_interpolation() # CHECK: Necessary?

	if debugMode: targetingNode.modulate = Color.RED if isFiring else Color.GRAY

#endregion


#region Boom Boom

func onDamageComponent_didCollideReceiver(_damageReceivingComponent: DamageReceivingComponent) -> void:
	if not self.isEnabled or not self.isFiring or isOnCooldown: return
	fire()


func fire() -> bool:
	if isOnCooldown \
	or (dontShootIfNoTargets and damageComponent.damageReceivingComponentsInContact.is_empty()):
		return false

	if useAmmo():
		if debugMode: emitDebugBubble(str("HIT ", damageComponent.damageReceivingComponentsInContact.size()))
		damageComponent.causeDamageToAllReceivers()
		self.didFire.emit(damageComponent.damageReceivingComponentsInContact)
		self.startCooldown()
		return true
	else:
		if debugMode: emitDebugBubble("LOW AMMO", damageComponent.damageReceivingComponentsInContact.size())
		ammoInsufficient.emit()
		return false


## Deducts the [member ammoCost] from the [member ammo] [Stat].
## If no [member ammo] [Stat] Resource is specified, no ammo is needed and the result is always `true`.
## Returns `false` if [member ammo] is specified but there is not enough ammo.
func useAmmo() -> bool:
	# If no ammo resource is specified, no ammo is needed!
	if not self.ammoCost or not self.ammo: return true

	# Do we have enough ammo?

	if ammo.value < ammoCost:
		if debugMode: printDebug("Not enough ammo")
		ammoInsufficient.emit()
		return false

	ammo.value -= ammoCost

	# Did we just deplete the ammo with this shot?

	if ammo.previousValue > 0 and ammo.value <= 0:
		if debugMode: printDebug("ammo depleted")
		didDepleteAmmo.emit()
		if not self.ammoDepletedMessage.is_empty(): TextBubble.create(self.ammoDepletedMessage)

	return true


func finishCooldown() -> void:
	super.finishCooldown()
	if not self.isEnabled or not self.isFiring: return
	fire()
	if cooldownTimer.one_shot: cooldownTimer.start() # Keep firing

#endregion
