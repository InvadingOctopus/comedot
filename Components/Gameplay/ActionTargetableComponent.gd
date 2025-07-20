## Allows the Entity to be targeted by a player or another character's [ActionTargetingComponentBase] which requires a target to be chosen,
## for an [Action] such as a special skill/spell like "Fireball", or a trivial command like "Examine".
## Requirements: Component must be [Node2D] to receive mouse events.
## @experimental

class_name ActionTargetableComponent
extends AreaComponentBase


#region Parameters
## Highlight even when not being targeted by an [ActionTargetingComponent]?
@export var shouldAlwaysHighlightOnMouseHover: bool = false:
	set(newValue):
		if newValue != shouldAlwaysHighlightOnMouseHover:
			shouldAlwaysHighlightOnMouseHover = newValue
			updateMouseHover()

@export var isEnabled: bool = true
#endregion


#region Signals
signal wasChosen(action: Action, sourceEntity: Entity)
#endregion


func _ready() -> void:
	if self.get_node(^".") is not Node2D:
		printWarning("Component is not Node2D")

	selfAsArea.monitoring = false # This [Area2D] does not need to monitor any other areas; it only needs to be `monitorable`

	self.add_to_group(Global.Groups.targetables)
	parentEntity.add_to_group(Global.Groups.targetables)
	connectSignals()
	updateMouseHover()


func connectSignals() -> void:
	self.willRemoveFromEntity.connect(self.onWillRemoveFromEntity)


func onWillRemoveFromEntity() -> void:
	parentEntity.remove_from_group(Global.Groups.targetables)


#region Action Targeting

## May be called by an [ActionTargetingComponent].
func requestToChoose(action: Action = null, sourceEntity: Entity = null) -> bool:
	# DESIGN: The `action` & `sourceEntity` parameters are optional because most targets will not care,
	# but some targets may only accept or decline certain specific Actions.
	if debugMode: printLog(str("requestToChoose() action: ", action.logName, ", sourceEntity: ", sourceEntity.logFullName))
	if checkConditions(action, sourceEntity):
		self.wasChosen.emit(action, sourceEntity)
		return true
	else:
		if debugMode: printLog("checkConditions() failed!")
		return false


## Overridden in subclass to specify any conditions.
@warning_ignore("unused_parameter")
func checkConditions(action: Action = null, sourceEntity: Entity = null) -> bool:
	return self.isEnabled

#endregion


#region Mouse Hover

func updateMouseHover() -> void:
	self.input_pickable = shouldAlwaysHighlightOnMouseHover
	if isEnabled and shouldAlwaysHighlightOnMouseHover: connectMouseSignals()
	else: disconnectMouseSignals()


func connectMouseSignals() -> void:
	Tools.connectSignal(selfAscollisionObject.mouse_entered, setHighlight.bind(true))
	Tools.connectSignal(selfAscollisionObject.mouse_exited, setHighlight.bind(false))


func disconnectMouseSignals() -> void:
	Tools.disconnectSignal(selfAscollisionObject.mouse_entered, setHighlight.bind(true))
	Tools.disconnectSignal(selfAscollisionObject.mouse_exited, setHighlight.bind(false))


func setHighlight(highlight: bool = true) -> void:
	parentEntity.modulate = Color.GREEN if highlight else Color.WHITE

#endregion
