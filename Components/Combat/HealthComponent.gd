## Stores the entity's health and manages destruction etc.
## For applying damage and handling factions, use the [DamageReceivingComponent].
## NOTE: If you use a [StatsComponent] then you must share the same [Stat] Resource for health between both components.

class_name HealthComponent
extends Component


#region Parameters
@export var health: Stat
@export var shouldRemoveEntityOnZero: bool = false
#endregion

#region Signals

## A decrease is a negative [param difference], so this signal may be connected to the same function as [signal didIncrease].
signal didDecrease(difference: int)

## [param difference] is always positive, so this signal may be connected to the same function as [signal didDecrease], which always has a negative [param difference].
signal didIncrease(difference: int)

## May be less than zero.
signal didZero

## May be greater than [member health].[member Stat.max].
signal didMax

signal willRemoveEntity

#endregion


func _ready() -> void:
	health.changed.connect(onHealthChanged, CONNECT_PERSIST) # CAUTION: TBD: Should `CONNECT_PERSIST` be used?
	%DebugIndicator.text = str(health.value)


func onHealthChanged() -> void:
		var _difference: int = health.previousChange # A decrease should appear as a negative difference

		if health.value < health.previousValue: didDecrease.emit(health.previousChange) # NOTE: This should be a negative number so that both signals may be connected to the same function.
		if health.value > health.previousValue: didIncrease.emit(health.previousChange)
		%DebugIndicator.text = str(health.value)

		if health.value <= 0:
			didZero.emit()
			
			if shouldRemoveEntityOnZero and parentEntity: 
				willRemoveEntity.emit()
				parentEntity.requestDeletion()


## [param damageAmount] must be a positive number. Negative values will INCREASE health.
## Returns: Remaining health.
func damage(damageAmount: int) -> int:
	health.value -= damageAmount
	return health.value


## [param healAmount] must be a positive number. Negative values will DECREASE health.
## Returns: Remaining health.
func heal(healAmount: int) -> int:
	health.value += healAmount

	if health.value >= health.max:
		didMax.emit()

	return health.value
