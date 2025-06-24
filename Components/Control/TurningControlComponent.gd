## Allows the player to rotate a node with left & right input actions.
## May be combined with the [ThrustControlComponent] to provide "tank-like" controls, similar to Asteroids.
## NOTE: Mutually exclusive with [MouseRotationComponent].
## Requirements: AFTER [InputComponent]

class_name TurningControlComponent
extends Component


#region Parameters
@export_range(0.1, 20, 0.1) var rotationSpeed: float = 5.0

## Override this to rotate a different node instead of the parent [Entity], such as a [GunComponent].
@export var nodeToRotate: Node2D = null

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue # Don't bother checking for a change
		self.set_physics_process(isEnabled) # PERFORMANCE: Set once instead of every frame
#endregion


#region Dependencies
@onready var inputComponent: InputComponent = coComponents.InputComponent # TBD: Static or dynamic?

func getRequiredComponents() -> Array[Script]:
	return [InputComponent]
#endregion


func _ready() -> void:
	if not nodeToRotate: nodeToRotate = self.parentEntity
	self.set_physics_process(isEnabled) # Apply setter because Godot doesn't on initialization


func _physics_process(delta: float) -> void:
	var rotationDirection: float = inputComponent.turnInput
	if  rotationDirection: nodeToRotate.rotation += (rotationSpeed * rotationDirection) * delta
	# DEBUG: Debug.watchList.rotationDirection = rotationDirection
