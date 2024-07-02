## Base class for components which manipulate a [CharacterBody2D] before and after it moves during each frame.
## Splits the [method Node._physics_process] method into 2 methods: [method PhysicsComponentBase.processPhysicsBeforeMove] and [method PhysicsComponentBase.processPhysicsAfterMove].
## Those methods are called on each [PhysicsComponentBase] by [method CharacterBodyEntity._physics_process] before and after the entity calls [method CharacterBodt2D.move_and_slide] (a function which must be called ONLY ONCE PER FRAME).
## This allows multiple components to coalescee and synchronize their physics updates.
## @experimental

class_name PhysicsComponentBase
extends BodyComponent


## Called before [method CharacterBody2D.move_and_slide]
## Must be overridden by subclasses.
func processPhysicsBeforeMove(delta: float) -> void:
	pass
	

## Called after [method CharacterBody2D.move_and_slide]	
## Must be overridden by subclasses.
func processPhysicsAfterMove(delta: float) -> void:
	pass
