# meta-default: true

## Description
## Requirements: [Does this component depend on other components? Or does it need the parent Entity to be a specific type of node?]

class_name _CLASS_
extends TurnBasedComponent


#region Parameters
@export_range(0.0, 10.0, 1.0) var placeholder: float ## Placeholder
#endregion


#region State

var coComponent: Component: ## Placeholder
	get:
		# WARNING: "Memoization" (caching the reference) may cause bugs if a new component of the same type is later added to the entity.
		if not coComponent: coComponent = self.getCoComponent(Component)
		return coComponent
		
#endregion


#region Signals
signal didSomethingHappen ## Placeholder
#endregion


## Returns a list of required component types that this component depends on.
func getRequiredcomponents() -> Array[Script]:
	return []


func _ready() -> void:
	pass # Any code needed to configure and prepare the component.


func _input(event: InputEvent):
	if not isEnabled: return
	pass # Handle one-shot input events such as jumping or firing.


func processTurnBegin() -> void:
	# isEnabled is handled by parent class.
	pass # Handle "pre-turn" activity that happens BEFORE the main activity, such as animations, healing-over-time effects or any other setup.


func processTurnUpdate() -> void:
	# isEnabled is handled by parent class.
	pass # Handle The actual actions which occur every turn, such as movement or combat.


func processTurnEnd() -> void:
	# isEnabled is handled by parent class.
	pass # Handle any "post-turn" activity that happens AFTER the main activity, such as animations, damage-over-time effects, log messages, or cleanup.
