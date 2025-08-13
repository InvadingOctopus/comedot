## Represents a weapon which does not emit "bullets" or other projectiles, instead causes instant damage at a target position.
## Other components/scripts may be used to draw "fake" projectiles as a visual indicator of the weapon firing.
## IMPORTANT: This is NOT a standalone component; it must used with other components such as [DamageComponent] to represent the area of attack,
## a [DamageRepeatingComponent] to toggle the [DamageComponent] on & off, 
## and an [AimingCursorComponent] to control the targetting (or a [TetherComponent] + [PositionControlComponent]).
## Those components may be combined to make a specialized "GunEntity" etc.
## Requirements: [DamageComponent], [DamageRepeatingComponent], BEFORE [InputComponent]
## @experimental

class_name BulletlessGunComponent
extends Component


#region Parameters

## The node to reposition the [DamageComponent] to on each frame.
## If unspecified, an [AimingCursorComponent] is used, if available.
@export var targetingNode: Node2D:
	set(newValue):
		if newValue != targetingNode:
			targetingNode = newValue
			self.set_physics_process(isEnabled and is_instance_valid(targetingNode))

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			if not isEnabled: isFiring = false
			self.set_physics_process(isEnabled and is_instance_valid(targetingNode))

@export_group("Ammo")

@export var ammo: Stat ## The [Stat] Resource to use as the ammo. If omitted, no ammo is required to fire the gun.
@export var ammoCostPerTick: int = 1 ## The ammo used when initating the firing and then per tick of the [member DamageRepeatingComponent.timer]. 0 == Unlimited ammo. NOTE: A negative number will INCREASE the ammo when firing.
@export var ammoDepletedMessage: String = "AMMO DEPLETED" ## The text to display via the Entity's [LabelComponent] when the [member ammo] [Stat] reaches 0 after firing.

#endregion


#region State

var isFiring: bool = false:
	set(newValue):
		if newValue != isFiring:
			if debugMode:
				Debug.printChange("isFiring", isFiring, newValue, self.debugModeTrace) # logAsTrace
				emitDebugBubble("isFiring" if newValue else "!isFiring", randomDebugColor, true) # emitFromEntity
			isFiring = newValue
			damageComponent.isEnabled = self.isFiring
			if isFiring: damageRepeatingComponent.timer.start()
			else: damageRepeatingComponent.timer.stop()

var secondElapsed: float = 0 # TBD @export_storage?

#endregion


#region Dependencies
@onready var inputComponent:  InputComponent  = parentEntity.findFirstComponentSubclass(InputComponent)
@onready var damageComponent: DamageComponent = coComponents.DamageComponent
@onready var damageRepeatingComponent: DamageRepeatingComponent = coComponents.DamageRepeatingComponent

func getRequiredComponents() -> Array[Script]:
	return [DamageComponent, DamageRepeatingComponent, InputComponent]
#endregion


func _ready() -> void:
	if not targetingNode:
		targetingNode = coComponents.AimingCursorComponent.get_node(^".") as Node2D
		if not targetingNode: printWarning("targetingNode not set!")

	self.isFiring = isEnabled and inputComponent.inputActionsPressed.has(GlobalInput.Actions.fire)

	# Apply setters because Godot doesn't on _ready()

	damageComponent.isEnabled = self.isFiring

	if isFiring: damageRepeatingComponent.timer.start()
	else: damageRepeatingComponent.timer.stop()

	self.set_physics_process(isEnabled and is_instance_valid(targetingNode))

	Tools.connectSignal(inputComponent.didProcessInput,   self.onInputComponent_didProcessInput)
	Tools.connectSignal(damageRepeatingComponent.didTick, self.onDamageRepeatingComponent_didTick)


func onInputComponent_didProcessInput(event: InputEvent) -> void:
	if event.is_action(GlobalInput.Actions.fire):
		self.isFiring = isEnabled and event.is_action_pressed(GlobalInput.Actions.fire)


func _physics_process(_delta: float) -> void:
	damageComponent.global_position = targetingNode.global_position
	damageComponent.reset_physics_interpolation() # CHECK: Necessary?

	if debugMode: targetingNode.modulate = Color.RED if isFiring else Color.GRAY


func onDamageRepeatingComponent_didTick(_damageReceivingComponentsInContact: Array[DamageReceivingComponent]) -> void:
	# The number of hurt boxes in contact does not matter
	if not self.isFiring: return

	if ammo and not is_zero_approx(ammoCostPerTick):
		ammo.value -= ammoCostPerTick
