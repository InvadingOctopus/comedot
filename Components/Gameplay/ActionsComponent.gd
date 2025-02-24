## Stores a list of gameplay actions which an Entity such as the player character or an NPC may perform.
## The actions may cost a Stat Resource when used and may require a target to be chosen,
## such as a special skill/spell like "Fireball", or a trivial command like "Examine".
## To perform an Action in response to player control, use [ActionControlComponent].
## Requirements: [StatsComponent] to perform Actions which have a Stat cost.
## @experimental

class_name ActionsComponent
extends Component


#region Parameters

## The list of available actions that the Entity may choose to perform.
@export var actions: Array[Action]

## A subclass of [ActionTargetingComponentBase] to add to the parent [Entity] to present a UI to the player for choosing a target for [Action]s which require a target, such as a "Fireball" spell or a "Talk" command.
@export_file("*ActionTargeting*Component.tscn") var targetingComponentPath: String # Exclude the abstract "Base" components.

@export var isEnabled: bool = true

#endregion


#region State
@export_storage var actionsOnCooldown: Array[Action]
#endregion


#region Signals

## Emitted if the [Action] [member Action.requiresTarget] but a target has not been provided for [method perform].
## May be handled by game-specific UI to prompt the player to choose a target for the Action.
## NOTE: If an Action is to be performed via this component's [method perform] then this signal is emitted by the [ActionsComponent] ONLY; [signal Action.didRequestTarget] will NOT be emitted.
signal didRequestTarget(action: Action, source: Entity)

signal willPerformAction(action: Action)
signal didPerformAction(action: Action, result: Variant)
#endregion


#region Dependencies
@onready var statsComponent: StatsComponent = coComponents.StatsComponent # TBD: Static or dynamic?
#endregion


func _ready() -> void:
	connectSignals()


#region Interface

## Returns the first [Action] with the matching name from the [member actions] array.
func findAction(nameToSearch: StringName) -> Action:
	# TBD: Use `Array.any()`?
	for action in self.actions:
		if action.name == nameToSearch: return action

	printDebug("Cannot find Action named: " + nameToSearch)
	return null


## Returns the result of the [Action]'s [member Action.payload], or `false` if the Action or a required [param target] is missing.
## To perform Actions in response to player control, use [ActionControlComponent].
func performAction(actionName: StringName, target: Entity = null) -> Variant:
	var actionToPerform: Action = self.findAction(actionName)
	if shouldShowDebugInfo: printLog(str("performAction(): ", actionName, " (", actionToPerform.logName, ") target: ", target))
	if not actionToPerform: return false

	# Check for target
	if actionToPerform.requiresTarget and target == null:
		if shouldShowDebugInfo: printDebug("Missing target")
		createTargetingComponent(actionToPerform) # Create & add a component which prompt the player to choose a target.
		self.didRequestTarget.emit(actionToPerform, self.parentEntity)
		# TBD: ALSO emit the Action's signal?
		# What would be the behavior expected by objects connecting to these signals? If an ActionsComponent is used, then it is the ActionsComponent requesting a target, right? The Action should not also request a target, to avoid UI duplication, right?
		return false

	# Get the Stat to pay the Action's cost with, if any,
	var statToPayWith: Stat = actionToPerform.getPaymentStatFromStatsComponent(statsComponent)

	self.willPerformAction.emit(actionToPerform)
	var result: Variant = actionToPerform.perform(statToPayWith, self.parentEntity, target)

	if result: # Must not be `null` and not `false`
		self.didPerformAction.emit(actionToPerform, result)

	return result


func createTargetingComponent(actionToPerform: Action) -> ActionTargetingComponentBase:
	var componentScene: PackedScene = load(targetingComponentPath)
	var targetingComponent: ActionTargetingComponentBase = componentScene.instantiate()
	
	if not targetingComponent:
		printWarning(str("Cannot instantiate an instance of ActionTargetingComponentBase: ", targetingComponentPath))
		return null
	
	targetingComponent.action = actionToPerform
	parentEntity.addComponent(targetingComponent)
	GlobalUI.actionDidRequestTarget.emit(actionToPerform, parentEntity)
	return targetingComponent

#endregion


#region Cooldowns

func connectSignals() -> void:
	for action in self.actions:
		Tools.reconnectSignal(action.didStartCooldown,  self.onAction_didStartCooldown.bind(action))
		Tools.reconnectSignal(action.didFinishCooldown, self.onAction_didFinishCooldown.bind(action))
	

func onAction_didStartCooldown(action: Action) -> void:
	self.actionsOnCooldown.append(action)
	self.set_process(true) # PERFORMANCE: Update per-frame only when needed


func onAction_didFinishCooldown(action: Action) -> void:
	self.actionsOnCooldown.erase(action)
	if self.actionsOnCooldown.is_empty(): self.set_process(false) # PERFORMANCE: Update per-frame only when needed


func _process(delta: float) -> void:
	if not isEnabled or self.actionsOnCooldown.is_empty(): return
	for action in actionsOnCooldown:
		action.cooldownRemaining -= delta

#endregion
