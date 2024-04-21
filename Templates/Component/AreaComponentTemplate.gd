# meta-name: Area Manipulating Component
# meta-description: A [Component] which manipulates an [Area2D], which may be the parent [Entity] itself.

# NOTE: This does NOT necessarily mean that this component HAS an area or must BE an area.

## Description

class_name _CLASS_
extends Component


#region Parameters

## If `null` then it will be acquired from the parent [Entity] on [method _enter_tree()]
@export var area: Area2D

@export var isEnabled := true

#endregion


#region State
var coComponent: Component:
	get: return self.findCoComponent(Component)
#endregion


#region Signals
signal didSomethingHappen
#endregion


# Called whenever the node enters the scene tree.
func _enter_tree():
	super._enter_tree()
	if parentEntity != null and self.area == null:
			self.area = parentEntity.getArea()


func _ready():
	pass # Any code needed to configure and prepare the component.


func _input(event: InputEvent):
	if not isEnabled: return
	pass # Handle one-shot input events such as jumping or firing.


func _process(delta: float):
	if not isEnabled: return
	pass # Handle per-frame updates and continuous input such as moving or turning.
