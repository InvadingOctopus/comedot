## Receives player input and calls [method ActionsComponent.performAction] to perform an [Action].
## An [Action] may be a special skill like "Heal", or a spell like "Fireball", or a trivial command like "Examine".
## Some actions may require a target entity or object to chosen, and may cost a [Stat] to be used.
## If the [ActionsComponent] requests a target, then a subclass of [ActionTargetingComponentBase] is added to the Entity to prompt the player to choose a target.
## Requirements: [ActionsComponent]

class_name ActionControlComponent
extends Component


#region Parameters
## A subclass of [ActionTargetingComponentBase] to add to the parent [Entity] to present a UI to the player for choosing a target for [Action]s which require a target, such as a "Fireball" spell or a "Talk" command.
@export_file("*ActionTargeting*Component.tscn") var targetingComponentPath: String = "res://Components/Control/ActionTargetingMouseComponent.tscn" # Exclude the abstract "Base" components.

@export var isEnabled: bool = true
#endregion


#region State
#endregion


#region Signals
#endregion


#region Dependencies

@onready var actionsComponent: ActionsComponent = coComponents.ActionsComponent # TBD: Static or dynamic?

func getRequiredComponents() -> Array[Script]:
	return [ActionsComponent]

#endregion


#region Input & Execution

func _input(event: InputEvent) -> void:
	if not isEnabled or not event is InputEventAction: return
	if debugMode: printDebug(str("_input() ", event))

	# Just get an Action's name, if any, and forward it to ActionsComponent.performAction()

	var eventAction: InputEventAction = event as InputEventAction
	var eventName:   StringName = eventAction.action

	# Is it a "special" Action? # TBD: Less ambiguous name? :')
	if not eventName.begins_with(GlobalInput.Actions.specialActionPrefix): return

	var actionName: StringName = eventName.trim_prefix(GlobalInput.Actions.specialActionPrefix)
	actionsComponent.performAction(actionName)

#endregion


#region Target Selection

func _ready() -> void:
	Tools.connectSignal(actionsComponent.didRequestTarget, self.onActionsComponent_didRequestTarget)


func onActionsComponent_didRequestTarget(action: Action, source: Entity) -> void:
	if debugMode: printDebug(str("onActionsComponent_didRequestTarget() ", action, ", source: ", source))
	if source == self.parentEntity: createTargetingComponent(action) # Create & add a component which prompt the player to choose a target.
	else: printDebug(str("Action source: ", source, " is not parentEntity: ", parentEntity))


func createTargetingComponent(actionToPerform: Action) -> ActionTargetingComponentBase:
	var componentScene: PackedScene = load(targetingComponentPath)
	var targetingComponent: ActionTargetingComponentBase = componentScene.instantiate()

	if not targetingComponent:
		printWarning(str("Cannot instantiate an instance of ActionTargetingComponentBase: ", targetingComponentPath))
		return null

	targetingComponent.action = actionToPerform
	parentEntity.addComponent(targetingComponent)
	# GlobalUI.actionDidRequestTarget.emit(actionToPerform, parentEntity) # This should be emitted by ActionsComponent next to its `didRequestTarget` as that's the first point where a target is requested.
	return targetingComponent

#endregion
