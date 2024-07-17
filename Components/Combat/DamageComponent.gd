## Causes damage to a [DamageReceivingComponent] which then passes it on to a [HealthComponent].
## Requirements: This component should be an [Area2D] node.

class_name DamageComponent
extends Component


#region Parameters

## The amount of damage to cause to the target when this [DamageComponent] first collides with a [DamageReceivingComponent].
## Suitable for bullets.
@export_range(1, 1000, 1) var damageOnCollision: int = 1 # NOTE: Should this be an integer or float?

## Optional. The amount of damage to cause to the target for as long as this [DamageComponent] remains within the area of a [DamageReceivingComponent].
## Suitable for monsters or hazards.
## NOTE: Damage-per-frame may be caused in the same frame in which a collision first happens.
@export_range(0.0, 1000.0) var damagePerSecond: float = 0.0 # NOTE: Should this be an integer or float?

## Optional. A [DamageTimerComponent] to apply to the parent [Entity] of the target [DamageReceivingComponent].
@export var damageTimerComponent: DamageTimerComponent

## Should bullets from the same faction hurt?
@export var friendlyFire := false

#endregion


#region State

## Returns this component as an [Area2D] node.
var area: Area2D:
	get: return (self.get_node(".") as Area2D)

## A shortcut that returns the [FactionComponent] of the parent [Entity].
var factionComponent: FactionComponent:
	# TBD: Export as parameter?
	get: return getCoComponent(FactionComponent)

## A list of [DamageReceivingComponent]s currently in collision contact.
var damageReceivingComponentsInContact: Array[DamageReceivingComponent]

#endregion


#region Signals
signal didCollideWithReceiver(damageReceivingComponent: DamageReceivingComponent)
#endregion


#region Collisions

func onAreaEntered(area: Area2D) -> void:
	var damageReceivingComponent := getDamageReceivingComponent(area)

	# If the Area2D is not a DamageReceivingComponent, there's nothing to do.
	if damageReceivingComponent:
		damageReceivingComponentsInContact.append(damageReceivingComponent)
		didCollideWithReceiver.emit(damageReceivingComponent)
		causeCollisionDamage(damageReceivingComponent)

		if damageTimerComponent:
			applyDamageTimerComponent(damageReceivingComponent)


func onAreaExited(area: Area2D) -> void:
	# No need to cast the area's type, just remove it from the array.
	damageReceivingComponentsInContact.erase(area)


## Casts an [Area2D] as a [DamageReceivingComponent].
func getDamageReceivingComponent(area: Area2D) -> DamageReceivingComponent:
	var damageReceivingComponent: DamageReceivingComponent = area.get_node(".") as DamageReceivingComponent # HACK: TODO: Find better way to cast

	if not damageReceivingComponent:
		## NOTE: This warning may help to set collision masks properly.
		printDebug("Cannot cast area as DamageReceivingComponent: " + str(area) + " | Check collision masks")
		return null

	# Is it our own entity?
	if damageReceivingComponent.parentEntity == self.parentEntity:
		return null

	return damageReceivingComponent

#endregion


func _physics_process(delta: float) -> void:
	if is_zero_approx(damagePerSecond): return

	## NOTE: Damage-per-frame may be caused in the same frame in which a collision first happens.
	## TBD: Skip the frame in which a collision happens?
	## But the would require more work to keep track of each collision :(

	# TODO: Verify that it is indeed per second.
	var damageForThisFrame := self.damagePerSecond * delta

	for damageReceivingComponent in damageReceivingComponentsInContact:
		# DEBUG: printLog("causeFrameDamage: " + str(damageReceivingComponent) + " | damageForThisFrame: " + str(damageForThisFrame))
		causeFrameDamage(damageReceivingComponent, damageForThisFrame)


func causeCollisionDamage(damageReceivingComponent: DamageReceivingComponent) -> void:
	# NOTE: The "own entity" check is done once in `getDamageReceivingComponent()`

	# The signal is emitted in [onAreaEntered]

	# Do we belong to a faction?
	# will be checked in the `factionComponent` property getter

	# Even if we have no faction, damage must be dealt.
	printLog("causeCollisionDamage: " + str(damageReceivingComponent))
	damageReceivingComponent.processCollision(self, factionComponent)


func causeFrameDamage(damageReceivingComponent: DamageReceivingComponent, damageForThisFrame: float) -> void:
	# NOTE: The "own entity" check is done once in `getDamageReceivingComponent()`

	# TBD: Should there be a signal emitted every frame??
	#willCauseFrameDamage.emit(damageReceivingComponent)

	# Do we belong to a faction?
	# will be checked in the `factionComponent` property getter

	# Even if we have no faction, damage must be dealt.

	# TBD: Why use `handleDamage` directly here?
	# Let's pretend it's because of performance :')
	damageReceivingComponent.handleFractionalDamage(self, damageForThisFrame, factionComponent.factions, self.friendlyFire)


func applyDamageTimerComponent(damageReceivingComponent: DamageReceivingComponent) -> DamageTimerComponent:

	# Create a new copy of the provided component.

	var newDamageTimerComponent: DamageTimerComponent = self.damageTimerComponent.duplicate()
	newDamageTimerComponent.attackerFactions = self.factionComponent.factions
	newDamageTimerComponent.friendlyFire 	 = self.friendlyFire

	damageReceivingComponent.handleDamageTimerComponent(newDamageTimerComponent)

	return newDamageTimerComponent
