## Stores the entity's health and manages destruction etc. For applying damage and handling factions, use the [DamageReceivingComponent].

class_name HealthComponent
extends Component


#region Parameters
@export var health: Stat
@export var shouldRemoveParentOnZero: bool = false
#endregion

#region Signals

## May be a negative number.
signal healthDidDecrease(difference: int)

signal healthDidIncrease(difference: int)

## May be less than zero.
signal healthDidZero

## May be greater than maximumHealth.
signal healthDidMax

#endregion


func _ready() -> void:
	health.changed.connect(onHealthChanged, CONNECT_PERSIST) # CAUTION: TBD: Should `CONNECT_PERSIST` be used?
	%DebugIndicator.text = str(health.value)


func onHealthChanged() -> void:
		var _difference: int = health.previousChange # A decrease should appear as a negative difference

		if health.value < health.previousValue: healthDidDecrease.emit(health.previousChange)  # TBD: Should this be a negative number?
		if health.value > health.previousValue: healthDidIncrease.emit(health.previousChange)
		%DebugIndicator.text = str(health.value)

		if health.value <= 0:
			healthDidZero.emit()
			if shouldRemoveParentOnZero:
				parentEntity.requestRemoval()


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
		healthDidMax.emit()

	return health.value
