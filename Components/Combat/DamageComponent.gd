## Causes damage to another Entity when this component's [Area2D] "hitbox" collides with a [DamageReceivingComponent]'s "hurtbox", which then passes it on to the victim entity's [HealthComponent].
## If both entities have a [FactionComponent] then damage is dealt only if the entities do not share any faction. If a [FactionComponent] is missing then damage is always dealt.
## ALERT: Set the appropriate [member CollisionObject2D.collision_layer] & [member CollisionObject2D.collision_mask] on each [Area2D] or the combat system may behave unexpectedly!
## NOTE: The default for both properties is the `combat` physics layer, but for player entities the layer should be `players` and the mask should be `enemies`, and vice versa for monsters.
## TIP: For hazards such as pools of acid or lava that cause repeated damage as long as the victim remains in contact, use [DamageRepeatingComponent].
## TIP: For attacks such as poison arrows etc. that cause "lingering" damage over time, add a [DamageOverTimeComponent] to the victim entity.
## Requirements: This component must be an [Area2D] representing the "hitbox".

class_name DamageComponent
extends Component

# DESIGN: An attacker's [DamageComponent] is the "active" object that initiates the combat and calls the [DamageReceivingComponent]'s damage processing code.
# [DamageReceivingComponent] is the passive object in this system.
# DESIGN: PERFORMANCE: This component cannot use a separate [Area2D] because the combat system needs to casts an [Area2D] to a [DamageComponent].
# This may REDUCE performance but it ensures a self-contained-components workflow.


#region Parameters

## The amount of damage to cause to the target when this [DamageComponent] first collides with a [DamageReceivingComponent].
## Suitable for bullets and other nodes that disappear on a collision.
## This value may be set to 0 if another script is going to handle the signals and apply the damage.
## IMPORTANT: Use [member damageOnCollisionWithModifier] to get the actual damage value including the [member damageModifier] if any.
@export_range(0, 1000, 1) var damageOnCollision: int = 1 # NOTE: Should this be an integer or float?

## An OPTIONAL [Stat] whose [member Stat.value] is added to or subtracted from the base [member damageOnCollision].
## TIP: This allows [Upgrade]s with a [StatModifierPayload] or debuffs etc. to easily increase/decrease the player's attack power.
## TIP: [member damageOnCollision] may be set to 0 to use the [Stat] as the base and sole damage value.
## IMPORTANT: Use [member damageOnCollisionWithModifier] to get the actual damage value.
## @experimental
@export var damageModifier: Stat

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

## Returns the total damage value including the base [member damageOnCollision] +/- the [member damageModifier] [Stat] if any.
## @experimental
var damageOnCollisionWithModifier: int:
	get: return self.damageOnCollision + (damageModifier.value if damageModifier else 0) # FIXED: Wow watch those () brackets, Godot's ternary operator works in unexpected ways without them!

## Returns this component as an [Area2D] node.
var area: Area2D:
	get: return self.get_node(^".") as Area2D

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
	# UNUSED: Signals already connected in .tscn Scene
	# Tools.connectSignal(area.area_entered, self.onAreaEntered)
	# Tools.connectSignal(area.area_exited,  self.onAreaExited)


#region Collisions

func onAreaEntered(areaEntered: Area2D) -> void:
	if not isEnabled or areaEntered == self.parentEntity or areaEntered.owner == self.parentEntity: return # Don't run into ourselves. TBD: Will all these checks harm performance?
	var damageReceivingComponent: DamageReceivingComponent = getDamageReceivingComponent(areaEntered)
	if debugMode: printDebug(str("onAreaEntered(): ", areaEntered, ", damageReceivingComponent: ", damageReceivingComponent.logNameWithEntity if damageReceivingComponent else "null"))

	# If the Area2D is not a DamageReceivingComponent, there's nothing to do.
	if damageReceivingComponent:
		damageReceivingComponentsInContact.append(damageReceivingComponent)
		didCollideReceiver.emit(damageReceivingComponent)
		self.causeCollisionDamage(damageReceivingComponent)

		## ALERT: This is performed EVEN WHEN there NO actual damage is applied! i.e. even when there are no opposing factions. So a player's bullet may get blocked by the player entity itself.
		## TIP: To remove a "bullet" etc. ONLY when damage is actually applied (i.e. on collision between opposing factions), use `removeEntityOnApplyingDamage` instead.
		if removeEntityOnCollisionWithReceiver:
			if debugMode: printDebug("removeEntityOnCollisionWithReceiver")
			self.isEnabled = false # Disable and remove self just in case, to avoid hurting any other victims in the same physics pass :')
			self.removeFromEntity.call_deferred() # AVOID: Godot error: "Removing a CollisionObject node during a physics callback is not allowed and will cause undesired behavior."
			self.requestDeletionOfParentEntity()


func onAreaExited(areaExited: Area2D) -> void:
	# NOTE: This should NOT be affected by `isEnabled`; areas that exit should ALWAYS be removed!

	# NOTE: Even though we don't need to use a [DamageReceivingComponent] here, we have to cast the type, to fix this Godot runtime error:
	# "Attempted to erase an object into a TypedArray, that does not inherit from 'GDScript'." :(
	var damageReceivingComponent: DamageReceivingComponent = areaExited.get_node(^".") as DamageReceivingComponent # HACK: Find better way to cast self?
	if  debugMode: printDebug(str("onAreaExited(): ", areaExited, ", damageReceivingComponent: ", damageReceivingComponent.logNameWithEntity if damageReceivingComponent else "null"))
	if  damageReceivingComponent:
		damageReceivingComponentsInContact.erase(damageReceivingComponent)
		didLeaveReceiver.emit(damageReceivingComponent)


## Returns a [DamageReceivingComponent] by casting an [Area2D] node, if possible.
func getDamageReceivingComponent(collidingArea: Area2D) -> DamageReceivingComponent:
	var damageReceivingComponent: DamageReceivingComponent = collidingArea.get_node(^".") as DamageReceivingComponent # HACK: Find better way to cast self?

	if not damageReceivingComponent:
		## NOTE: This warning may help to set collision masks properly.
		if debugMode: printWarning(str("Cannot cast area as DamageReceivingComponent: ", collidingArea, " — Check collision masks."))
		return null

	# Is it our own entity?
	if self.parentEntity and damageReceivingComponent.parentEntity == self.parentEntity:
		if debugMode: printDebug(str("DamageReceivingComponent belongs to this DamageComponent's Entity: ", damageReceivingComponent.parentEntity.logName))
		return null

	return damageReceivingComponent


## Calls [method DamageReceivingComponent.processCollision]
func causeCollisionDamage(damageReceivingComponent: DamageReceivingComponent) -> void:
	if not isEnabled: return
	if debugMode: printLog(str("causeCollisionDamage() damageOnCollision: ", self.damageOnCollision, " + damageModifier: ", damageModifier.logName if damageModifier else "null", " to ", damageReceivingComponent))

	# NOTE: The "own entity" check is done once in `getDamageReceivingComponent()`

	# The signal is emitted in [onAreaEntered]

	# Do we belong to a faction?
	# will be checked in the `factionComponent` property getter

	# Even if we have no faction, damage must be dealt.
	var didReceiveDamage: bool = damageReceivingComponent.processCollision(self, factionComponent)

	if removeEntityOnApplyingDamage and didReceiveDamage:
			if debugMode: printDebug("removeEntityOnApplyingDamage")
			self.isEnabled = false # Disable and remove self just in case, to avoid hurting any other victims in the same physics pass :')
			self.removeFromEntity.call_deferred() # AVOID: Godot error: "Removing a CollisionObject node during a physics callback is not allowed and will cause undesired behavior."
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
