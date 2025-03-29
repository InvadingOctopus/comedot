## Receives damage when this component's [Area2D] "hurtbox" collides with an attacker's [DamageComponent] "hitbox". The damage is passed to the parent entity's [HealthComponent].
## If both entities have a [FactionComponent] then damage is dealt only if the entities do not share any faction. If a [FactionComponent] is missing then damage is always dealt.
## ALERT: Set the appropriate [member CollisionObject2D.collision_layer] & [member CollisionObject2D.collision_mask] on each [Area2D] or the combat system may behave unexpectedly!
## NOTE: The default for both properties is the `combat` physics layer, but for player entities the layer should be `players` and the mask should be `enemies`, and vice versa for monsters.
## Requirements: This component must be an [Area2D] representing the "hurtbox", and the Entity must also have a [HealthComponent] (or subclass).

class_name DamageReceivingComponent
extends Component

# DESIGN:	[DamageReceivingComponent] should NOT monitor the physics: It is the passive object in relation to the attacker's [DamageComponent] which is the "active" object that initiates the combat and calls the damage processing code.
# DESIGN: PERFORMANCE: This component cannot use a separate [Area2D] because the combat system needs to casts an [Area2D] to a [DamageReceivingComponent].
# This may REDUCE performance but it ensures a self-contained-components workflow.
# NOTE:		Do NOT modify the `healthComponent.health` directly; use `healthComponent.damage()` to ensure that subclasses such as [ShieldedHealthComponent] may be able to intercept and redirect the damage.
# TBD:		Dynamically find co-components?


#region Parameters
@export var shouldRemoveEntityIfNoHealthComponent: bool = true ## Lets this component be usable without a [THealthComponent], as a single solution for basic gameplay and entities that don't need to have "health".

@export var isEnabled: bool = true: ## Also effects [member Area2D.monitorable] and [member Area2D.monitoring]
	set(newValue):
		isEnabled = newValue
		# Toggle the area too, to ensure that [DamageComponent] can re-detect us,
		# e.g. after an [InvulnerabilityOnHitComponent] ends.

		# NOTE: Cannot set flags directly because Godot error: "Function blocked during in/out signal."
		set_deferred("monitorable", newValue)
		set_deferred("monitoring",  newValue)
#endregion


#region Signals

## Emitted when the factions are opposing or there is friendly fire, EVEN if there is no [HealthComponent].
## NOTE: The [param amount] may NOT be the ACTUAL amount of "health" deducted, which depends on the implementation of [HealthComponent], if there are any healing effects or "shields" etc.
## TIP:  To monitor actual changes in entity's "health", connect to [HealthComponent] signals.
signal didReceiveDamage(damageComponent: DamageComponent, amount: int, attackerFactions: int)

## This signal is always raised when colliding with a [DamageComponent] even if the factions are friendly and no health is reduced.
signal didCollideWithDamage(damageComponent: DamageComponent)

signal didAccumulateFractionalDamage(damageComponent: DamageComponent, amount: float, attackerFactions: int) ## @experimental

signal willRemoveEntity ## Emitted if there is no [HealthComponent] and [member shouldRemoveEntityIfNoHealthComponent]
#endregion


#region State

## To eliminate any possibility of bugs or inaccuracies arising from floating point math imprecision.
var accumulatedFractionalDamage: float

## A list of [DamageComponent]s currently in collision contact.
var damageComponentsInContact: Array[DamageComponent]

## Returns this component as an [Area2D] node.
var area: Area2D:
	get: return self.get_node(^".") as Area2D

#endregion


#region Dependencies

## May be a subclass such as [ShieldedHealthComponent].
@onready var healthComponent:  HealthComponent  = parentEntity.findFirstComponentSubclass(HealthComponent)
@onready var factionComponent: FactionComponent = coComponents.get(&"FactionComponent") # Avoid crash if missing
#endregion


# func _ready() -> void:
	# UNUSED: Signals already connected in .tscn Scene
	# Tools.connectSignal(area.area_entered, self.onAreaEntered)
	# Tools.connectSignal(area.area_exited,  self.onAreaExited)


#region Collisions

func onAreaEntered(areaEntered: Area2D) -> void:
	if not isEnabled or areaEntered == self.parentEntity or areaEntered.owner == self.parentEntity: return # Don't run into ourselves. TBD: Will all these checks harm performance?
	var damageComponent: DamageComponent = getDamageComponent(areaEntered)
	if debugMode: printDebug(str("onAreaEntered(): ", areaEntered, ", damageComponent: ", damageComponent.logNameWithEntity if damageComponent else "null"))

	# If the Area2D is not a DamageComponent, there's nothing to do.
	if damageComponent:
		damageComponentsInContact.append(damageComponent)
		didCollideWithDamage.emit(damageComponent)

	# processCollision(damageComponent, null) # NOTE: Damage-causing area collision is initiated by the [DamageComponent] script.


func onAreaExited(areaExited: Area2D) -> void:
	if not isEnabled: return

	# NOTE: Even though we don't need to use a [DamageComponent] here, we have to cast the type, to fix this Godot runtime error:
	# "Attempted to erase an object into a TypedArray, that does not inherit from 'GDScript'." :(
	var damageComponent: DamageComponent = areaExited.get_node(^".") as DamageComponent # HACK: Find better way to cast self?
	if  debugMode: printDebug(str("onAreaExited(): ", areaExited, ", damageComponent: ", damageComponent.logNameWithEntity if damageComponent else "null"))
	if  damageComponent: damageComponentsInContact.erase(damageComponent)

	# Reset the `accumulatedFractionalDamage` if there is no source of damage in contact.
	if damageComponentsInContact.is_empty():
		accumulatedFractionalDamage = 0


## Returns a [DamageComponent] by casting an [Area2D] node, if possible.
func getDamageComponent(collidingArea: Area2D) -> DamageComponent:
	var damageComponent: DamageComponent = collidingArea.get_node(^".") as DamageComponent # HACK: Find better way to cast self?

	if not damageComponent:
		## NOTE: This warning may help to set collision masks properly.
		if debugMode: printWarning(str("Cannot cast area as DamageComponent: ", collidingArea, " — Check collision masks."))
		return null

	# Is it our own entity?
	if self.parentEntity and damageComponent.parentEntity == self.parentEntity:
		if debugMode: printDebug(str("DamageComponent belongs to this DamageComponent's Entity: ", damageComponent.parentEntity.logName))
		return null

	return damageComponent


## This function may be called by a colliding [DamageComponent].
## Returns `true` if there are opposing factions or friendly fire, or no [FactionComponent] (which means damage is always applied).
func processCollision(damageComponent: DamageComponent, attackerFactionComponent: FactionComponent) -> bool:
	if not isEnabled: return false
	if debugMode: printDebug(str("processCollision() damageComponent: ", damageComponent.logNameWithEntity, ", attackerFactionComponent: ", attackerFactionComponent))
	# Not creating an "attackerFactions" or whatever variable to improve performance, maybe?
	# NOTE: Get damageOnCollisionWithModifier to include the damageModifier Stat from Upgrades/debuffs etc.!
	if attackerFactionComponent:
		return self.handleDamage(damageComponent, damageComponent.damageOnCollisionWithModifier, attackerFactionComponent.factions, damageComponent.friendlyFire)
	else: # If the attacker has no factions, damage must be dealt to everyone.
		if debugMode: printDebug("No FactionComponent on attacker DamageComponent's Entity: " + damageComponent.parentEntity.logName)
		return self.handleDamage(damageComponent, damageComponent.damageOnCollisionWithModifier, 0, damageComponent.friendlyFire)

#endregion


## Checks whether the attacking faction should cause damage to the parent entity.
## Take damage only if NO factions match; if the attacker and target are not in a same faction.
## or even if there is no FactionComponent at all. This lets objects such as trees or rocks to handle "mining" and yield resources.
##
## Example: if CharacterA is in the Players faction and CharacterB is in Enemies, they can damage each other.
## But if CharacterB is in Enemies and ALSO IN Players, they will not damage each other.
func checkFactions(attackerFactions: int = 0, friendlyFire: bool = false) -> bool:
	var shouldReceiveDamage: bool = false

	if friendlyFire or not self.factionComponent:
		shouldReceiveDamage = true
	else:
		shouldReceiveDamage = self.factionComponent.checkOpposition(attackerFactions)

	if debugMode: printDebug(str("checkFactions() attackerFactions: ", attackerFactions, ", selfFactions: ", self.factionComponent.factions, ", friendlyFire: ", friendlyFire, ", shouldReceiveDamage: ", shouldReceiveDamage))
	return shouldReceiveDamage


#region Damage

## Passes the [param damageAmount] to a [HealthComponent] if the damage is from an opposing faction or [param friendlyFire].
## Returns `true` if there are opposing factions or friendly fire, or no [param attackerFactions] (which means damage is always applied).
## NOTE: [param damageComponent] may be `null` in case the caller is a different component.
func handleDamage(damageComponent: DamageComponent, damageAmount: int, attackerFactions: int = 0, friendlyFire: bool = false) -> bool:
	if not isEnabled or not checkFactions(attackerFactions, friendlyFire): return false

	if debugMode: printDebug(str("handleDamage() damageComponent: ", damageComponent, ", damageAmount: ", damageAmount, ", attackerFactions: ", attackerFactions, ", friendlyFire: ", friendlyFire, ", healthComponent: ", healthComponent))

	# Even if there is no HealthComponent, we will still emit the signal.
	if healthComponent: healthComponent.damage(damageAmount) # See header notes.

	# DESIGN: This signal should be emitted regardless of actual health deducted, because this signal is to acknowledge that we received an attempt to cause damage.
	# TIP: For changes to health, monitor [HealthComponent]
	didReceiveDamage.emit(damageComponent, damageAmount, attackerFactions)

	if not healthComponent and shouldRemoveEntityIfNoHealthComponent:
		self.willRemoveEntity.emit()
		self.requestDeletionOfParentEntity()

	return true # There were opposing (or no) factions or friendly fire.


## Converts float damage values to a single integer damage value.
## Such as damage accumulated over time/per frame.
## @experimental
func handleFractionalDamage(damageComponent: DamageComponent, fractionalDamage: float, attackerFactions: int = 0, friendlyFire: bool = false) -> void:
	# INFO: The convention is to keep all player-facing stats as integers,
	# to eliminate any potential bugs or inconsistencies arising from floating point math inaccuracies.

	# TBD: WTF? Do we really need this?

	if not isEnabled \
	or is_zero_approx(fractionalDamage) or fractionalDamage < 0.0 \
	or not checkFactions(attackerFactions, friendlyFire):
		return

	self.accumulatedFractionalDamage += fractionalDamage

	# TBD: Is it be costly to emit this signal each frame? Should it be emitted regardless of health?
	didAccumulateFractionalDamage.emit(damageComponent, fractionalDamage, attackerFactions)

	# Drain the damage

	var damageToApply: int = 0

	while accumulatedFractionalDamage > 1.0 \
	or is_equal_approx(accumulatedFractionalDamage, 1.0):
		# DEBUG: printLog("Time: " + str(Time.get_ticks_msec()) + " | accumulatedFractionalDamage: " + str(accumulatedFractionalDamage))
		damageToApply += 1
		accumulatedFractionalDamage -= 1.0

	if damageToApply > 0:
		# Even if there is no HealthComponent, we will still emit the signal.
		if healthComponent: healthComponent.damage(damageToApply) # See header notes.

		# CHECK: Should this signal be emitted regardless of health?
		didReceiveDamage.emit(damageComponent, damageToApply, attackerFactions)


#endregion
