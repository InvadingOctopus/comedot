## An entity which is also a [CharacterBody2D] and uses subclasses of [PhysicsComponentBase] to manipulate the physics body.
## Splits the [method Node._physics_process] method into 2 methods: [method PhysicsComponentBase.processPhysicsBeforeMove] and [method PhysicsComponentBase.processPhysicsAfterMove].
## These methods are called on each [PhysicsComponentBase] before and after the entity calls [method CharacterBodt2D.move_and_slide] (a function which must be called ONLY ONCE PER FRAME).
## This allows multiple components to coalescee and synchronize their physics updates.
## @experimental

@icon("res://Assets/Icons/Entity.svg")

class_name BodyEntity
extends Entity 


#region Parameters

## Include children of child nodes when performing physics updates on components.
## WARNING: May reduce performance.
# TBD: @export var includeInternalChildren: bool = false

#endregion


func _ready() -> void:
	self.body = self.get_node(^".") as CharacterBody2D

	
func _physics_process(delta: float) -> void:
	if self.components.is_empty(): return
	
	# DEBUG: print(Engine.get_frames_drawn())
	# printLog("_physics_process(): " + str(delta))
	
	for child in self.components.values():
		var physicsComponent: PhysicsComponentBase = child as PhysicsComponentBase
		if physicsComponent:
			# DEBUG: printDebug(str(physicsComponent, ".processPhysicsBeforeMove()"))
			
			physicsComponent.processPhysicsBeforeMove(delta)
			
	# DEBUG: printLog("move_and_slide")
	
	self.callOnceThisFrame(self.body.move_and_slide)
	
	# NOTE: Reget the components list instead of using a cached list,
	# in case components have been added or removed during the same frame.
	
	for child in self.components.values():
		var physicsComponent: PhysicsComponentBase = child as PhysicsComponentBase
		if physicsComponent:
			# DEBUG: printDebug(str(physicsComponent, ".processPhysicsAfterMove()"))
			
			physicsComponent.processPhysicsAfterMove(delta)
