## Stores the entity's health and manages destruction etc.
## For applying damage and handling factions, use the [DamageReceivingComponent].
## NOTE: If you use a [StatsComponent] then you must share the same [Stat] Resource for health between both components.

class_name HealthComponent
extends Component


#region Parameters

@export var health: Stat

## Enable for the main player entity to emit the global [signal GameState.gameDidOver] signal. Also see: GameOver.gd
## Affected by [member isEnabled].
## WARNING: Should NOT be used if the game has more than 1 player; use [method GameState.removePlayer] instead to emit the Game Over signal only after all players are dead.
@export var shouldGameOverOnZero: bool = false

## Affected by [member isEnabled].
@export var shouldRemoveEntityOnZero: bool = false

## If true, [member health] will not decrease (or increase, if the damage is negative) more than [member maximumHealthDamagePerHit] during a single call to [method damage].
## This may be used for objects or enemies that require a fixed number of hits to destroy, no matter what the "strength" of the gun or attack is.
@export var shouldClampHealthDamage: bool

## Limits the maximum amount of damage during a single call to [method damage] if [member HealthComponent.health] is true.
## NOTE: If this limit is NEGATIVE then only HEALING will be allowed.
@export var maximumHealthDamagePerHit: int

@export var isEnabled: bool = true

#endregion

#region Signals

## A decrease is a negative [param difference], so this signal may be connected to the same function as [signal healthDidIncrease].
signal healthDidDecrease(difference: int)

## [param difference] is always positive, so this signal may be connected to the same function as [signal healthDidDecrease], which always has a negative [param difference].
signal healthDidIncrease(difference: int)

## NOTE: Emitted ONLY when the health DECREASES from >0 to <=0, not if it changes from <0 to <0. NOT affected by [member isEnabled].
signal healthDidZero

## May be greater than [member health].[member Stat.max].
signal healthDidMax

signal willRemoveEntity

#endregion


func _ready() -> void:
	health.changed.connect(onHealthChanged, CONNECT_PERSIST) # CAUTION: TBD: Should `CONNECT_PERSIST` be used?
	# %DebugIndicator.text = str(health.value) # TBD: Add a visual indicator into this component or let [DebugComponent] handle this job?


func onHealthChanged() -> void:
		var difference: int = health.previousChange # A decrease should appear as a negative difference

		if health.value < health.previousValue: healthDidDecrease.emit(difference) # NOTE: This should be a negative number so that both signals may be connected to the same function.
		if health.value > health.previousValue: healthDidIncrease.emit(difference)
		# %DebugIndicator.text = str(health.value) # TBD: ?

		# NOTE: Emit signals and handle "death" ONLY when the health DECREASES from >0 to <=0, not if it changes from <0 to <0. (Why? It just makes sense that way, and to reduce excessive signals.)
		if difference < 0 and health.value <= 0:
			healthDidZero.emit()
			
			if isEnabled:
				if shouldRemoveEntityOnZero and parentEntity:
					willRemoveEntity.emit()
					parentEntity.requestDeletion()
				if shouldGameOverOnZero:
					GameState.gameDidOver.emit()


## [param damageAmount] must be a positive number. Negative values will INCREASE health.
## If [member shouldClampHealthDamage] is true, then the [param damageAmount] will be limited to [member maximumHealthDamagePerHit] before deducting it from [member health].
## Returns: Remaining [member health].
func damage(damageAmount: int) -> int:
	if debugMode: printTrace([isEnabled, damageAmount, health.value])
	if not isEnabled: return health.value

	if self.shouldClampHealthDamage and damageAmount > self.maximumHealthDamagePerHit:
		if debugMode: printDebug(str("Clamping damage ", damageAmount, " → ", maximumHealthDamagePerHit))
		damageAmount = self.maximumHealthDamagePerHit # NOTE: Limit may be negative. See property documentation.

	health.value -= damageAmount

	return health.value


## [param healAmount] must be a positive number. Negative values will DECREASE health.
## Returns: Remaining health.
func heal(healAmount: int) -> int:
	# TBD: Add option for clamping healing?
	if isEnabled: 
		health.value += healAmount
		if health.value >= health.max: healthDidMax.emit()
	return health.value
