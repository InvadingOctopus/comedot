## Allows the player to rotate a node with left & right input actions.
## May be combined with the [ThrustControlComponent] to provide "tank-like" controls, similar to Asteroids.
## Requirements: [PlayerInputComponent]

class_name TurningControlComponent
extends Component


#region Parameters
@export_range(0.1, 20, 0.1) var rotationSpeed: float = 5.0

## Override this to rotate a different node instead of the parent [Entity], such as a [GunComponent].
@export var nodeToRotate: Node2D = null

@export var isEnabled: bool = true
#endregion


#region State
var playerInputComponent: PlayerInputComponent:
	get:
		if not playerInputComponent:
			playerInputComponent = self.getCoComponent(PlayerInputComponent)
		return playerInputComponent
#endregion


func _ready() -> void:
	if not nodeToRotate:
		nodeToRotate = self.parentEntity


func _physics_process(delta: float):
	if not isEnabled: return

	var rotationDirection: float = playerInputComponent.turnInput

	if rotationDirection: nodeToRotate.rotation += (rotationSpeed * rotationDirection) * delta

	#Debug.watchList.rotationDirection = rotationDirection
