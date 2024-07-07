## An entity which is also a [CharacterBody2D] and uses subclasses of [PhysicsComponentBase] to manipulate the physics body.
## Splits the [method Node._physics_process] method into 2 methods: [method PhysicsComponentBase.processPhysicsBeforeMove] and [method PhysicsComponentBase.processPhysicsAfterMove].
## These methods are called on each [PhysicsComponentBase] before and after the entity calls [method CharacterBodt2D.move_and_slide] (a function which must be called ONLY ONCE PER FRAME).
## This allows multiple components to coalescee and synchronize their physics updates.
## @experimental

@icon("res://Assets/Icons/Entity.svg")

class_name CharacterBodyEntity
extends Entity 


#region Parameters

## Include children of child nodes when performing physics updates on components.
## WARNING: May reduce performance.
# TBD: @export var includeInternalChildren: bool = false

#endregion


#region State
#endregion


func _ready() -> void:
	self.body = self.get_node(^".") as CharacterBody2D
	if not body:
		printError("CharacterBodyEntity script not attached to a CharacterBody2D node!")


func _physics_process(delta: float) -> void:
	if self.components.is_empty(): return
	
	var physicsComponent: PhysicsComponentBase
	
	# DEBUG: printLog("_physics_process(): " + str(delta))
	
	# TBD: PERFORMANCE: Which is faster? Iterating through dictionary keys or values?
	# for child in self.components.values():
	# or
	# for key: StringName in self.components.keys():
	
	for key: StringName in self.components.keys():
		physicsComponent = self.components[key] as PhysicsComponentBase
		if physicsComponent:
			# DEBUG: printDebug(str(physicsComponent, ".processPhysicsBeforeMove()"))
			
			physicsComponent.processPhysicsBeforeMove(delta)
		# physicsComponent = null # Dhould be nulled by prior assignment
			
	# DEBUG: printDebug("move_and_slide")
	
	self.callOnceThisFrame(self.body.move_and_slide)
	
	# NOTE: Reget the components list instead of using a cached list,
	# in case components have been added or removed during the same frame.
	
	for key: StringName in self.components.keys():
		physicsComponent = self.components[key] as PhysicsComponentBase
		if physicsComponent:
			# DEBUG: printDebug(str(physicsComponent, ".processPhysicsAfterMove()"))
			
			physicsComponent.processPhysicsAfterMove(delta)
		# physicsComponent = null # Dhould be nulled by prior assignment
