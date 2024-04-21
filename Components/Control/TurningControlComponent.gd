## Allows the player to rotate a node with left & right input actions.
## Also known as "tank controls"

class_name TurningControlComponent
extends Component


## Override this to rotate a different node instead of the parent [Entity], such as a [GunComponent].
@export var nodeToRotate: Node2D = null

@export_range(0.1, 20, 0.1) var rotationSpeed: float = 5.0


func _ready():
	if not nodeToRotate:
		nodeToRotate = self.parentEntity


func _physics_process(delta: float):
	var rotationDirection := Input.get_axis(GlobalInput.Actions.turnLeft, GlobalInput.Actions.turnRight)
	if not rotationDirection: return
	Debug.watchList.rotationDirection = rotationDirection

	nodeToRotate.rotation += (rotationSpeed * rotationDirection) * delta
