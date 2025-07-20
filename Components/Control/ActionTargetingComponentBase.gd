## Abstract base class for components which prompt the player or another [Entity] to choose a target for an [Action].
## The [Action] may be a special skill or magic spell etc. such as "Fireball", which may be targeted anywhere,
## or it may be an explicit command like "Talk" or "Examine" which requires the target to be an [Entity] with an [ActionTargetableComponent].

class_name ActionTargetingComponentBase # TBD: Cannot set as `@abstract` because it causes an error in ActionControlComponent.gd:94 "Cannot set object script"
extends Component


#region Parameters

@export var action: Action

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.isChoosing = isEnabled
			# PERFORMANCE: Set once instead of checking on every frame/event
			# NOTE: WATCHOUT: BUGCHANCE: If other flags in a subclass dictate one of these "process" states, then changing `isEnabled` will not respect those flags.
			self.set_process(isEnabled)
			self.set_process_input(isEnabled)
			self.set_process_unhandled_input(isEnabled)

#endregion


#region State
@onready var cursor: Node2D = self.get_node(^".") as Node2D
var isChoosing: bool
#endregion


#region Signals
signal didChooseTarget(entity: Entity)
signal didCancel
#endregion


#region Dependencies
@onready var actionsComponent: ActionsComponent = coComponents.ActionsComponent # TBD: Static or dynamic?
#endregion


func _ready() -> void:
	if not action: printWarning("No action provided")
	self.isChoosing = self.isEnabled

	if action and self.isChoosing:
		GlobalUI.actionIsChoosingTarget.emit(action, self.parentEntity) # Let any UI such as ActionButton update itself.


## Returns the [Entity] of the chosen [ActionTargetableComponent] if [method ActionTargetableComponent.requestToChoose] is approved,
## otherwise returns `null`.
func chooseTarget(target: ActionTargetableComponent) -> Entity:
	if debugMode: printLog("chooseTarget(): " + target.logFullNameWithEntity)
	if isEnabled and target.requestToChoose(action, self.parentEntity):
		var targetEntity: Entity = target.parentEntity
		# Signals
		self.didChooseTarget.emit(targetEntity)
		GlobalUI.actionDidChooseTarget.emit(action, self.parentEntity, targetEntity)
		# Go!
		actionsComponent.performAction(action.name, targetEntity) # NOTE: Perform actions by their name ID # TBD: Use the actual Action instance?
		return targetEntity
	else:
		if debugMode: printLog("chooseTarget() failed: " + target.logFullNameWithEntity)
		return null # TBD: Should the chosen Entity be returned even if requestToChoose() is denied?


#region Cancellation

func cancelTargetSelection() -> void:
	TextBubble.create.call_deferred(str("CANCEL:", self.action.name), parentEntity) # call_deferred() because of Godot error: "Parent node is busy setting up children" when this Component is replaced by another targeting component, e.g. when clicking another Button while we are still choosing.
	self.isChoosing = false
	self.didCancel.emit()
	GlobalUI.actionDidCancelTarget.emit(action, self.parentEntity)
	self.requestDeletion()


func _input(event: InputEvent) -> void:
	# NOTE: _input() instead of _unhandled_input() because we don't want to be suppressed by Button or other UI click events etc.
	# NOTE: Do not check `isEnabled`: Cancellation must always be allowed
	if self.isChoosing and event.is_action(GlobalInput.Actions.cancel) and event.is_action_pressed(GlobalInput.Actions.cancel) and not event.is_echo():
		self.cancelTargetSelection()
		self.get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_UNPARENTED: if isChoosing: cancelTargetSelection() # Remove selection UI etc. if we're getting forcibly evicted :')
	# NOTE: FIXED: AVOID: _notification() is called for superclass automatically! Manually calling `super._notification(what)` causes bugs!!


func _exit_tree() -> void:
	if isChoosing: cancelTargetSelection() # Remove selection UI etc. if we're getting forcibly evicted :')
	super._exit_tree()

#endregion
