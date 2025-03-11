## Adds or removes a specified set of components, or removes the parent Entity itself, after the supplied [Timer] times out.
## NOTE: By default, the `$InternalTimer` child of this component performs ALL actions after 3 seconds, in order:
## [method removeEntity] if [member shouldRemoveEntity] → [method removeNodes] → [method removeComponents] → [method createComponents]
## To use a different time for each of those tasks, enable `Editable Children` and disable `$InternalTimer`, then connect any other [Timer] to any of those methods.
## TIP: To add/remove nodes based on physics collisions, use [ModifyOnCollisionComponent]
## TIP: EXAMPLE: For entities like arrows that should get stuck in walls etc. then be removed after a few seconds,
## use a [ModifyOnCollisionComponent] to add a [ModifyOnTimerComponent] to the entity,
## then connect the [signal ModifyOnCollisionComponent.didEnterBody] to the $InternalTimer of [ModifyOnTimerComponent] and choose the Timer's [method Timer.start] method,
## and UNBIND 1 signal argument so that the collision event's `body` argument does not get passed to the Timer's `time` float parameter.

class_name ModifyOnTimerComponent
extends NodeModifierComponentBase


func onInternalTimer_timeout() -> void:
	super.performAllModifications()
 