## A subclass of a [HealthComponent] that lets a "shield" or armor [Stat] absorb damage before reducing the shield Stat.

class_name ShieldedHealthComponent
extends HealthComponent


#region Parameters

## The [Stat] that will absorb the damage before [member HealthComponent.health] can be decreased.
@export var shield: Stat

## If true, [method recharge] will call [method HealthComponent.heal] if [member shield] is at maximum and [member isShieldEnabled].
## NOTE: "LEFTOVER" values are IGNORED. e.g. if the `rechargeAmount` is 100 while the shield is at 9 and its maximum is 10, the shield will only be recharged to 10 and healing will not occur.
@export var shouldHealOnMaxRecharge: bool = false

## If false, all damage is dealt directly to [member HealthComponent.health] and "recharging" is disabled.
@export var isShieldEnabled: bool = true

#endregion


#region State
var isProtecting: bool:
	get: return self.isShieldEnabled and shield.value > 0
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


## Applies the specified damage to the [member shield] [Stat]. If shield is 0 or [member isShieldEnabled] is false, then the damage is passed to the [member HealthComponent.health].
## NOTE: [param damageAmount] must be a positive number. Negative values will INCREASE the shield.
## Returns: Remaining shield.
func damage(damageAmount: int) -> int:
	# If we're still shielded, don't let the health get damaged.
	if self.isShieldEnabled and shield.value > 0: 
		shield.value -= damageAmount
	else: 
		super.damage(damageAmount)

	return shield.value


## Increases the [member shield] [Stat].
## If [member shouldHealOnMaxRecharge] is true and [member shield] is at its [member Stat.max], the [param rechargeAmount] is passed on to [method HealthComponent.heal].
## If [member isShieldEnabled] is false, this method does nothing.
## NOTE: "LEFTOVER" values are IGNORED. e.g. if the `rechargeAmount` is 100 while the shield is at 9 and its maximum is 10, the shield will only be recharged to 10 and healing will not occur.
## NOTE: [param rechargeAmount] must be a positive number. Negative values will DECREASE the shield.
## Returns: Remaining shield.
func recharge(rechargeAmount: int) -> int:
	if not self.isShieldEnabled: return shield.value

	# If the shields are at max, heal the health.
	if self.shouldHealOnMaxRecharge and shield.value >= shield.max:
		super.heal(rechargeAmount)
	else:
		shield.value += rechargeAmount
		if shield.value >= shield.max: shieldDidMax.emit()

	return shield.value
