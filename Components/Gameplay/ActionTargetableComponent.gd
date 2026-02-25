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
signal wasChosen  (action: Action, sourceEntity: Entity) # Emitted when this component's entity is CHOSEN for an [Action] via [ActionTargetingComponentBase] etc., but BEFORE the Action's [Payload] is executed.
signal wasTargeted(action: Action, sourceEntity: Entity, actionResult: Variant) # Emitted AFTER an [Action]'s [Payload] is executed with this component's entity as the target.
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
	parentEntity.remove_from_group(Global.Groups.targetables) # CHECK: Will this cause problems if there are somehow multiple ActionTargetableComponent subclasses on an Entity?


#region Action Targeting

## May be called by an [ActionTargetingComponent] BEFORE an [Action]'s [Payload] is executed.
func requestToChoose(action: Action = null, sourceEntity: Entity = null) -> bool:
	# DESIGN: The `action` & `sourceEntity` parameters are optional because most targets will not care,
	# but some targets may only accept or decline certain specific Actions.
	
	if not isEnabled: return false
	if debugMode: printLog(str("requestToChoose() action: ", (action.logName if action else "null"), ", sourceEntity: ", sourceEntity.logFullName if sourceEntity else "null"))
	
	if checkConditions(action, sourceEntity): # Arguments should be validated by checkConditions()
		self.wasChosen.emit(action, sourceEntity)
		return true
	else:
		if debugMode: printLog("checkConditions() failed!")
		return false


## Overridden in subclass to specify specific conditions, i.e. to potentially reject/refuse an [Action].
@warning_ignore("unused_parameter")
func checkConditions(action: Action = null, sourceEntity: Entity = null) -> bool:
	return self.isEnabled


## May be called by an targeted [Action] AFTER the [Action]'s [Payload] is successfully executed.
## May optionally return the result of a "reaction" or just nothing etc.
func didTarget(action: Action, sourceEntity: Entity, actionResult: Variant) -> Variant:
	if not isEnabled: return false
	wasTargeted.emit(action, sourceEntity, actionResult)
	return null

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
