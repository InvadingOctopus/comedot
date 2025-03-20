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

@export var shouldShowTargetPrompt: bool = true
@export var debugMode: bool

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
	updateCooldown()


func updateCooldown() -> void:
	# TBD: PERFORMANCE: Just check action.isInCooldown or avoid property access/temporary variable creation for some reason? :')
	var isInCooldown: bool = action.cooldownRemaining > 0 or not is_zero_approx(action.cooldownRemaining) # Multiple checks in case of float funkery
	
	cooldownBar.max_value = action.cooldown
	cooldownBar.value	= action.cooldownRemaining if isInCooldown else 0.0 # Snap to 0 to avoid float funkery
	cooldownBar.visible	= isInCooldown
	self.disabled		= isInCooldown
	self.set_process(isInCooldown) # PERFORMANCE: Update per-frame only when needed


## Checks if the [member entity]'s [StatsComponent] has the [Stat] required to perform the [member action].
func checkUsability() -> bool:
	return action.isUsable \
		and action.validateStatsComponent(statsComponent)


#region Events

func connectSignals() -> void:
	Tools.connectSignal(action.didDecreaseUses,   self.onAction_didDecreaseUses)
	Tools.connectSignal(action.didStartCooldown,  self.onAction_didStartCooldown)
	Tools.connectSignal(action.didFinishCooldown, self.onAction_didFinishCooldown)

	Tools.connectSignal(GlobalUI.actionIsChoosingTarget, self.onGlobalUI_actionIsChoosingTarget)
	Tools.connectSignal(GlobalUI.actionDidChooseTarget,  self.onGlobalUI_actionDidChooseTarget)
	Tools.connectSignal(GlobalUI.actionDidCancelTarget,  self.onGlobalUI_actionDidCancelTarget)


func onPressed() -> void:
	if debugMode: Debug.printDebug("onPressed()", self)
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
	updateCooldown()


func onAction_didFinishCooldown() -> void:
	updateCooldown()


func onGlobalUI_actionIsChoosingTarget(eventAction: Action, _source: Entity) -> void:
	if eventAction == self.action:
		self.disabled = true
		if shouldShowTargetPrompt: TextBubble.create("Choose target", self, Vector2(self.size.x / 2, 0)) # Position the Bubble at the center of this Button


func onGlobalUI_actionDidChooseTarget(eventAction: Action, _source: Entity, _target: Variant) -> void:
	if eventAction == self.action: self.disabled = false


func onGlobalUI_actionDidCancelTarget(eventAction: Action, _source: Entity) -> void:
	if eventAction == self.action: self.disabled = false


func _process(_delta: float) -> void:
	# PERFORMANCE: Update per-frame only when needed: Call `self.set_process()` whenever the Action starts or ends its cooldown.
	if action.cooldownRemaining > 0:
		cooldownBar.value = action.cooldownRemaining

#endregion
