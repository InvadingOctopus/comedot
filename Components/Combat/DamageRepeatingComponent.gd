## A [Timer] counterpart to [DamageComponent] that repeatedly applies the [member DamageComponent.damageOnCollision] as long as an opposing entity's [DamageReceivingComponent] [Area2D] "hurtbox" remains in contact.
## Add this component to entities representing hazards like pools of acid etc. or turrets etc. with [BulletlessGunComponent]
## NOTE: The damage is applied to ALL opposing [DamageReceivingComponent]s in contact AT THE SAME TIME, regardless of WHEN they collided.
## TIP: For attacks such as a poison arrow etc. that must apply some lingering damage, add [DamageOverTimeComponent] to the "VICTIM" entity instead.
## Requirements: [DamageComponent]
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
			if self.is_node_ready():
				Tools.toggleSignal(damageComponent.didCollideReceiver, self.onDamageComponent_didCollideReceiver, self.shouldStartOnCollision)
				# TBD: DESIGN: Wait for next collision or start now in case already in contact?
				# if shouldStartOnCollision: startTimer()


## Restarts the [member timer] if re-enabled while a [DamageReceivingComponent] is in contact.
func setIsEnabled(newValue: bool) -> void:
	var wasEnabled: bool = isEnabled
	super.setIsEnabled(newValue)
	if not wasEnabled and isEnabled and self.is_node_ready(): startTimer()

#endregion


#region Signals
signal didTick(damageReceivingComponentsInContact: Array[DamageReceivingComponent]) ## Emitted only if [member damageReceivingComponentsInContact] is not empty.
#endregion


#region Dependencies
@onready var damageComponent: DamageComponent = coComponents.DamageComponent # TBD: Include subclasses?
func getRequiredComponents() -> Array[Script]: return [DamageComponent]
#endregion


#region Events

func _ready() -> void:
	# Just in case...
	timer.autostart = false
	timer.stop()

	# Apply setters because Godot doesn't on _ready()
	Tools.toggleSignal(damageComponent.didCollideReceiver, self.onDamageComponent_didCollideReceiver, self.shouldStartOnCollision)
	Tools.connectSignal(damageComponent.didLeaveReceiver,  self.onDamageComponent_didLeaveReceiver)
	startTimer() # In case the [DamageComponent] is already be in contact with hitboxes, if this component was added dynamically.


func onDamageComponent_didCollideReceiver(_damageReceivingComponent: DamageReceivingComponent) -> void:
	startTimer()


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

#endregion


## Starts the [member timer] if [member shouldStartOnCollision] and [member DamageComponent.damageReceivingComponentsInContact] is not empty.
## NOTE: Skipped if [member DamageComponent.shouldRemoveEntityOnCollision] e.g. for bullets.
func startTimer() -> void:
	# If we're getting removed, we can't repeat damage anyway
	if not isEnabled or not shouldStartOnCollision or not timer.is_stopped() \
	or self.is_queued_for_deletion() or entity.is_queued_for_deletion() \
	or damageComponent.shouldRemoveEntityOnCollision \
	or damageComponent.damageReceivingComponentsInContact.is_empty():
		return

	timer.start()
	if debugMode: emitDebugBubble("HIT TIMER ON", randomDebugColor, true) # emitFromEntity
