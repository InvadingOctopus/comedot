## Causes damage to when this component's [Area2D] "hitbox" collides with a [DamageReceivingComponent]'s "hurtbox", which then passes it on to the victim entity's [HealthComponent].
## If both entities have a [FactionComponent] then damage is dealt only if the entities do not share any faction.
## If a [FactionComponent] is missing then damage is always dealt.
## ALERT: Remember to set the proper [member CollisionObject2D.collision_layer] & [member CollisionObject2D.collision_mask] or the combat system may behave unexpectedly!
## The default for both properties is the `combat` physics layer, but for player entities the layer should be `players` and the mask should be `enemies`, and vice versa for monsters.
## TIP: For hazards such as pools of acid or lava that cause repeated damage as long as the victim remains in contact, use [DamageRepeatingComponent].
## TIP: For attacks such as poison arrows etc. that cause "lingering" damage over time, add a [DamageOverTimeComponent] to the victim entity.
## Requirements: This component must be an [Area2D] or connected to signals from an [Area2D] representing the "hitbox".

class_name DamageComponent
extends Component


#region Parameters

## The amount of damage to cause to the target when this [DamageComponent] first collides with a [DamageReceivingComponent].
## Suitable for bullets and other nodes that disappear on a collision.
## This value may be set to 0 if another script is going to handle the signals and apply the damage.
@export_range(0, 1000, 1) var damageOnCollision: int = 1 # NOTE: Should this be an integer or float?

## Optional. The amount of damage to cause to the target for as long as this [DamageComponent] remains within the area of a [DamageReceivingComponent].
## Suitable for monsters or hazards and other nodes which remain in the scene after causing damage.
## NOTE: Damage-per-frame may be caused in the same frame in which a collision first happens.
@export_range(0, 1000) var damagePerSecond: float = 0 # NOTE: Should this be an integer or float?

## Should bullets from the same faction hurt?
@export var friendlyFire: bool = false

## Should the parent Entity be removed when this [DamageComponent]'s "hitbox" collides with a [DamageReceivingComponent]'s "hurtbox"?
## Useful for "bullet" entities (including arrows etc.) that must be blocked by all receivers.
## ALERT: This is performed EVEN WHEN there NO actual damage is applied! i.e. even when there are no opposing factions. So a player's bullet may get blocked by the player entity itself.
## TIP: To remove a "bullet" etc. ONLY when damage is actually applied (i.e. on collision between opposing factions), use [member removeEntityOnApplyingDamage] instead.
@export var removeEntityOnCollisionWithReceiver: bool = false

## Should the parent Entity be removed when this [DamageComponent] causes damage to a [DamageReceivingComponent] related to an opposing [FactionComponent]?
## Useful for "bullet" entities (including arrows etc.) that should NOT be blocked by the entity which fired them.
## Ignored if the combatants do not have opposing factions or friendly fire.
## TIP: To always remove a "bullet" etc. on ANY collision with a receiver, use [member removeEntityOnCollisionWithReceiver].
## WARNING: Do NOT set to `true` for persistent "hazards" like spikes or acid pools etc.
@export var removeEntityOnApplyingDamage: bool = false

@export var isEnabled: bool = true: ## Also effects [member Area2D.monitorable] and [member Area2D.monitoring]
	set(newValue):
		isEnabled = newValue
		# Toggle the area too, to ensure that [DamageComponent] can re-detect us,
		# e.g. after an [InvulnerabilityOnHitComponent] ends.

		# NOTE: Cannot set flags directly because Godot error: "Function blocked during in/out signal."
		set_deferred("monitorable", newValue)
		set_deferred("monitoring",  newValue)

#endregion


#region State

## The "attacker" [Entity] that "initiated" the damage or fired the bullet etc. It may be the player entity, a monster, or a "hazard" like a pool of acid.
## Optional; may be used to handle various situations such as ignoring the collision of a bullet against the entity that fired the bullet (not currently implemented).
## NOTE: When applied to the [DamageComponent] of a "bullet" entity, this value is NOT the bullet entity: It's the entity that FIRED the bullet.
## If `null` on [method _ready], it is set to this component's [member parentEntity]
## @experimental
@export_storage var initiatorEntity: Entity

## A list of [DamageReceivingComponent]s currently in collision contact.
var damageReceivingComponentsInContact: Array[DamageReceivingComponent]

## Returns this component as an [Area2D] node.
var area: Area2D:
	get: return (self.get_node(".") as Area2D)

#endregion


#region Dependencies
## A shortcut that returns the [FactionComponent] of the parent [Entity].
@onready var factionComponent: FactionComponent = coComponents.get(&"FactionComponent") # Use `get()` to avoid crash if `null`. TBD: Static or dynamic?
#endregion


#region Signals
signal didCollideReceiver(damageReceivingComponent: DamageReceivingComponent)
signal didLeaveReceiver(damageReceivingComponent:   DamageReceivingComponent)
#endregion


func _ready() -> void:
	if self.initiatorEntity == null: self.initiatorEntity = self.parentEntity


#region Collisions

func onAreaEntered(areaEntered: Area2D) -> void:
	if not isEnabled or areaEntered == self.parentEntity or areaEntered.owner == self.parentEntity: return # Don't run into ourselves. TBD: Will all these checks harm performance?
	if debugMode: printDebug(str("onAreaEntered: ", areaEntered, ", owner: ", areaEntered.owner))

	var damageReceivingComponent: DamageReceivingComponent = getDamageReceivingComponent(areaEntered)

	# If the Area2D is not a DamageReceivingComponent, there's nothing to do.
	if damageReceivingComponent:
		damageReceivingComponentsInContact.append(damageReceivingComponent)
		didCollideReceiver.emit(damageReceivingComponent)
		self.causeCollisionDamage(damageReceivingComponent)

		## ALERT: This is performed EVEN WHEN there NO actual damage is applied! i.e. even when there are no opposing factions. So a player's bullet may get blocked by the player entity itself.
		## TIP: To remove a "bullet" etc. ONLY when damage is actually applied (i.e. on collision between opposing factions), use `removeEntityOnApplyingDamage` instead.
		if removeEntityOnCollisionWithReceiver:
			if debugMode: printDebug("removeEntityOnCollisionWithReceiver")
			self.requestDeletionOfParentEntity()


func onAreaExited(areaExited: Area2D) -> void:
	# NOTE: This should NOT be affected by `isEnabled`; areas that exit should ALWAYS be removed!

	# NOTE: Even though we don't need to use a [DamageReceivingComponent] here, we have to cast the type, to fix this Godot runtime error:
	# "Attempted to erase an object into a TypedArray, that does not inherit from 'GDScript'." :(
	var damageReceivingComponent: DamageReceivingComponent = areaExited.get_node(".") as DamageReceivingComponent # HACK: TODO: Find better way to cast
	if  damageReceivingComponent:
		damageReceivingComponentsInContact.erase(damageReceivingComponent)
		didLeaveReceiver.emit(damageReceivingComponent)


## Casts an [Area2D] as a [DamageReceivingComponent].
func getDamageReceivingComponent(componentArea: Area2D) -> DamageReceivingComponent:
	var damageReceivingComponent: DamageReceivingComponent = componentArea.get_node(".") as DamageReceivingComponent # HACK: TODO: Find better way to cast

	if not damageReceivingComponent:
		## NOTE: This warning may help to set collision masks properly.
		printDebug(str("Cannot cast area as DamageReceivingComponent: ", componentArea, " — Check collision masks"))
		return null

	# Is it our own entity?
	if damageReceivingComponent.parentEntity == self.parentEntity:
		return null

	return damageReceivingComponent


## Calls [method DamageReceivingComponent.processCollision]
func causeCollisionDamage(damageReceivingComponent: DamageReceivingComponent) -> void:
	if not isEnabled: return

	# NOTE: The "own entity" check is done once in `getDamageReceivingComponent()`

	# The signal is emitted in [onAreaEntered]

	# Do we belong to a faction?
	# will be checked in the `factionComponent` property getter

	# Even if we have no faction, damage must be dealt.
	var didReceiveDamage: bool = damageReceivingComponent.processCollision(self, factionComponent)
	if debugMode: printLog(str("causeCollisionDamage: ", self.damageOnCollision, " to ", damageReceivingComponent))
	
	if removeEntityOnApplyingDamage and didReceiveDamage:
			if debugMode: printDebug("removeEntityOnApplyingDamage")
			self.requestDeletionOfParentEntity()


## Calls [method DamageReceivingComponent.processCollision] on ALL the [DamageReceivingComponent]s in [member damageReceivingComponentsInContact]
## Used by [DamageRepeatingComponent]
func causeDamageToAllReceivers() -> void:
	for damageReceivingComponent in self.damageReceivingComponentsInContact:
		damageReceivingComponent.processCollision(self, factionComponent)

#endregion


#region Per-Frame Damage

func _physics_process(delta: float) -> void:
	if not isEnabled or is_zero_approx(damagePerSecond): return

	## NOTE: Damage-per-frame may be caused in the same frame in which a collision first happens.
	## TBD: Skip the frame in which a collision happens?
	## But the would require more work to keep track of each collision :(

	# TODO: Verify that it is indeed per second.
	var damageForThisFrame: float = self.damagePerSecond * delta

	for damageReceivingComponent in damageReceivingComponentsInContact:
		# DEBUG: printLog("causeFrameDamage: " + str(damageReceivingComponent) + " | damageForThisFrame: " + str(damageForThisFrame))
		causeFrameDamage(damageReceivingComponent, damageForThisFrame)


func causeFrameDamage(damageReceivingComponent: DamageReceivingComponent, damageForThisFrame: float) -> void:
	if not isEnabled: return
	if debugMode: printDebug(str("causeFrameDamage() damageReceivingComponent: ", damageReceivingComponent, ", damageForThisFrame: ", damageForThisFrame))

	# NOTE: The "own entity" check is done once in `getDamageReceivingComponent()`

	# TBD: Should there be a signal emitted every frame??
	#willCauseFrameDamage.emit(damageReceivingComponent)

	# Do we belong to a faction?
	# will be checked in the `factionComponent` property getter

	# Even if we have no faction, damage must be dealt.

	# TBD: Why use `handleDamage` directly here?
	# Let's pretend it's because of performance :')
	damageReceivingComponent.handleFractionalDamage(self, damageForThisFrame, factionComponent.factions, self.friendlyFire)

#endregion
