## Allows the Entity to be targetted by a player or another character's action which requires a target,
## such as a skill/spell like "Fireball", or a trivial command like "Examine".
## @experimental

class_name ActionTargetableComponent
extends Component


#region Parameters
@export var isEnabled: bool = true
#endregion


#region State
#endregion


#region Signals
#endregion


#region Dependencies
#endregion


func _ready() -> void:
    self.add_to_group(Global.Groups.targetables)
    parentEntity.add_to_group(Global.Groups.targetables)


func willRemoveFromEntity() -> void:
    super.willRemoveFromEntity()
    parentEntity.remove_from_group(Global.Groups.targetables)
