## Pew Pew
## WARNING: This component relies on [method _unhandled_input] to process player input,
## in order to allow UI elements to receive input without firing the gun.
## If mouse input events are not reaching this component, check the [member Control.mouse_filter] property of any overlaying nodes, and set it to `MOUSE_FILTER_PASS` or `MOUSE_FILTER_IGNORE`.

class_name GunComponent
extends CooldownComponent

# TBD: Optional toggle for only [_unhandled_input] or accepting all [_input]

#region Parameters

## The [Entity] to instantiate a copy of when the Gun shoots.
@export var bulletEntity: PackedScene # TODO: Enforce `Entity` type

const ammoCost: int = -1 ## Should be a negative number, to allow for situations where ammo might increase when firing. ;)
@export var ammo: Stat

## If `true`, the gun fires automatically without any player input.
@export var autoFire := false

## If `true`, the button input has to be unpressed and pressed again for each bullet. If `false`, keep firing as long as the button input is pressed.
@export var pressAgainToShoot := false

## The position in relation to the Pivot where newly spawned bullets are placed.
@export var bulletEmissionLocation: Vector2:
	get:
		return %BulletEmissionLocation.position
	set(newValue):
		if %BulletEmissionLocation:
			%BulletEmissionLocation.position = newValue

@export var isEnabled := true

#endregion


#region Signals
signal didFire(bullet: Entity)
signal didDepleteAmmo ## Emited when [member ammo] goes below 1 after firing the gun.
signal ammoInsufficient ## Emited when attempt to fire the gun while [member ammo] is < 1
#endregion


#region State
var isFireActionPressed := false
var wasFireActionJustPressed := false
#region


func _unhandled_input(_event: InputEvent) -> void:
	# NOTE: Using [_unhandled_input] allows UI buttons etc. to trap mouse clicks
	# without causing the gun to fire, which looks janky.

	# ATTENTION: If mouse input events are not reaching this component,
	# check the [member Control.mouse_filter] property of any overlaying nodes,
	# and set it to `MOUSE_FILTER_PASS` or `MOUSE_FILTER_IGNORE`.

	if not isEnabled or autoFire: return

	wasFireActionJustPressed = Input.is_action_just_pressed(GlobalInput.Actions.fire)
	isFireActionPressed = Input.is_action_pressed(GlobalInput.Actions.fire)


func _process(_delta: float) -> void:
	# NOTE: Input actions are handled in [_unhandled_input]
	# to allow UI buttons etc. to handle mouse clicks,
	# because it looks janky if the gun fires when the player clicks on an unrelated UI button.

	if not isEnabled: return

	if autoFire and hasCooldownCompleted:
		fire()
	elif not pressAgainToShoot and isFireActionPressed:
		fire()
	elif pressAgainToShoot and wasFireActionJustPressed:
		fire()
		wasFireActionJustPressed = false


func fire(ignoreCooldown: bool = false) -> void:

	if not isEnabled: return
	if not hasCooldownCompleted and not ignoreCooldown: return

	if not bulletEntity:
		printWarning("No bulletEntity specified!")
		return

	# Create a new bullet, but we may not have enough ammo, in which case return.

	var newBullet: Entity = createNewBullet()
	if not newBullet: return

	# Do we have a faction? If so, copy the FactionComponent to the new bullet.

	var factionComponent: FactionComponent = self.getCoComponent(FactionComponent)

	if factionComponent:
		var factionComponentCopy: FactionComponent = factionComponent.duplicate()
		newBullet.add_child(factionComponentCopy)

	# Add the bullet to the scene
	self.parentEntity.get_parent().add_child(newBullet)
	newBullet.owner = newBullet.get_parent() # INFO: Necessary for persistence to a [PackedScene] for save/load.
	
	didFire.emit(newBullet)

	# Start the cooldown timer
	startCooldown()


func useAmmo() -> bool:

	# First, do we have enough ammo?

	if ammo.value <= 0:
		ammoInsufficient.emit()
		return false

	ammo.value += ammoCost

	# Did we just deplete the ammo with this shot?

	if ammo.previousValue > 0 and ammo.value <= 0:
		Debug.printDebug("ammo depleted")
		didDepleteAmmo.emit()
		parentEntity.displayLabel("AMMO DEPLETED")

	return true


## Decreases the [member ammo] [Stat] and creates a new [member bulletEntity] [Entity].
func createNewBullet() -> Entity:

	# First, do we have enough ammo?
	if not useAmmo(): return

	# Start forging a new bullet.

	# var bulletResource := load(bulletEntity.resource_path) # TBD
	var newBullet: Entity = bulletEntity.instantiate() as Entity

	if not newBullet:
		printError("Cannot instantiate a new bullet: " + str(bulletEntity.resource_path))
		return null

	newBullet.global_position = %BulletEmissionLocation.global_position
	newBullet.global_rotation = %BulletEmissionLocation.global_rotation
	newBullet.z_index   = %BulletEmissionLocation.z_index
	newBullet.top_level = %BulletEmissionLocation.top_level
	return newBullet
