## Receives player input and calls [method ActionsComponent.performAction] to perform an [Action].
## An [Action] may be a special skill like "Heal", or a spell like "Fireball", or a trivial command like "Examine".
## Some actions may require a target entity or object to chosen, and may cost a [Stat] to be used.
## Requirements: [ActionsComponent]
## @experimental

class_name ActionControlComponent
extends Component

# TODO: Prompt player to choose a target if required


#region Parameters
@export var isEnabled: bool = true
#endregion


#region State
#endregion


#region Signals
#endregion


#region Dependencies

var actionsComponent: ActionsComponent:
	get:
		if not actionsComponent: actionsComponent = self.getCoComponent(ActionsComponent)
		return actionsComponent

## Returns a list of required component types that this component depends on.
func getRequiredcomponents() -> Array[Script]:
	return [ActionsComponent]

#endregion


#region Input & Execution

func _input(event: InputEvent) -> void:
	if not isEnabled or not event is InputEventAction: return
	if shouldShowDebugInfo: printDebug(str("_input() ", event))

	# Just get an Action's name, if any, and forward it to ActionsComponent.performAction()

	var eventAction: InputEventAction = event as InputEventAction
	var eventName:   StringName = eventAction.action

	# Is it a "special" Action? # TBD: Less ambiguous name? :')
	if not eventName.begins_with(GlobalInput.Actions.specialActionPrefix): return

	var actionName: StringName = eventName.trim_prefix(GlobalInput.Actions.specialActionPrefix)
	actionsComponent.performAction(actionName)

#endregion
