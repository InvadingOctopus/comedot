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
			if self.is_node_ready(): updateUI()

@export var shouldShowDebugInfo: bool

#endregion


#region State
#endregion


#region Signals
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

@onready var cooldownBar: ProgressBar = $CooldownBar
#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not entity:
		entity = player
		if not entity: Debug.printWarning("Missing entity", self)

	if action:
		connectSignals()
		updateUI()

	self.set_process(false) # PERFORMANCE: Update per-frame only when needed


func updateUI() -> void:
	self.text = action.displayName \
		+ (str("\n[", action.usesRemaining, "]") if action.hasFiniteUses else "")
	self.icon = action.icon
	self.tooltip_text = action.description
	self.disabled = not checkUsability()
	cooldownBar.visible = action.cooldownRemaining > 0 or not is_zero_approx(action.cooldownRemaining) # Multiple checks in case of float funkery


## Checks if the [member entity]'s [StatsComponent] has the [Stat] required to perform the [member action].
func checkUsability() -> bool:
	return action.isUsable \
		and action.validateStatsComponent(statsComponent)


#region Events

func connectSignals() -> void:
	Tools.reconnectSignal(action.didDecreaseUses,   self.onAction_didDecreaseUses)
	Tools.reconnectSignal(action.didStartCooldown,  self.onAction_didStartCooldown)
	Tools.reconnectSignal(action.didFinishCooldown, self.onAction_didFinishCooldown)


func onPressed() -> void:
	if shouldShowDebugInfo: Debug.printDebug("onPressed()", self)
	generateInputEvent()


## Generates a "fake" input event with the [member Action.name] of the [member action] prefixed with [member GlobalInput.Actions.specialActionPrefix].
## This [InputEventAction] may then be processed by any Component or other class as any other [method _input] event.
func generateInputEvent() -> void:
	var actionEvent: InputEventAction = InputEventAction.new()
	actionEvent.action  = GlobalInput.Actions.specialActionPrefix + self.action.name
	actionEvent.pressed = true
	Input.parse_input_event(actionEvent)


func onAction_didDecreaseUses() -> void:
	updateUI()


func onAction_didStartCooldown() -> void:
	cooldownBar.max_value = action.cooldown
	cooldownBar.value	= action.cooldownRemaining
	cooldownBar.visible	= true
	self.disabled		= true
	self.set_process(true) # PERFORMANCE: Update per-frame only when needed


func onAction_didFinishCooldown() -> void:
	cooldownBar.value	= 0
	cooldownBar.visible	= false
	self.disabled		= false
	self.set_process(false) # PERFORMANCE: Update per-frame only when needed


func _process(_delta: float) -> void:
	if action.cooldownRemaining > 0:
		cooldownBar.value = action.cooldownRemaining

#endregion
