## Displays a button for one of the [Action]s that a playable character may perform.
## @experimental

class_name ActionButton
extends Button

# TBD: Use `action.name` to search within an `ActionsComponent`?


#region Parameters

## An [Entity] with an [ActionsComponent] and [StatsComponent].
## If `null`, the first [member GameState.players] Entity will be used.
@export var entity: Entity

@export var action: Action:
	set(newValue):
		if newValue != action:
			action = newValue
			updateUI()

@export var shouldShowDebugInfo: bool = false
#endregion


#region State
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
	
	if action: updateUI()


func updateUI() -> void:
	self.text = action.displayName
	self.icon = action.icon
	self.tooltip_text = action.description
	self.disabled = not checkUsability()


## Checks if the [member entity]'s [StatsComponent] has the [Stat] required to perform the [member action].
func checkUsability() -> bool:
	return action.validateStatsComponent(statsComponent)


func onPressed() -> void:
	if shouldShowDebugInfo: Debug.printDebug("onPressed()", str(self))
	self.didPressButton.emit()
