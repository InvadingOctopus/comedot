## Causes damage to a [DamageReceivingComponent] which then passes it on to a [HealthComponent].
## Requirements: This component should be an [Area2D] node.

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

## Optional. A [DamageTimerComponent] to apply to the parent [Entity] of the target [DamageReceivingComponent].
@export var damageTimerComponent: DamageTimerComponent

## Should bullets from the same faction hurt?
@export var friendlyFire: bool = false

## Should the parent Entity be removed when this [DamageComponent] collides with a [DamageReceivingComponent]?
## Useful for bullets.
@export var removeEntityOnCollisionWithDamageReceiver: bool = false

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

## Returns this component as an [Area2D] node.
var area: Area2D:
	get: return (self.get_node(".") as Area2D)

## A shortcut that returns the [FactionComponent] of the parent [Entity].
@onready var factionComponent: FactionComponent = coComponents.FactionComponent # TBD: Static or dynamic?

## A list of [DamageReceivingComponent]s currently in collision contact.
var damageReceivingComponentsInContact: Array[DamageReceivingComponent]

#endregion


#region Signals
signal didCollideWithReceiver(damageReceivingComponent: DamageReceivingComponent)
#endregion


#region Collisions

func onAreaEntered(areaEntered: Area2D) -> void:
	if not isEnabled or areaEntered == self.parentEntity or areaEntered.owner == self.parentEntity: return # Don't run into ourselves. TBD: Will all these checks harm performance?
	if shouldShowDebugInfo: printDebug(str("onAreaEntered: ", areaEntered, ", owner: ", areaEntered.owner))

	var damageReceivingComponent: DamageReceivingComponent = getDamageReceivingComponent(areaEntered)

	# If the Area2D is not a DamageReceivingComponent, there's nothing to do.
	if damageReceivingComponent:
		damageReceivingComponentsInContact.append(damageReceivingComponent)
		didCollideWithReceiver.emit(damageReceivingComponent)
		self.causeCollisionDamage(damageReceivingComponent)

		if damageTimerComponent:
			applyDamageTimerComponent(damageReceivingComponent)
		
		if removeEntityOnCollisionWithDamageReceiver:
			printDebug("removeEntityOnCollisionWithDamageReceiver")
			self.requestDeletionOfParentEntity()


func onAreaExited(areaExited: Area2D) -> void:
	# NOTE: This should NOT be affected by `isEnabled`; areas that exit should ALWAYS be removed!

	# NOTE: Even though we don't need to use a [DamageReceivingComponent] here, we have to cast the type, to fix this Godot runtime error:
	# "Attempted to erase an object into a TypedArray, that does not inherit from 'GDScript'." :(
	var damageReceivingComponent: DamageReceivingComponent = areaExited.get_node(".") as DamageReceivingComponent # HACK: TODO: Find better way to cast
	if  damageReceivingComponent: damageReceivingComponentsInContact.erase(damageReceivingComponent)


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

#endregion


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


func causeCollisionDamage(damageReceivingComponent: DamageReceivingComponent) -> void:
	if not isEnabled: return

	# NOTE: The "own entity" check is done once in `getDamageReceivingComponent()`

	# The signal is emitted in [onAreaEntered]

	# Do we belong to a faction?
	# will be checked in the `factionComponent` property getter

	# Even if we have no faction, damage must be dealt.
	printLog("causeCollisionDamage: " + str(damageReceivingComponent))
	damageReceivingComponent.processCollision(self, factionComponent)


func causeFrameDamage(damageReceivingComponent: DamageReceivingComponent, damageForThisFrame: float) -> void:
	if not isEnabled: return
	if shouldShowDebugInfo: printDebug(str("causeFrameDamage() damageReceivingComponent: ", damageReceivingComponent, ", damageForThisFrame: ", damageForThisFrame))

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
	if not isEnabled: return
	if shouldShowDebugInfo: printDebug(str("applyDamageTimerComponent() damageReceivingComponent: ", damageReceivingComponent))
	
	# Create a new copy of the provided component.

	var newDamageTimerComponent: DamageTimerComponent = self.damageTimerComponent.duplicate()
	newDamageTimerComponent.attackerFactions = self.factionComponent.factions
	newDamageTimerComponent.friendlyFire 	 = self.friendlyFire

	damageReceivingComponent.handleDamageTimerComponent(newDamageTimerComponent)

	return newDamageTimerComponent
