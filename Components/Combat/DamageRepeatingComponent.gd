## A variant of [DamageComponent] that repeatedly applies its [member damageOnCollision] as long as an opposing entity's [DamageReceivingComponent] [Area2D] "hurtbox" remains in contact.
## Enable "Editable Children" to change the `$DamageTimer` duration. Default: every 1 second.
## Add this component to entities representing hazards like pools of acid etc. or turrets etc. with [BulletlessGunComponent].
## NOTE: The damage is applied to ALL opposing [DamageReceivingComponent]s in contact AT THE SAME TIME, regardless of WHEN they collided.
## TIP: For attacks such as a poison arrow etc. that must apply some lingering damage, add [DamageOverTimeComponent] to the "VICTIM" entity instead.
## Requirements: This component must be an [Area2D] or connected to signals from an [Area2D] representing the "hitbox".
## @experimental

class_name DamageRepeatingComponent
extends TimerComponentBase

# TBD: Cooldown between Timer start/stop?
# TBD: A way to offset the damage time based on WHEN the hurtboxes came in contact?


#region Parameters
@export var shouldStartOnCollision: bool = true: ## If `true` then the [Timer] is started automatically whenever the [signal DamageComponent.didCollideReceiver] signal is received.
	set(newValue):
		if newValue != shouldStartOnCollision:
			shouldStartOnCollision = newValue
			if self.is_node_ready(): Tools.toggleSignal(damageComponent.didCollideReceiver, self.onDamageComponent_didCollideReceiver, self.shouldStartOnCollision)
#endregion


#region Signals
signal didTick(damageReceivingComponentsInContact: Array[DamageReceivingComponent]) ## Emitted only if [member damageReceivingComponentsInContact] is not empty.
#endregion


#region Dependencies
@onready var damageComponent: DamageComponent = coComponents.DamageComponent # TBD: Include subclasses?
#endregion


func _ready() -> void:
	# Just in case...
	timer.autostart = false
	timer.stop()

	# Apply setters because Godot doesn't on _ready()
	Tools.toggleSignal(damageComponent.didCollideReceiver, self.onDamageComponent_didCollideReceiver, self.shouldStartOnCollision)
	Tools.connectSignal(damageComponent.didLeaveReceiver,  self.onDamageComponent_didLeaveReceiver)


## Starts the [member timer] if it's not already on.
func onDamageComponent_didCollideReceiver(_damageReceivingComponent: DamageReceivingComponent) -> void:
	if not isEnabled or not shouldStartOnCollision or not timer.is_stopped() \
	or damageComponent.removeEntityOnCollisionWithReceiver: # If we're getting removed, we can't repeat damage anyway.
		return

	timer.start()
	if debugMode: emitDebugBubble("HIT TIMER ON", randomDebugColor, true) # emitFromEntity


## Stops the [member timer] if there are no [DamageReceivingComponent] hurtboxes in contact.
## Does not care about [member isEnabled],
func onDamageComponent_didLeaveReceiver(_damageReceivingComponent: DamageReceivingComponent) -> void:
	# NOTE: Timer should be stopped even if not isEnabled
	if damageComponent.damageReceivingComponentsInContact.is_empty():
		timer.stop()
		if debugMode: emitDebugBubble("HIT TIMER OFF", randomDebugColor, true) # emitFromEntity


func onTimeout() -> void:
	if not isEnabled or damageComponent.damageReceivingComponentsInContact.is_empty(): return
	if debugMode: emitDebugBubble(str("HIT ", damageComponent.damageReceivingComponentsInContact.size()), randomDebugColor, true) # emitFromEntity
	damageComponent.causeDamageToAllReceivers()
	didTick.emit(damageComponent.damageReceivingComponentsInContact) # TBD: Should this be emitted even if no hurtboxes in contact?
