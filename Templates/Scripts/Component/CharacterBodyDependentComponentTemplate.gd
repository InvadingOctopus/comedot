# meta-name: Body Manipulating Component
# meta-description: A [Component] which manipulates a [CharacterBody2D], which may be the parent [Entity] itself.

## Description

class_name _CLASS_
extends CharacterBodyDependentComponentBase

# Manipulates an [CharacterBody2D]. NOTE: This does NOT necessarily mean that this component HAS a body or must BE a body.


#region Parameters
@export_range(0.0, 100.0, 10.0) var speed: float ## PLACEHOLDER
@export var isEnabled: bool = true
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
	return [CharacterBodyComponent, InputComponent]

#endregion


func _ready() -> void:
	# PLACEHOLDER: Remove signals if not needed.
	Tools.connectSignal(characterBodyComponent.didMove,				self.onCharacterBodyComponent_didMove)
	Tools.connectSignal(inputComponent.didUpdateMovementDirection,	self.onInputComponent_didUpdateMovementDirection)
	Tools.connectSignal(inputComponent.didUpdateInputActionsList,	self.onInputComponent_didUpdateInputActionsList)
	# PLACEHOLDER: Add any code needed to configure and prepare the component.


func onInputComponent_didUpdateMovementDirection(movementDirection: Vector2, difference: Vector2) -> void:
	if not isEnabled: return
	pass # PLACEHOLDER: Remove if input is not needed.


func onInputComponent_didUpdateInputActionsList(event: InputEvent) -> void:
	if not isEnabled: return
	pass # PLACEHOLDER: Handle one-shot input events such as jumping or firing.


func _process(delta: float) -> void: # NOTE: If you need to process movement or collisions, use `_physics_process()`
	if not isEnabled: return
	pass # PLACEHOLDER: Perform any per-frame updates.


## Performs updates that depend on the state and flags of the [CharacterBody2D] AFTER [method CharacterBody2D.move_and_slide].
func onCharacterBodyComponent_didMove(delta: float) -> void:
	if not isEnabled: return
	pass # PLACEHOLDER: Add your code here.
