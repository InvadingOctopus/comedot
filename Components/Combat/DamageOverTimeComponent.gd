## Applies damage over time at a regular interval to the parent entity's [DamageReceivingComponent]. Does NOT depend on "hitbox/hurtbox" collision.
## Enable "Editable Children" to change the durations: $DamageTimer is how often the repeated damage occurs, and $RemovalTimer is when the DoT ends and this component is removed from the entity.
## Add this component to a "victim" entity after a DoT attack such as a poison arrow etc.
## TIP: For entities representing hazards like pools of acid etc., add [DamageRepeatingComponent] to the "ATTACKER" instead.
## WARNING: Currently, multiple components of the same class cannot be added to an entity, so only the 1 latest [DamageOverTimeComponent] may be active at a time.
## Requirements: [DamageReceivingComponent]
## @experimental

class_name DamageOverTimeComponent
extends Component


#region Parameters
@export_range(0, 100, 1) var damagePerTick: int = 1 ## The damage to apply on each [signal Timer.timeout] "tick" of the $DamageTimer.
@export_flags("neutral", "players", "playerAllies", "enemies") var attackerFactions: int = 1
@export var friendlyFire: bool = false
@export var isEnabled: bool = true
#endregion


#region State
@onready var damageTimer:  Timer = $DamageTimer
@onready var removalTimer: Timer = $RemovalTimer ## Does not care about [member isEnabled]

var damageReceivingComponent: DamageReceivingComponent: # TBD: PERFORMANCE: Should this be static? or dynamic to support runtime swapping?
	get:
		if not damageReceivingComponent: damageReceivingComponent = coComponents.get(&"DamageReceivingComponent") # Avoid crash if missing
		return damageReceivingComponent

#endregion


func _ready() -> void:
	# Start when added to Entity
	self.damageTimer.start()
	self.removalTimer.start()


func onDamageTimer_timeout() -> void:
	if not isEnabled or not damageReceivingComponent: return
	damageReceivingComponent.handleDamage(null, damagePerTick, attackerFactions, friendlyFire)


func onRemovalTimer_timeout() -> void:
	# `isEnabled` should not affect removal.
	self.requestDeletion()
