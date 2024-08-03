# meta-name: Body Manipulating Component
# meta-description: A [Component] which manipulates a [CharacterBody2D], which may be the parent [Entity] itself.

# NOTE: This does NOT necessarily mean that this component HAS a body or must BE a body.

## Description

class_name _CLASS_
extends Component


#region Parameters

## If `null` then it will be acquired from the parent [Entity] on [method _enter_tree()]
@export var body: CharacterBody2D

@export var isEnabled: bool = true

#endregion


#region State
var coComponent: Component:
	get: return self.getCoComponent(Component)
#endregion


#region Signals
signal didSomethingHappen
#endregion


# Called whenever the node enters the scene tree.
func _enter_tree() -> void:
	super._enter_tree()
	if parentEntity != null and self.body == null:
			self.body = parentEntity.getBody()


func _ready() -> void:
	pass # Any code needed to configure and prepare the component.


func _input(event: InputEvent) -> void:
	if not isEnabled: return
	pass # Handle one-shot input events such as jumping or firing.


func _process(delta: float) -> void:
	if not isEnabled: return
	pass # Handle per-frame updates and continuous input such as moving or turning.
