## Base class for components which manipulate a [CharacterBody2D] before and after it moves during each frame.
## Splits the [method Node._physics_process] method into 2 methods: [method PhysicsComponentBase.processBodyBeforeMove] and [method PhysicsComponentBase.processBodyAfterMove].
## Those methods are called on each [PhysicsComponentBase] by [method CharacterBodyEntity._physics_process] before and after the entity calls [method CharacterBodt2D.move_and_slide] (a function which must be called ONLY ONCE PER FRAME).
## This allows multiple components to coalescee and synchronize their physics updates.
## @experimental

class_name PhysicsComponentBase
extends Component


#region Parameters

## If `null` then it will be acquired from the parent [Entity] on [method _enter_tree()]
@export var body: CharacterBody2D:
	get:
		if body == null and not skipFirstWarning:
			printWarning("body is null! Call parentEntity.getBody() to find and remember the Entity's CharacterBody2D")
		return body

#endregion


#region State
## This avoids the superfluous warning when checking the [member body] for the first time in [method _enter_tree()].
var skipFirstWarning := true
#endregion


# Called whenever the node enters the scene tree.
func _enter_tree() -> void:
	super._enter_tree()
	
	if self.body == null and parentEntity != null:
		self.body = parentEntity.getBody()
	
	if not body:
		printError("Missing CharacterBody2D in parent Entity: \n" + parentEntity.logFullName)

	skipFirstWarning = false


#region Abstract Methods to Override

## Called before [method CharacterBody2D.move_and_slide]
## Must be overridden by subclasses.
func processBodyBeforeMove(delta: float) -> void:
	pass
	

## Called after [method CharacterBody2D.move_and_slide]	
## Must be overridden by subclasses.
func processBodyAfterMove(delta: float) -> void:
	pass

#endregion
