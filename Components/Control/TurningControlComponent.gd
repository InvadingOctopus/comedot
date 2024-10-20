## Allows the player to rotate a node with left & right input actions.
## May be combined with the [ThrustControlComponent] to provide "tank-like" controls, similar to Asteroids.
## NOTE: Mutually exclusive with [MouseRotationComponent].
## Requirements: AFTER [PlayerInputComponent]

class_name TurningControlComponent
extends Component


#region Parameters
@export_range(0.1, 20, 0.1) var rotationSpeed: float = 5.0

## Override this to rotate a different node instead of the parent [Entity], such as a [GunComponent].
@export var nodeToRotate: Node2D = null

@export var isEnabled: bool = true
#endregion


#region Dependencies
@onready var playerInputComponent: PlayerInputComponent = coComponents.PlayerInputComponent # TBD: Static or dynamic?

func getRequiredComponents() -> Array[Script]:
	return [PlayerInputComponent]
#endregion


func _ready() -> void:
	if not nodeToRotate:
		nodeToRotate = self.parentEntity


func _physics_process(delta: float) -> void:
	if not isEnabled: return

	var rotationDirection: float = playerInputComponent.turnInput

	if rotationDirection: nodeToRotate.rotation += (rotationSpeed * rotationDirection) * delta

	#Debug.watchList.rotationDirection = rotationDirection
