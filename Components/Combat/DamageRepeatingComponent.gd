## A variant of [DamageComponent] that repeatedly applies its [member damageOnCollision] as long as an opposing entity's [DamageReceivingComponent] [Area2D] "hurtbox" remains in contact.
## Enable "Editable Children" to change the $RepetitionTimer duration, default: Every 1 second.
## Add this component to entities representing hazards like pools of acid etc.
## NOTE: The damage is applied to ALL opposing [DamageReceivingComponent]s in contact AT THE SAME TIME, regardless of WHEN they collided.
## TIP: For attacks such as a poison arrow etc. that must apply some lingering damage, add [DamageOverTimeComponent] to the "VICTIM" entity instead.
## Requirements: This component must be an [Area2D] or connected to signals from an [Area2D] representing the "hitbox".
## @experimental

class_name DamageRepeatingComponent
extends DamageComponent

# TBD: A way to offset the damage time based on WHEN the hurtboxes came in contact?


#region Dependencies
## This [Timer] is started when the first [DamageReceivingComponent] hurtbox comes in contact, and stopped when the last hurtbox leaves contact.
@onready var repetitionTimer: Timer = $RepetitionTimer
#endregion


func _ready() -> void:
	# Just in case...
	repetitionTimer.autostart = false
	repetitionTimer.stop()
	Tools.connectSignal(self.didCollideReceiver, self.onDidCollideReceiver)
	Tools.connectSignal(self.didLeaveReceiver,   self.onDidLeaveReceiver)


## Starts the [member repetitionTimer] if it's not already on.
func onDidCollideReceiver(_damageReceivingComponent: DamageReceivingComponent) -> void:
	if not isEnabled: return
	if repetitionTimer.is_stopped(): repetitionTimer.start()


## Stops the [member repetitionTimer] if there are no [DamageReceivingComponent] hurtboxes in contact.
## Does not care about [member isEnabled]
func onDidLeaveReceiver(_damageReceivingComponent: DamageReceivingComponent) -> void:
	if not isEnabled: return
	if self.damageReceivingComponentsInContact.is_empty(): repetitionTimer.stop()


func onRepetitionTimer_timeout() -> void:
	self.causeDamageToAllReceivers()
