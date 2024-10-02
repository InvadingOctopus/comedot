## Pew Pew
## WARNING: This component relies on [method _unhandled_input] to process player input,
## in order to allow UI elements to receive input without firing the gun.
## If mouse input events are not reaching this component, check the [member Control.mouse_filter] property of any overlaying nodes, and set it to `MOUSE_FILTER_PASS` or `MOUSE_FILTER_IGNORE`.
## TIP: For aiming, use [NodeFacingComponent] or [MouseRotationComponent].

class_name GunComponent
extends CooldownComponent

# TBD: Optional toggle for only `_unhandled_input()` or accepting all `_input()`?


#region Parameters

## The [Entity] to instantiate a copy of when the Gun shoots.
@export var bulletEntity: PackedScene # TODO: Enforce `Entity` type

@export var ammo:Stat
@export var ammoCost: int = 1 ## The ammo used per shot. A negative number will INCREASE the ammo when firing.

## If `true`, the gun fires automatically without any player input.
@export var autoFire: bool = false

## If `true`, the button input has to be unpressed and pressed again for each bullet. If `false`, keep firing as long as the button input is pressed.
@export var pressAgainToShoot: bool = false

## The position in relation to the Pivot where newly spawned bullets are placed.
@export var bulletEmissionLocation: Vector2:
	get: return %BulletEmissionLocation.position
	set(newValue):
		if %BulletEmissionLocation:
			%BulletEmissionLocation.position = newValue

## The text to display via the Entity's [LabelComponent] when the [member ammo] [Stat] reaches 0 after firing.
@export var ammoDepletedMessage: String = "AMMO DEPLETED"

@export var isEnabled: bool = true

#endregion


#region Signals
signal didFire(bullet: Entity)
signal didDepleteAmmo   ## Emitted when [member ammo] goes below 1 after firing the gun.
signal ammoInsufficient ## Emitted when attempt to fire the gun while [member ammo] is < 1
#endregion


#region State
var isFireActionPressed: bool = false
var wasFireActionJustPressed: bool = false
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


## Returns the bullet that was fired.
func fire(ignoreCooldown: bool = false) -> Entity:
	if not isEnabled: return null
	if not hasCooldownCompleted and not ignoreCooldown: return null

	if not bulletEntity:
		printWarning("No bulletEntity specified!")
		return null

	# Create a new bullet, but it may fail if there is not enough ammo or any other errors.
	var newBullet: Entity = createNewBullet()
	if not newBullet: return null

	# Add the bullet to the scene
	self.parentEntity.get_parent().add_child(newBullet, true) # force_readable_name
	newBullet.owner = newBullet.get_parent() # INFO: Necessary for persistence to a [PackedScene] for save/load.

	didFire.emit(newBullet)
	startCooldown() # Start the cooldown Timer

	return newBullet


## Deducts the [member ammoCost] from the [member ammo] [Stat].
## Returns `false` if there is not enough ammo.
func useAmmo() -> bool:
	# First, do we have enough ammo?

	if ammo.value < ammoCost:
		printDebug("Not enough ammo")
		ammoInsufficient.emit()
		return false

	ammo.value -= ammoCost

	# Did we just deplete the ammo with this shot?

	if ammo.previousValue > 0 and ammo.value <= 0:
		printDebug("ammo depleted")
		didDepleteAmmo.emit()
		if not self.ammoDepletedMessage.is_empty(): parentEntity.displayLabel(self.ammoDepletedMessage)

	return true


## Decreases the [member ammo] [Stat] and creates a new [member bulletEntity] [Entity].
func createNewBullet() -> Entity:
	printDebug("createNewBullet()")

	# First, do we have enough ammo?
	if not useAmmo(): return

	# Start forging a new bullet.

	# var bulletResource := load(bulletEntity.resource_path) # TBD
	var newBullet: Entity = bulletEntity.instantiate() as Entity

	if not newBullet:
		printError("Cannot instantiate a new bullet: " + str(bulletEntity.resource_path))
		return null

	newBullet.global_position	= %BulletEmissionLocation.global_position
	newBullet.global_rotation	= %BulletEmissionLocation.global_rotation
	newBullet.z_index			= %BulletEmissionLocation.z_index
	newBullet.top_level			= %BulletEmissionLocation.top_level

	newBullet.isLoggingEnabled	= self.shouldShowDebugInfo
	newBullet.shouldShowDebugInfo = self.shouldShowDebugInfo
	
	# Does this gun's firing entity have a faction? If so, copy the FactionComponent to the new bullet.
	# TBD:
	
	var factionComponent: FactionComponent = self.coComponents.FactionComponent

	if factionComponent:
		printDebug(str("Copying factionComponent to newBullet: ", factionComponent))
		var factionComponentCopy: FactionComponent = factionComponent.duplicate()
		newBullet.add_child(factionComponentCopy, true) # force_readable_name
	
	return newBullet
