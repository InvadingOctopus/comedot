## Presents a mouse-controlled cursor and other UI for the player to choose a target for an [Action].
## The [Action] may be a special skill or magic spell etc. such as "Fireball", which may be targeted anywhere,
## or it may be an explicit command like "Talk" or "Examine" which requires the target to be an [Entity] with an [ActionTargetableComponent].
## @experimental

class_name ActionTargetingMouseComponent
extends ActionTargetingCursorComponentBase


#region Parameters
#endregion


#region State
#endregion


#region Signals
#endregion


#region Dependencies
#endregion


func _ready() -> void:
	super._ready()
	self.global_position = parentEntity.get_global_mouse_position()


func _process(_delta: float) -> void:
	if not isEnabled or not isChoosing: return
	self.global_position = parentEntity.get_global_mouse_position()
