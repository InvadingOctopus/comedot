## Abstract base class for components which prompt the player or another [Entity] to choose a target for an [Action].
## The [Action] may be a special skill or magic spell etc. such as "Fireball", which may be targeted anywhere,
## or it may be an explicit command like "Talk" or "Examine" which requires the target to be an [Entity] with an [ActionTargetableComponent].

class_name ActionTargetingComponentBase
extends Component


#region Parameters

@export var action: Action

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.isChoosing = isEnabled 

#endregion


#region State
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


## Returns the [Entity] of the chosen [ActionTargetableComponent] if [method ActionTargetableComponent.requestToChoose] is approved,
## otherwise returns `null`.
func chooseTarget(target: ActionTargetableComponent) -> Entity:
	if isEnabled and target.requestToChoose():
		var targetEntity: Entity = target.parentEntity
		self.didChooseTarget.emit(targetEntity)
		actionsComponent.performAction(action.name, targetEntity)
		return targetEntity
	else:
		return null
		# TBD: Should the chosen Entity be returned even if `requestToChoose()` is denied?


func cancelTargetSelection() -> void:
	self.isChoosing = false
	self.didCancel.emit()
	self.requestDeletion()
