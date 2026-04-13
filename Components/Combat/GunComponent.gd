## Pew Pew
## ALERT: This component relies on [method _unhandled_input] to process player input,
## in order to allow UI elements to receive input without firing the gun.
## If mouse input events are not reaching this component, check the [member Control.mouse_filter] property of any overlaying nodes, and set it to `MOUSE_FILTER_PASS` or `MOUSE_FILTER_IGNORE`.
## NOTE: Enable "Editable Children" to edit the [CooldownTimer] & access the gun sprite or bullet emission position.
## The `$GunSprite` is a separate child node so that the [GunComponent] node can serve as a pivot for rotation etc.
## TIP: For aiming, use [MouseRotationComponent] or [NodeFacingComponent].
## TIP: To hide the internal sprite, enable "Editable Children" and set the visibility, e.g. to use the player's own sprite.
## Requirements: [InputComponent]

class_name GunComponent
extends CooldownComponent

# TODO: PERFORMANCE: Allow non-Entity bullets
# NOTE: The .tscn Scene file cannot inherit from CooldownComponent because CooldownComponent is a Node, but GunComponent needs to be a Node2D for positioning :')


#region Parameters

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			setProcess()
			if isEnabled and self.is_node_ready() and inputComponent: self.onInputComponent_didUpdateInputActionsList(null) # Resync the input state i.e. if the button is already held down when re-enabling.

## If `true`, the gun fires automatically without any player input.
@export var autoFire: bool = false:
	set(newValue):
		if newValue != autoFire:
			autoFire = newValue
			setProcess()

## If `true`, the button input has to be unpressed and pressed again for each bullet. If `false`, keep firing as long as the button input is pressed.
@export var shouldPressAgainToShoot: bool = false:
	set(newValue):
		if newValue != shouldPressAgainToShoot:
			shouldPressAgainToShoot = newValue
			setProcess()


@export_group("Ammo")

@export var ammo:Stat ## The [Stat] Resource to use as the ammo. If omitted, no ammo is required to fire the gun.
@export var ammoCost: int = 0 ## The ammo used per shot. 0 == Unlimited ammo. NOTE: A negative number will INCREASE the ammo when firing.
@export var ammoDepletedMessage: String = "AMMO DEPLETED" ## The text to display as a [TextBubble] when the [member ammo] [Stat] reaches 0 AFTER firing.


@export_group("Bullets")

## The [Entity] to instantiate a copy of when the Gun shoots.
## Does not necessarily have to be a "bullet": It may be an arrow or rock or any other projectile, even a monster!
@export var bulletTemplate: PackedScene # TODO: Enforce `Entity` type

## Any node such as a [Marker2D] where newly spawned bullets will be placed placed. Bullets will be added as children of the emitter's parent node.
## If omitted, this component's internal "%BulletEmitter" [Marker2D] node is used by default, and bullets will be added to the entity's parent.
@export var bulletEmitter: Node2D:
	get:
		if not bulletEmitter:
			if is_instance_valid(internalBulletEmitter): bulletEmitter = internalBulletEmitter # Fallback to the default internal emitter
			else:
				bulletEmitter = selfAsNode2D
				if debugMode: printWarning("No bulletEmitter parameter or internal %BulletEmitter • Using self as emitter")
		return bulletEmitter

## The adjusted position in relation to the [member bulletEmitter] (including rotation & scale) where newly spawned bullets will be placed. (0,0) is the position of the emitter.
@export var bulletPositionOffset: Vector2

## Add the entity's [member CharacterBody2D.get_real_velocity] to the bullets' [LinearMotionComponent], if any.
## IMPORTANT: Requires [CharacterBodyComponent].
## @experimental
@export var shouldAddEntityVelocity: bool = false

## An optional parent node for new bullets.
## DEFAULT: If omitted, then bullets are added to the Entity's parent if the [member bulletEmitter] is a child of this [GunComponent], otherwise the emitter's parent node is used.
@export var bulletParentOverride: Node

#endregion


#region Signals
signal didFire(bullet: Entity)
signal didDepleteAmmo  ## Emitted when [member ammo] goes below 1 after firing the gun.
signal ammoInsufficient ## Emitted when attempt to fire the gun while [member ammo] is < 1
#endregion


#region State

@onready var selfAsNode2D:			Node2D = self.get_node(^".") as Node2D
@onready var internalBulletEmitter:	Node2D = self.get_node_or_null(^"%BulletEmitter") as Node2D # For crash-safety, to make it optional so that the node may be deleted from the scene if it's not needed

var isFireActionPressed:	  bool = false:
	set(newValue):
		if newValue != isFireActionPressed:
			isFireActionPressed = newValue
			setProcess()
			
var wasFireActionJustPressed: bool = false:
	set(newValue):
		if newValue != wasFireActionJustPressed:
			wasFireActionJustPressed = newValue
			setProcess()

#region


#region Dependencies

@onready var inputComponent: InputComponent = coComponents.InputComponent # TBD: Include subclasses?

var characterBodyComponent: CharacterBodyComponent: ## For adding the entity's velocity
	get:
		if not characterBodyComponent: characterBodyComponent = coComponents.get(&"CharacterBodyComponent") # Avoid crash if missing
		return characterBodyComponent

func getRequiredComponents() -> Array[Script]:
	# GODOT Dumbness: Ternary operator returns untyped array
	if shouldAddEntityVelocity: return [InputComponent, CharacterBodyComponent]
	else: return [InputComponent]

#endregion


func _ready() -> void:
	super._ready()
	Tools.connectSignal(inputComponent.didUpdateInputActionsList, self.onInputComponent_didUpdateInputActionsList)
	setProcess()


#region Process Input

func onInputComponent_didUpdateInputActionsList(_event: InputEvent) -> void:
	isFireActionPressed = inputComponent.inputActionsPressed.has(GlobalInput.Actions.fire) # DESIGN: Check state instead of InputEvent, to allow runtime modification/injection.
	if isFireActionPressed: wasFireActionJustPressed = Input.is_action_just_pressed(GlobalInput.Actions.fire)
	else: wasFireActionJustPressed = false


## PERFORMANCE: Makes sure the component doesn't update every frame unless firing.
func setProcess() -> void:
	self.set_process(isEnabled and \
		(autoFire or wasFireActionJustPressed or \
			(isFireActionPressed and not shouldPressAgainToShoot)))


func _process(_delta: float) -> void:
	# TBD: PERFORMANCE: Should per-frame updates be conditionally-enabled based on flags and input?

	# NOTE: Input actions should be handled in _unhandled_input()
	# to allow UI buttons etc. to handle mouse clicks,
	# because it looks janky if the gun fires when the player clicks on an unrelated UI button.

	# NOTE: RARE: If the fire button is released but the event is eaten by UI or some other node,
	# the gun may get stuck firing (until pressed and released again), so clear the flags here just in case.
	# BUT only do it if we're player-controlled! If AI generated synthetic input events, then checking Input.is_action_pressed() may be `false`
	# CHECK: PERFORMANCE: Does this slow things down?
	if isFireActionPressed \
		and not Input.is_action_pressed(GlobalInput.Actions.fire) \
		and inputComponent and inputComponent.isPlayerControlled:
			isFireActionPressed = false
			wasFireActionJustPressed = false

	if autoFire and not isOnCooldown:
		fire()
	elif not shouldPressAgainToShoot and isFireActionPressed:
		fire()
	elif shouldPressAgainToShoot and wasFireActionJustPressed:
		fire()
		wasFireActionJustPressed = false

#endregion


#region Pew Pew

## Returns the bullet that was fired.
func fire(emitter: Node2D = self.bulletEmitter, ignoreCooldown: bool = false) -> Entity:
	if not isEnabled: return null
	if isOnCooldown and not ignoreCooldown: return null

	if not bulletTemplate:
		printWarning("No bulletTemplate specified!")
		return null

	# Create a new bullet, but it may fail if there is not enough ammo or any other errors.
	var newBullet: Entity = createBullet(emitter) # shouldUseAmmo, not shouldApplyTransforms because 
	if not newBullet: return null

	# Add the bullet to the scene
	# after determining which node should contain the new bullet
	
	var bulletParent: Node

	# Is there a custom parent specified?
	if bulletParentOverride: bulletParent = bulletParentOverride
	
	# Is it this component's internal Marker2D or its own node itself? Then the entity's parent (usually the root scene) should contain the bullet
	elif bulletEmitter == internalBulletEmitter or bulletEmitter == self or bulletEmitter.get_parent() == self:
		bulletParent = parentEntity.get_parent()
		
	# Otherwise, get the parent of whatever the "custom" emitter node is
	else: bulletParent = bulletEmitter.get_parent()

	# PERFORMANCE: Not using NodeTools.addChildAndSetOwner() to avoid a large amount of function calls if many bullets are fired each frame.
	bulletParent.add_child(newBullet, false) # PERFORMANCE: not force_readable_name (which is "very slow" according to Godot documentation)

	# CHECK: Should we [re]apply the position/rotation/etc AFTER the bullet is added to a parent node?
	# to ensure the parent's rotation/scale/etc transforms are also applied? or does that happen anyway?

	if debugMode: printDebug(str("fire() bulletParent: ", bulletParent))
	newBullet.owner = bulletParent # For persistence to a [PackedScene] for save/load. CHECK: Is this necessary or will it reduce performance?

	didFire.emit(newBullet)
	startCooldown() # Start the cooldown Timer

	return newBullet


## Checks if the [member ammo] [Stat] can pay for the [member ammoCost].
## If there is no cost or Stat, then it is assumed that no ammo is required to use this weapon so the result is always `true`.
## Does NOT consume ammo and does NOT check [member isEnabled].
func checkAmmo() -> bool:
	# If no ammo resource is specified, no ammo is needed!
	if self.ammoCost == 0 or not self.ammo: return true

	# Do we have enough ammo?
	if ammo.value < ammoCost:
		if debugMode: printDebug("checkAmmo(): Not enough ammo")
		ammoInsufficient.emit()
		return false
	else: return true


## Deducts the [member ammoCost] from the [member ammo] [Stat].
## If no [member ammo] [Stat] Resource is specified, no ammo is needed.
## Returns `false` if [member ammo] is specified but there is not enough ammo, or if not [param isEnabled].
func useAmmo(shouldCheckAmmo: bool = true) -> bool:
	if not isEnabled: return false # If this component is disabled it shouldn't consume a Stat
	if shouldCheckAmmo and not checkAmmo(): return false

	if self.ammoCost == 0 or not self.ammo: return true # If no ammo resource is specified, no ammo is needed!
	ammo.value -= ammoCost

	# Did we just deplete the ammo with this shot?
	if ammo.previousValue > 0 and ammo.value <= 0:
		if debugMode: printDebug("useAmmo(): ammo depleted")
		didDepleteAmmo.emit()
		if not self.ammoDepletedMessage.is_empty(): TextBubble.create(self.ammoDepletedMessage)

	return true


## Decreases the [member ammo] [Stat] and forges a new [member bulletTemplate] [Entity].
## Does NOT check [member isEnabled] so that external scripts may use this method to create bullets,
## NOTE: but will fail if [member shouldUseAmmo] but not [member isEnabled].
func createBullet(emitter: Node2D = self.bulletEmitter, shouldUseAmmo: bool = true) -> Entity:
	if shouldUseAmmo and not isEnabled:
		if debugMode: printDebug("createBullet(): shouldUseAmmo but not isEnabled: Bullet not created")
		return null

	# First, do we have a valid emitter?
	if not is_instance_valid(emitter): emitter = selfAsNode2D # Fallback to this component itself as the emission point

	# Next, CHECK if we have enough ammo, but do NOT consume it yet
	if shouldUseAmmo and not checkAmmo(): return null

	# Forge a new bullet and validate it.
	# PERFORMANCE: This happens after the ammo check because it's a more expensive task
	var newBullet: Entity = bulletTemplate.instantiate() as Entity

	if not newBullet:
		printError("Cannot instantiate a new bullet: " + bulletTemplate.resource_path)
		return null

	# If we successfully made a bullet, eat the ammo
	if shouldUseAmmo and not useAmmo(false): return null # not shouldCheckAmmo because we already checked

	# Prepare the properties
	# CHECK: PERFORMANCE: Are we checking and setting too many properties here?

	newBullet.global_position	= emitter.to_global(self.bulletPositionOffset) # NOTE: use to_global() instead of a simple + to incldue rotation & scale
	newBullet.global_rotation	= emitter.global_rotation
	newBullet.z_index			= emitter.z_index
	newBullet.top_level			= emitter.top_level

	# CHECK: Should we [re]apply the position/rotation/etc AFTER the bullet is added to a parent node?
	# to ensure the parent's rotation/scale/etc transforms are also applied? or does that happen anyway?

	# Copy debugging flags only if bullet's are off
	if not newBullet.isLoggingEnabled: newBullet.isLoggingEnabled = self.debugMode
	if not newBullet.debugMode: newBullet.debugMode = self.debugMode

	# Speed: Add the gun's entity's speed to the bullet's speed, so that the attacker doesn't run into its own bullets if they are too slow.

	if shouldAddEntityVelocity and characterBodyComponent:
		# TODO: Add support for RigidBody2D
		var bulletLinearMotionComponent: LinearMotionComponent = newBullet.components.get(&"LinearMotionComponent") # TBD: Include subclasses?
		if  bulletLinearMotionComponent:
			# TODO: CHECK: BUG: FIXME: This does not seem to be the correct way: Shooting while moving backwards makes bullets faster.
			bulletLinearMotionComponent.initialSpeed += characterBodyComponent.body.get_real_velocity().length() # NOTE: Get the REAL velocity so it LOOKS and feels natural.

	# Who Shot Entity?
	# Use `get()` to avoid crash if `null`

	var bulletDamageComponent: DamageComponent = newBullet.components.get(&"DamageComponent")
	if  bulletDamageComponent: bulletDamageComponent.initiatorEntity = self.parentEntity

	# Factions: Does this gun's entity have a faction and does the bullet also have a FactionComponent? If so, copy the attacker's factions to the new bullet.

	var gunFactionComponent: FactionComponent = coComponents.get(&"FactionComponent")
	var bulletFactionComponent: FactionComponent = newBullet.components.get(&"FactionComponent")

	if gunFactionComponent and bulletFactionComponent:
		if debugMode: printDebug(str("Copying entity factions to newBullet: ", gunFactionComponent.factions))
		bulletFactionComponent.factions = gunFactionComponent.factions

	if debugMode: printDebug(str("createBullet() → ", newBullet))
	return newBullet

#endregion
