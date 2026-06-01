## Allows the Entity to be targeted by a player or another character's [AbilityTargetingComponentBase] which requires a target to be chosen,
## for an [Ability] such as a special skill/spell like "Fireball", or a trivial command like "Examine".
## Requirements: Component must be [Node2D] to receive mouse events.
## @experimental

class_name AbilityTargetableComponent
extends AreaComponentBase


#region Parameters
## Highlight even when not being targeted by an [AbilityTargetingComponentBase] subclass?
@export var shouldAlwaysHighlightOnMouseHover: bool = false:
	set(newValue):
		if newValue != shouldAlwaysHighlightOnMouseHover:
			shouldAlwaysHighlightOnMouseHover = newValue
			updateMouseHover()

@export var isEnabled: bool = true
#endregion


#region Signals
signal wasChosen  (ability: Ability, sourceEntity: Entity) # Emitted when this component's entity is CHOSEN for an [Ability] via [AbilityTargetingComponentBase] etc., but BEFORE the Ability's [Payload] is executed.
signal wasTargeted(ability: Ability, sourceEntity: Entity, abilityResult: Variant) # Emitted AFTER an [Ability]'s [Payload] is executed with this component's entity as the target.
#endregion


func _ready() -> void:
	if self.get_node(^".") is not Node2D:
		printWarning("Component is not Node2D")

	selfAsArea.monitoring = false # This [Area2D] does not need to monitor any other areas; it only needs to be `monitorable`

	self.add_to_group(Global.Groups.targetables)
	entity.add_to_group(Global.Groups.targetables)
	updateMouseHover()


func onWillUninstall() -> void:
	entity.remove_from_group(Global.Groups.targetables) # CHECK: Will this cause problems if there are somehow multiple AbilityTargetableComponent subclasses on an Entity?


#region Ability Targeting

## May be called by an [AbilityTargetingComponentBase] subclass BEFORE an [Ability]'s [Payload] is executed.
func requestToChoose(ability: Ability = null, sourceEntity: Entity = null) -> bool:
	# DESIGN: The `ability` & `sourceEntity` parameters are optional because most targets will not care,
	# but some targets may only accept or decline certain specific Abilities.
	
	if not isEnabled: return false
	if debugMode: printLog(str("requestToChoose() ability: ", (ability.logName if ability else "null"), ", sourceEntity: ", sourceEntity.logFullName if sourceEntity else "null"))
	
	if checkConditions(ability, sourceEntity): # Arguments should be validated by checkConditions()
		self.wasChosen.emit(ability, sourceEntity)
		return true
	else:
		if debugMode: printLog("checkConditions() failed!")
		return false


## Overridden in subclass to specify specific conditions, i.e. to potentially reject/refuse an [Ability].
@warning_ignore("unused_parameter")
func checkConditions(ability: Ability = null, sourceEntity: Entity = null) -> bool:
	return self.isEnabled


## May be called by an targeted [Ability] AFTER the [Ability]'s [Payload] is successfully executed.
## May optionally return the result of a "reaction" or just nothing etc.
func didTarget(ability: Ability, sourceEntity: Entity, abilityResult: Variant) -> Variant:
	if not isEnabled: return false
	wasTargeted.emit(ability, sourceEntity, abilityResult)
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
	entity.modulate = Color.GREEN if highlight else Color.WHITE

#endregion
