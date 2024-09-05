## Displays a button for one of the [Action]s that a playable character may perform.

class_name ActionButton
extends Button


#region Parameters

## An [Entity] with an [ActionsComponent] and [StatsComponent].
## If `null`, the first [member GameState.players] Entity will be used.
@export var entity: Entity

## The name of the [Action] to search from the [member Entity]'s [ActionsComponent].
@export var actionName: StringName:
	set(newValue):
		if newValue != actionName:
			actionName = newValue
			updateUI()

@export var shouldShowDebugInfo: bool = false
#endregion


#region State
var action: Action:
	get:
		if not action: action = actionsComponent.actions.front() # TODO: PLACEHOLDER
		return action
#endregion


#region Signals
signal didPressButton
#endregion


#region Dependencies
var player: PlayerEntity:
	get: return GameState.players.front()

var actionsComponent: ActionsComponent:
	get:
		if not actionsComponent: actionsComponent = entity.getComponent(ActionsComponent)
		return actionsComponent

var statsComponent: StatsComponent:
	get:
		if not statsComponent: statsComponent = entity.getComponent(StatsComponent)
		return statsComponent
#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not entity:
		entity = player
		if not entity: Debug.printWarning("Missing entity", str(self))
	
	updateUI()


func updateUI() -> void:
	pass


func onPressed() -> void:
	self.didPressButton.emit()
