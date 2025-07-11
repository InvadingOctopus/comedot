## Stores a list of special gameplay actions which an Entity such as the player character or an NPC may explicitly choose to perform.
## Actions may be special skills/spells like "Fireball", or trivial commands like "Examine".
## An Action may cost a [Stat] Resource when used and may require a target to be chosen.
## To perform an Action in response to player control, use [ActionControlComponent].
## To display UI buttons for Actions, use [ActionButtons] & [ActionButtonsList].
## TIP: To execute Actions via keyboard shortcuts or gamepad buttons, edit the Project Settings' Input Map,
## and add Godot input actions with names matching [member GlobalInput.Actions.specialActionPrefix] + [member Action.name] e.g. `specialAction_dash`.
## Requirements: [StatsComponent] to perform Actions which have a Stat cost.

class_name ActionsComponent
extends Component


#region Parameters
@export var actions: Array[Action] ## The list of available [Action]s that the Entity may choose to perform.
@export var isEnabled: bool = true
#endregion


#region State
@export_storage var actionsOnCooldown: Array[Action]
#endregion


#region Signals

## Emitted if the [Action] [member Action.requiresTarget] but a target has not been provided for [method perform].
## Handled by [ActionControlComponent] to provide game-specific UI for prompting the player to choose a target for the Action.
## NOTE: If an Action is to be performed via this component's [method perform] then this signal is emitted by the [ActionsComponent] ONLY; [signal Action.didRequestTarget] will NOT be emitted.
signal didRequestTarget(action: Action, source: Entity)

signal willPerformAction(action: Action)
signal didPerformAction(action: Action, result: Variant)

#endregion


#region Dependencies
@onready var statsComponent: StatsComponent = coComponents.get(&"StatsComponent")
#endregion


func _ready() -> void:
	createCooldownsList() # Check if any Actions were already in cooldown when they were added to this component
	connectSignals() # Then connect signals for future cooldown updates


#region Interface

## Returns the first [Action] with the matching name from the [member actions] array.
func findAction(nameToSearch: StringName) -> Action:
	# TBD: Use `Array.any()`?
	# TBD: PERFORMANCE: Use a Dictionary to cache Name:Action?
	# TBD: PERFORMANCE: Should we to_lower() to avoid any typo bugs? Or is that a bad idea for StringName?

	for action in self.actions:
		if action.name == nameToSearch: return action

	printDebug("Cannot find Action named: " + nameToSearch)
	return null


## Returns an [Action] that matches an [InputEvent] shortcut.
## i.e. the first [Action] from this component's [member actions] array where
## [member GlobalInput.Actions.specialActionPrefix] + [member Action.name] returns `true` for [method InputEvent.is_action]
## For example `specialAction_dash`.
## This method is called by [ActionControlComponent] to handle keyboard/gamepad/etc. shortcuts for special Actions.
func findActionForInputEvent(inputEvent: InputEvent) -> Action:
	# NOTE: GRR: Dummy Godot does not seem to have a way to get all the matching Godot Input Action from an InputEvent,
	# so we have to try all the [special/explicit] Actions we have and ask Godot whether an InputEvent matches any of them.

	if debugMode: printDebug(str("findActionForInputEvent(): ", inputEvent))
	var inputActionName: StringName
	for action in self.actions:
		inputActionName = GlobalInput.Actions.specialActionPrefix + action.name
		if InputMap.has_action(inputActionName) and inputEvent.is_action(inputActionName): # Check InputMap.has_action() to avoid a dumb Godot error
			if debugMode: printDebug(str("First match: ", action.logName))
			return action
	return null


## Returns the result of the [Action]'s [member Action.payload], or `false` if the Action or a required [param target] is missing.
## To perform Actions in response to player control and handle targeting, use [ActionControlComponent].
func performAction(actionName: StringName, target: Entity = null) -> Variant:
	# TBD: PERFORMANCE: Use a Dictionary to cache Name:Action?
	# TBD: PERFORMANCE: Should we to_lower() to avoid any typo bugs? Or is that a bad idea for StringName?
	var actionToPerform: Action = self.findAction(actionName)
	if debugMode: printLog(str("performAction(): ", actionName, " (", actionToPerform.logName, ") target: ", target))
	if not actionToPerform: return false

	# Check for target
	if actionToPerform.requiresTarget and target == null:
		if debugMode: printDebug("Missing target")
		self.didRequestTarget.emit(actionToPerform, self.parentEntity) # To be handled by ActionControlComponent
		GlobalUI.actionDidRequestTarget.emit(actionToPerform, self.parentEntity) # This should be emitted here next to `didRequestTarget` as this is the first point where a target is requested, not ActionControlComponent.
		# TBD: ALSO emit the Action's signal?
		# What would be the behavior expected by objects connecting to these signals? If an ActionControlComponent is used, then it is the ActionControlComponent requesting a target, right? The Action should not also request a target, to avoid UI duplication, right?
		return false

	# TBD: Refund Stat cost if Action fails?

	# Get the Stat to pay the Action's cost with, if any,
	var statToPayWith: Stat = actionToPerform.getPaymentStatFromStatsComponent(statsComponent)

	self.willPerformAction.emit(actionToPerform)
	var result: Variant = actionToPerform.perform(statToPayWith, self.parentEntity, target)

	if Tools.checkResult(result): # Must not be `null` and not `false` and not an empty collection
		self.didPerformAction.emit(actionToPerform, result)

	return result

#endregion


#region Cooldowns

## Resets the [member actionsOnCooldown] array and checks each [Action] in the [member actions] array,
## adding it to [member actionsOnCooldown] if [member Action.isInCooldown].
## The cooldowns list is used by [method _process] to countdown the cooldown time of each Action on every frame.
func createCooldownsList() -> void:
	self.actionsOnCooldown.clear()
	for action in self.actions:
		if action.isInCooldown: self.actionsOnCooldown.append(action)
	self.set_process(not self.actionsOnCooldown.is_empty()) # PERFORMANCE: Update per-frame only if needed


func connectSignals() -> void:
	for action in self.actions:
		Tools.connectSignal(action.didStartCooldown,  self.onAction_didStartCooldown.bind(action))
		Tools.connectSignal(action.didFinishCooldown, self.onAction_didFinishCooldown.bind(action))


func onAction_didStartCooldown(action: Action) -> void:
	self.actionsOnCooldown.append(action)
	self.set_process(true) # Start per-frame updates


func onAction_didFinishCooldown(action: Action) -> void:
	self.actionsOnCooldown.erase(action)
	if self.actionsOnCooldown.is_empty(): self.set_process(false) # PERFORMANCE: Do not update per-frame anymore


func _process(delta: float) -> void:
	# NOTE: PERFORMANCE: Update per-frame only when needed: Call `self.set_process()` whenever `actionsOnCooldown` is modified.
	if not isEnabled or self.actionsOnCooldown.is_empty(): return
	for action in actionsOnCooldown:
		action.cooldownRemaining -= delta

#endregion
