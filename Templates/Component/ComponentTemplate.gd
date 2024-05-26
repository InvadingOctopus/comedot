# meta-default: true

## Description
## Requirements: [Does this component depend on other components? Or does it need the parent Entity to be a specific type of node?]

class_name _CLASS_
extends Component


#region Parameters
@export_range(0.0, 10.0, 1.0) var speed: float ## Placeholder
@export var isEnabled := true
#endregion


#region State
var coComponent: Component: ## Placeholder
	get: return self.findCoComponent(Component)
#endregion


#region Signals
signal didSomethingHappen ## Placeholder
#endregion


func _ready():
	pass # Any code needed to configure and prepare the component.


func _input(event: InputEvent):
	if not isEnabled: return
	pass # Handle one-shot input events such as jumping or firing.


func _process(delta: float):
	if not isEnabled: return
	pass # Handle per-frame updates and continuous input such as moving or turning.
