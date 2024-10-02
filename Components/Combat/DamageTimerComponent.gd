## Applies damage over time at a regular interval to a [DamageReceivingComponent].

class_name DamageTimerComponent
extends Component


#region Parameters
@export_range(0, 100, 1) var damageOnTimer: int = 1
@export_flags("neutral", "players", "playerAllies", "enemies") var attackerFactions: int = 1
@export var friendlyFire := false
@export var isEnabled := true
#endregion

@onready var damageReceivingComponent: DamageReceivingComponent = coComponents.DamageReceivingComponent # TBD: Static or dynamic?


func onTimerTimeout() -> void:
	if not isEnabled: return
	damageReceivingComponent.handleDamage(null, damageOnTimer, attackerFactions, friendlyFire)
