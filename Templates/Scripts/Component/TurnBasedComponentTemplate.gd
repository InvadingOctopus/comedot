# meta-default: true

## Description
## Requirements: [Does this component depend on other components? Or does it need the parent Entity to be a specific type of node?]

class_name _CLASS_
extends TurnBasedComponent


#region Parameters
@export_range(0.0, 100.0, 10.0) var speed: float ## PLACEHOLDER
#endregion


#region State
var property: int ## PLACEHOLDER
#endregion


#region Signals
signal didSomethingHappen ## PLACEHOLDER
#endregion


#region Dependencies

# WARNING: "Memoization" (caching the reference) may cause bugs if a component is removed from the entity later.

@onready var coComponent:	 Component		= coComponents.Component ## PLACEHOLDER
@onready var inputComponent: InputComponent	= getCoComponent(InputComponent, true) # findSubclasses

## Returns a list of required component types that this component depends on.
func getRequiredComponents() -> Array[Script]:
	return [InputComponent]

#endregion


func _ready() -> void:
	# PLACEHOLDER: Remove signals if input is not needed.
	Tools.connectSignal(inputComponent.didUpdateMovementDirection,	self.onInputComponent_didUpdateMovementDirection)
	Tools.connectSignal(inputComponent.didUpdateInputActionsList,	self.onInputComponent_didUpdateInputActionsList)
	# PLACEHOLDER: Add any code needed to configure and prepare the component.


func onInputComponent_didUpdateMovementDirection(movementDirection: Vector2, difference: Vector2) -> void:
	if not isEnabled or not TurnBasedCoordinator.canStartTurn: return
	pass # PLACEHOLDER: Remove if input is not needed.


func onInputComponent_didUpdateInputActionsList(event: InputEvent) -> void:
	if not isEnabled or not TurnBasedCoordinator.canStartTurn: return
	pass # PLACEHOLDER: Handle one-shot input events such as jumping or firing.


func processTurnBegin() -> void:
	# isEnabled is checked by [TurnBasedComponent]
	pass # PLACEHOLDER: Handle "pre-turn" activity that happens BEFORE the main activity, such as animations, healing-over-time effects or any other setup.


func processTurnExecute() -> void:
	# isEnabled is checked by [TurnBasedComponent]
	pass # PLACEHOLDER: Handle the actual actions which occur every turn, such as movement or combat.


func processTurnEnd() -> void:
	# isEnabled is checked by [TurnBasedComponent]
	pass # PLACEHOLDER: Handle any "post-turn" activity that happens AFTER the main activity, such as animations, damage-over-time effects, log messages, or cleanup.
