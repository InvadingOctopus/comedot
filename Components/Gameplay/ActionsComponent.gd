## Stores a list of gameplay actions which an Entity such as the player character or an NPC may perform.
## The actions may cost a Stat Resource when used and may require a target to be chosen,
## such as a special skill/spell like "Fireball", or a trivial command like "Examine".
## Requirements: [StatsComponent] to perform Actions which have a Stat cost.
## @experimental

class_name ActionsComponent
extends Component


#region Parameters
## The list of available actions that the Entity may choose to perform.
@export var actions: Array[Action]

@export var isEnabled: bool = true
#endregion


#region State
#endregion


#region Signals
signal willDoAction(action: Action)
signal didDoAction(action: Action)
#endregion


#region Dependencies

var statsComponent: StatsComponent: ## Placeholder
	get:
		if not statsComponent: statsComponent = self.getCoComponent(StatsComponent)
		return statsComponent

#endregion


#region Interface

## Returns the first [Action] with the matching name from the [member actions] array.
func findAction(nameToSearch: StringName) -> Action:
	# TBD: Use `Array.any()`?
	for action in self.actions:
		if action.name == nameToSearch: return action

	printDebug("Cannot find Action named: " + nameToSearch)
	return null


func performAction(actionName: StringName, target: Entity = null) -> void:
	if shouldShowDebugInfo: printLog(str("performAction(): " + actionName, ", target: ", target))

	var actionToPerform: Action = self.findAction(actionName)
	if not actionToPerform: return

	actionToPerform.perform(self.parentEntity)

#endregion


#region Input & Execution

func _input(event: InputEvent) -> void:
	# TBD: A better implementation?

	if not event is InputEventAction: return

	var eventAction: InputEventAction = event as InputEventAction
	var eventName:   StringName = eventAction.action

	# Is it a "special" Action? # TBD: Less ambiguous name? :')
	if not eventName.begins_with(GlobalInput.Actions.specialActionPrefix): return

	var actionName: StringName = eventName.trim_prefix(GlobalInput.Actions.specialActionPrefix)
	var action: Action = self.findAction(actionName)

	if not action: return

	# TODO: Handle target acquisition

	action.payload.execute(self.parentEntity, null)

#endregion

