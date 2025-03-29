## Pew Pew
## ALERT: This component relies on [method _unhandled_input] to process player input,
## in order to allow UI elements to receive input without firing the gun.
## If mouse input events are not reaching this component, check the [member Control.mouse_filter] property of any overlaying nodes, and set it to `MOUSE_FILTER_PASS` or `MOUSE_FILTER_IGNORE`.
## NOTE: Enable "Editable Children" to access the gun sprite & bullet emission position.
## The `$GunSprite` is a separate child node so that the [GunComponent] node can serve as a pivot for rotation etc.
## TIP: For aiming, use [MouseRotationComponent] or [NodeFacingComponent].
## TIP: To hide the internal sprite, enable "Editable Children" and set the visibility, e.g. to use the player's own sprite.

class_name GunComponent
extends CooldownComponent

# NOTE: The .tscn Scene file cannot inherit from CooldownComponent because CooldownComponent is a Node, but GunComponent needs to be a Node2D for positioning :')
# TBD:  Optional toggle for only `_unhandled_input()` or accepting all `_input()`?


#region Parameters

## The [Entity] to instantiate a copy of when the Gun shoots.
@export var bulletEntity: PackedScene # TODO: Enforce `Entity` type

@export var ammo:Stat ## The [Stat] Resource to use as the ammo. If omitted, no ammo is required to fire the gun.
@export var ammoCost: int = 0 ## The ammo used per shot. 0 == Unlimited ammo. NOTE: A negative number will INCREASE the ammo when firing.

## If `true`, the gun fires automatically without any player input.
@export var autoFire: bool = false

## If `true`, the button input has to be unpressed and pressed again for each bullet. If `false`, keep firing as long as the button input is pressed.
@export var pressAgainToShoot: bool = false

## Add the parent entity's [CharacterBody2D] node's velocity to bullets.
## IMPORTANT: Requires [CharacterBodyComponent] and the [member bulletEntity] should have a [LinearMotionComponent].
## @experimental
@export var shouldAddEntityVelocity: bool = false

## Any node such as a [Marker2D] where newly spawned bullets will be placed placed. Bullets will be added as children of the emitter's parent node.
## If omitted, this component's internal "BulletEmitter" [Marker2D] node is used by default, and bullets will be added to the entity's parent.
@export var bulletEmitter: Node2D

## The adjusted position in relation to the [member bulletEmitter] where newly spawned bullets are placed. (0,0) is the position of the emitter.
@export var bulletPositionOffset: Vector2

## An optional parent node for new bullets.
## DEFAULT: If omitted, then bullets are added to the Entity's parent if the [member bulletEmitter] is a child of this [GunComponent], otherwise the emitter's parent node is used.
@export var bulletParentOverride: Node

## The text to display via the Entity's [LabelComponent] when the [member ammo] [Stat] reaches 0 after firing.
@export var ammoDepletedMessage: String = "AMMO DEPLETED"

@export var isPlayerControlled: bool = true: ## Accept player input? Disable for AI-controlled enemies.
	set(newValue):
		if newValue != isPlayerControlled:
			isPlayerControlled = newValue
			self.set_process_unhandled_input(isPlayerControlled)

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


#region Dependencies
var characterBodyComponent: CharacterBodyComponent:
	get:
		if not characterBodyComponent: characterBodyComponent = self.coComponents.get(&"CharacterBodyComponent") # Avoid crash if missing
		return characterBodyComponent

var labelComponent: LabelComponent:
	get:
		if not labelComponent: labelComponent = self.coComponents.get(&"LabelComponent")
		return labelComponent

func getRequiredComponents() -> Array[Script]:
	# GODOT Dumbness: Ternary operator returns untyped array
	if shouldAddEntityVelocity: return [CharacterBodyComponent]
	else: return []
#endregion


#region Process Input

func _unhandled_input(_event: InputEvent) -> void:
	# NOTE: Using [_unhandled_input] allows UI buttons etc. to trap mouse clicks
	# without causing the gun to fire, which looks janky.

	# ATTENTION: If mouse input events are not reaching this component,
	# check the [member Control.mouse_filter] property of any overlaying nodes,
	# and set it to `MOUSE_FILTER_PASS` or `MOUSE_FILTER_IGNORE`.

	if not isEnabled or not isPlayerControlled or autoFire: return

	wasFireActionJustPressed = Input.is_action_just_pressed(GlobalInput.Actions.fire)
	isFireActionPressed = Input.is_action_pressed(GlobalInput.Actions.fire)


func _process(_delta: float) -> void:
	# TBD: PERFORMANCE: Should per-frame updates be conditionally-enabled based on flags and input?

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

#endregion


#region Pew Pew

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
	# PERFORMANCE: Not using Tools.addChildAndSetOwner() to avoid a large amount of function calls if many bullets are fired each frame.

	# If there is no parent specified and the default internal emitter is used, then this component's entity's parent should be the bullet's parent.
	# PERFORMANCE: add_child() must not force_readable_name (which is very slow according to Godot docs)
	if bulletParentOverride:
		bulletParentOverride.add_child(newBullet, false)
	elif bulletEmitter == %BulletEmitter or bulletEmitter.get_parent() == self:
		self.parentEntity.get_parent().add_child(newBullet, false)
	else:
		bulletEmitter.get_parent().add_child(newBullet, false)

	if debugMode: printDebug(str("fire(): newBullet.parent: ", newBullet.get_parent()))
	newBullet.owner = newBullet.get_parent() # For persistence to a [PackedScene] for save/load. CHECK: Is this necessary or will it reduce performance?

	didFire.emit(newBullet)
	startCooldown() # Start the cooldown Timer

	return newBullet


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
		if not self.ammoDepletedMessage.is_empty() and labelComponent:
			labelComponent.display(self.ammoDepletedMessage)

	return true


## Decreases the [member ammo] [Stat] and forges a new [member bulletEntity] [Entity].
func createNewBullet() -> Entity:
	# First, do we have enough ammo?
	if not useAmmo(): return null

	# Start forging a new bullet.

	var newBullet: Entity = bulletEntity.instantiate() as Entity

	if not newBullet:
		printError("Cannot instantiate a new bullet: " + bulletEntity.resource_path)
		return null

	# Prepare the properties
	# CHECK: PERFORMANCE: Are we checking and setting too many properties here?

	newBullet.global_position	= bulletEmitter.global_position + self.bulletPositionOffset # CHECK: Should the offset be applied separately to `newBullet.position`?
	newBullet.global_rotation	= bulletEmitter.global_rotation
	newBullet.z_index			= bulletEmitter.z_index
	newBullet.top_level			= bulletEmitter.top_level

	# Copy debugging flags only if bullet's are off
	if not newBullet.isLoggingEnabled: newBullet.isLoggingEnabled = self.debugMode
	if not newBullet.debugMode: newBullet.debugMode = self.debugMode

	# Speed: Add the gun's entity's speed to the bullet's speed, so that the attacker doesn't run into its own bullets if they are too slow.

	if shouldAddEntityVelocity and characterBodyComponent:
		# TODO: Add support for RigidBody2D
		var bulletLinearMotionComponent: LinearMotionComponent = newBullet.components.get(&"LinearMotionComponent")
		if bulletLinearMotionComponent:
			# TODO: CHECK: BUG: FIXME: This does not seem to be the correct way: Shooting while moving backwards makes bullets faster.
			bulletLinearMotionComponent.initialSpeed += characterBodyComponent.body.velocity.length()

	# Who Shot Entity?
	# Use `get()` to avoid crash if `null`

	var bulletDamageComponent: DamageComponent = newBullet.components.get(&"DamageComponent")
	if bulletDamageComponent:  bulletDamageComponent.initiatorEntity = self.parentEntity

	# Factions: Does this gun's entity have a faction and does the bullet also have a FactionComponent? If so, copy the attacker's factions to the new bullet.

	var gunFactionComponent: FactionComponent = self.coComponents.get(&"FactionComponent")
	var bulletFactionComponent: FactionComponent = newBullet.components.get(&"FactionComponent")

	if gunFactionComponent and bulletFactionComponent:
		if debugMode: printDebug(str("Copying entity factions to newBullet: ", gunFactionComponent.factions))
		bulletFactionComponent.factions = gunFactionComponent.factions

	if debugMode: printDebug(str("createNewBullet() → ", newBullet))
	return newBullet

#endregion
