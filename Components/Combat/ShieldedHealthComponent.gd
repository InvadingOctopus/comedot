## A subclass of a [HealthComponent] that lets a "shield" or armor [Stat] absorb damage before reducing the shield Stat.

class_name ShieldedHealthComponent
extends HealthComponent


#region Parameters
@export var shield: Stat
@export var isEnabled: bool = true
#endregion


#region State
var isShielded: bool:
	get: return self.shield.value > 0
#endregion


#region Signals

## A decrease is a negative [param difference], so this signal may be connected to the same function as [signal shieldDidIncrease].
signal shieldDidDecrease(difference: int)

## [param difference] is always positive, so this signal may be connected to the same function as [signal shieldDidDecrease], which always has a negative [param difference].
signal shieldDidIncrease(difference: int)

## May be less than zero.
signal shieldDidZero

## May be greater than [member shield].[member Stat.max].
signal shieldDidMax

#endregion


func _ready() -> void:
	shield.changed.connect(onShieldChanged, CONNECT_PERSIST) # CAUTION: TBD: Should `CONNECT_PERSIST` be used?
	super._ready()
	# %DebugIndicator.text = str(shield.value) # TBD: Add a visual indicator into this component or let [DebugComponent] handle this job?


func onShieldChanged() -> void:
		var difference: int = shield.previousChange # A decrease should appear as a negative difference

		if shield.value < shield.previousValue: shieldDidDecrease.emit(difference) # NOTE: This should be a negative number so that both signals may be connected to the same function.
		if shield.value > shield.previousValue: shieldDidIncrease.emit(difference)
		# %DebugIndicator.text = str(shield.value) # TBD: ?

		if shield.value <= 0: shieldDidZero.emit()


## [param damageAmount] must be a positive number. Negative values will INCREASE the shield.
## Returns: Remaining shield.
func damage(damageAmount: int) -> int:
	# If we're still shielded, don't let the shield get damaged.
	if shield.value > 0: shield.value -= damageAmount
	else: super.damage(damageAmount)

	return shield.value


## [param rechargeAmount] must be a positive number. Negative values will DECREASE the shield.
## Returns: Remaining shield.
func recharge(rechargeAmount: int) -> int:
	shield.value += rechargeAmount
	if shield.value >= shield.max: shieldDidMax.emit()
	return shield.value