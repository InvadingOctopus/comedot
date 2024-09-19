## Allows the Entity to be targetted by a player or another character's action which requires a target to be chosen,
## such as a special skill/spell like "Fireball", or a trivial command like "Examine".
## Requirements: Component must be [Node2D] to receive mouse events.
## @experimental

class_name ActionTargetableComponent
extends Component


#region Parameters
@export var isEnabled: bool = true
#endregion


#region State
#endregion


#region Signals
signal wasChosen
#endregion


#region Dependencies
#endregion


func _ready() -> void:
	if self.get_node(^".") is not Node2D:
		printWarning("Component is not Node2D")

	self.add_to_group(Global.Groups.targetables)
	parentEntity.add_to_group(Global.Groups.targetables)


func willRemoveFromEntity() -> void:
	super.willRemoveFromEntity()
	parentEntity.remove_from_group(Global.Groups.targetables)


func choose() -> bool:
	if checkConditions():
		self.wasChosen.emit()
		return true
	else:
		return false


## Overridden in subclass to specify any conditions.
func checkConditions() -> bool:
	# TODO: Add arguments to specify the chooser/action etc.
	return true


func onMouseEntered() -> void:
	parentEntity.modulate = Color.GREEN


func onMouseExited() -> void:
	parentEntity.modulate = Color.WHITE
