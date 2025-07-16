# meta-name: Area Manipulating Component
# meta-description: A [Component] which manipulates an [Area2D], which may be the parent [Entity] itself.

## Description

class_name _CLASS_
extends Component

# Manipulates an [Area2D]. NOTE: This does NOT necessarily mean that this component HAS an area or must BE an area.


#region Parameters
## If `null` then it will be acquired from the parent [Entity] on [method _enter_tree()]
@export var area: Area2D

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue # Don't bother checking for a change
		# PERFORMANCE: Set once instead of every frame
		self.set_process(isEnabled)
		self.set_process_input(isEnabled)
		if  area:
			# NOTE: Cannot set flags directly because Godot error: "Function blocked during in/out signal"
			area.set_deferred(&"monitoring",  isEnabled)
			area.set_deferred(&"monitorable", isEnabled)
#endregion


#region State
var property: int ## Placeholder
#endregion


#region Signals
signal didSomethingHappen ## Placeholder
#endregion


#region Dependencies

var coComponent: Component = coComponents.Component ## Placeholder # WARNING: "Memoization" (caching the reference) may cause bugs if a new component of the same type is later added to the entity.

## Returns a list of required component types that this component depends on.
func getRequiredComponents() -> Array[Script]:
	return []

#endregion


func _ready() -> void:
	if parentEntity != null and self.area == null:
		self.area = parentEntity.getArea()	
	# Apply setters because Godot doesn't on initialization
	self.set_process(isEnabled)
	self.set_process_input(isEnabled)
	if  area:
		area.monitoring  = isEnabled
		area.monitorable = isEnabled
		area.area_entered.connect(self.onArea_areaEntered)
		area.area_exited.connect(self.onArea_areaExited)
	# Placeholder: Add any code needed to configure and prepare the component.


func _input(event: InputEvent) -> void:
	pass # Placeholder: Handle one-shot input events such as jumping or firing.


func _process(delta: float) -> void: # NOTE: If you need to process movement or collisions, use `_physics_process()`
	pass # Placeholder: Perform any per-frame updates.


## Called when the [param enteredArea] enters this component's associated [member area]. Requires [member Area2D.monitoring] to be set to [constant true].
func onArea_areaEntered(enteredArea: Area2D) -> void:
	if not isEnabled: return
	pass # Placeholder: Add your code here.


## Called when the [param exitedArea] leaves this component's associated [member area]. Requires [member Area2D.monitoring] to be set to [constant true].
func onArea_areaExited(exitedArea: Area2D) -> void:
	if not isEnabled: return
	pass # Placeholder: Add your code here.
