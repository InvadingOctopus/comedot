# meta-name: Body Manipulating Component
# meta-description: A [Component] which manipulates a [CharacterBody2D], which may be the parent [Entity] itself.

# NOTE: This does NOT necessarily mean that this component HAS a body or must BE a body.

## Description

class_name _CLASS_
extends CharacterBodyManipulatingComponentBase


#region Parameters
@export_range(0.0, 10.0, 1.0) var speed: float ## Placeholder
@export var isEnabled: bool = true
#endregion


#region State
var placeholder: int ## Placeholder
#endregion


#region Signals
signal didSomethingHappen ## Placeholder
#endregion


#region Dependencies
var coComponent: Component: ## Placeholder
	get:
		# WARNING: "Memoization" (caching the reference) may cause bugs if a new component of the same type is later added to the entity.
		if not coComponent: coComponent = self.getCoComponent(Component)
		return coComponent
#endregion


## Returns a list of required component types that this component depends on.
func getRequiredcomponents() -> Array[Script]:
	return [] 


func _ready() -> void:
	characterBodyComponent.didMove.connect(self.onCharacterBodyComponent_didMove)
	pass # Placeholder: Add any code needed to configure and prepare the component.


func _input(event: InputEvent) -> void:
	if not isEnabled: return
	pass # Placeholder: Handle one-shot input events such as jumping or firing.


func _process(delta: float) -> void:
	if not isEnabled: return
	pass # Placeholder: Perform any per-frame updates and handle continuous input such as moving or turning.


## Performs updates that depend on the state and flags of the [CharacterBody2D] AFTER [method CharacterBody2D.move_and_slide].
func onCharacterBodyComponent_didMove() -> void:
	if not isEnabled: return
	pass # Placeholder: Add your code here.
