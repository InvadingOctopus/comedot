## Abstract base class for components which prompt the player or another [Entity] to choose a target for an [Ability].
## The [Ability] may be a special skill or magic spell etc. such as "Fireball", which may be targeted anywhere,
## or it may be an explicit command like "Talk" or "Examine" which requires the target to be an [Entity] with an [AbilityTargetableComponent].

class_name AbilityTargetingComponentBase # TBD: Cannot set as `@abstract` because it causes an error in AbilityControlComponent.gd:94 "Cannot set object script"
extends Component


#region Parameters

@export var ability: Ability

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
@onready var abilityComponent: AbilityComponent = coComponents.AbilityComponent # TBD: Static or dynamic?
#endregion


func _ready() -> void:
	if not ability: printWarning("No ability provided")
	self.isChoosing = self.isEnabled

	# Apply setters because Godot doesn't on initialization
	self.set_process(isEnabled)
	self.set_process_input(isEnabled)
	self.set_process_unhandled_input(isEnabled)

	if ability and self.isChoosing:
		GlobalUI.abilityIsChoosingTarget.emit(ability, self.entity) # Let any UI such as AbilityButton update itself.


#region Selection

## Calls [method AbilityTargetableComponent.requestToChoose] then if approved, calls [AbilityComponent.performAbility] with the entity of that [AbilityTargetableComponent].
## Returns the [Entity] of the chosen [AbilityTargetableComponent] if successful.
func chooseTarget(target: AbilityTargetableComponent) -> Entity:
	if debugMode: printLog("chooseTarget(): " + target.logFullNameWithEntity)
	if isEnabled and target.requestToChoose(ability, self.entity):
		var targetEntity: Entity = target.entity
		# Signals
		self.didChooseTarget.emit(targetEntity)
		GlobalUI.abilityDidChooseTarget.emit(ability, self.entity, targetEntity)
		# Go!
		abilityComponent.performAbility(ability.name, targetEntity) # NOTE: Perform abilities by their name ID # TBD: Use the actual Ability instance?
		return targetEntity
	else:
		if debugMode: printLog("chooseTarget() failed: " + target.logFullNameWithEntity)
		return null # TBD: Should the chosen Entity be returned even if requestToChoose() is denied?

#endregion


#region Cancellation

func cancelTargetSelection() -> void:
	TextBubble.create.call_deferred(str("CANCEL:", self.ability.name), entity) # call_deferred() because of Godot error: "Parent node is busy setting up children" when this Component is replaced by another targeting component, e.g. when clicking another Button while we are still choosing.
	self.isChoosing = false
	self.didCancel.emit()
	GlobalUI.abilityDidCancelTarget.emit(ability, self.entity)
	self.requestDeletion()


## IMPORTANT: Subclasses MUST call `super._input()` to handle cancellation.
func _input(event: InputEvent) -> void:
	# NOTE: _input() instead of _unhandled_input() because we don't want to be suppressed by Button or other UI click events etc.
	# DESIGN: Do NOT check `isEnabled` because cancellation must always be allowed
	if  self.isChoosing and event.is_action(GlobalInput.Actions.cancel) and event.is_action_pressed(GlobalInput.Actions.cancel) and not event.is_echo():
		self.cancelTargetSelection()
		self.get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		## ALERT: Notifications are received by subclass AFTER the base class,
		## so this component has already been unregistered at this point, but we don't need `entity` etc. so it's OK
		NOTIFICATION_UNPARENTED: if isChoosing: cancelTargetSelection() # Remove selection UI etc. if we're getting forcibly evicted :')
	# NOTE: FIXED: AVOID: _notification() is called for superclass automatically! Manually calling `super._notification(what)` causes bugs!!


func _exit_tree() -> void:
	if isChoosing: cancelTargetSelection() # Remove selection UI etc. if we're getting forcibly evicted :')
	super._exit_tree()

#endregion
