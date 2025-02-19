## Applies damage over time at a regular interval to the parent entity's [DamageReceivingComponent].
## This component may be added to a "victim" entity by an "attacker" entity's [DamageComponent],
## or by a "hazard" such as an area of poisonous gas, pool of acid etc.
## @experimental

class_name DamageTimerComponent
extends Component

# TBD: A better way to handle damage-over-time?


#region Parameters
@export_range(0, 100, 1) var damageOnTimer: int = 1 ## The damage to apply on each [signal Timer.timeout] "tick".
@export_flags("neutral", "players", "playerAllies", "enemies") var attackerFactions: int = 1
@export var friendlyFire: bool = false
@export var isEnabled: bool = true
#endregion


#region State
@onready var damageReceivingComponent: DamageReceivingComponent = coComponents.get(&"DamageReceivingComponent") # Avoid crash if missing
#endregion


func onTimerTimeout() -> void:
	if not isEnabled or not damageReceivingComponent: return
	damageReceivingComponent.handleDamage(null, damageOnTimer, attackerFactions, friendlyFire)
