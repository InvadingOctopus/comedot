## Creates an [ActionButton] for each [Action] in an [ActionsComponent].
## Attach this script to any [Container] [Control] such as a [GridContainer] or [HBoxContainer].
## @experimental

class_name ActionButtonsList
extends Container


#region Parameters

## An [Entity] with an [ActionsComponent] and a [StatsComponent] which will be used for validating and displaying each [Action] button.
## If `null`, the first [member GameState.players] Entity will be used.
@export var entity: Entity

@export var debugMode: bool = false
#endregion


#region State
var lastActionChosen: Action
#endregion


#region Signals
signal didChooseAction(action: Action)
#endregion


#region Dependencies

const actionButtonScene: PackedScene = preload("res://UI/Buttons/ActionButton.tscn") # TBD: load or preload?

var actionsComponent: ActionsComponent:
	get:
		if not actionsComponent: actionsComponent = entity.getComponent(ActionsComponent)
		return actionsComponent

var targetStatsComponent: StatsComponent:
	get:
		if not targetStatsComponent: targetStatsComponent = entity.getComponent(StatsComponent)
		return targetStatsComponent

var player: PlayerEntity:
	get: return GameState.players.front()

#endregion


func _ready() -> void:
	if not entity:
		entity = player
		if not entity: Debug.printWarning("Missing entity", self)

	if actionsComponent: readdAllActions()
	else: Debug.printWarning("Missing actionsComponent", self)


## Removes all children and adds all choices again.
func readdAllActions() -> void:
	Tools.removeAllChildren(self)
	for action in actionsComponent.actions:
		createActionButton(action)


func createActionButton(action: Action) -> Button:
	var newActionButton: ActionButton = actionButtonScene.instantiate()
	newActionButton.debugMode  = self.debugMode

	newActionButton.entity = self.entity
	newActionButton.action = action

	Tools.addChildAndSetOwner(newActionButton, self)

	newActionButton.updateUI() # TBD: Update before adding or after?
	newActionButton.pressed.connect(self.onActionButton_pressed.bind(action))

	return newActionButton


func onActionButton_pressed(action: Action) -> void:
	if debugMode: Debug.printDebug(str("onActionButton_pressed() ", action.logName), self)
	self.lastActionChosen = action
	self.didChooseAction.emit(action)
