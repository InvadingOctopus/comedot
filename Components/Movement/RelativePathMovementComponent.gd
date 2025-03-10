## Applies a set of movements relative to the a node's position (which may not be the entity).
## Uses a list of vectors which get "depleted" each frame.
## Requirements: Needs care when used together with other movement-manipulating components.

class_name RelativePathMovementComponent
extends Component

# Implementation:
# Get the first vector representing relative movement.
# Each frame: Apply a part of the vector to the entity's position,
# then deduct that part from the current movement vector.
# When the current vector is 0, get the next vector.

#region Parameters

@export var nodeOverride: Node2D ## If `null` then the parentEntity is used.

@export_range(0, 1000, 5) var speed: float = 50.0

## A list of vectors representing movement relative to the current position,
## such as "Go left 10 pixels" or "Go northwest 45 pixels".
@export var vectors: Array[Vector2] = [Vector2(32, 0), Vector2(-32, 0)]

@export_range(0, 60, 0.1, "seconds") var initialDelay: float = 0.0 ## The delay between the first move. NOT repeated in subsequent loops.

@export_range(0, 60, 0.1, "seconds") var delayBetweenMoves: float = 0.0

@export var shouldLoop: bool = true

@export var isEnabled := true

#endregion


#region State
var node: Node2D
var currentMoveIndex: int = 0
var currentVector:	Vector2 ## A vector represeting the remaining amount of relative movement to apply.

var isInDelay:		bool = false
var hasNoMoreMoves:	bool = false ## `true` if [member shouldLoop] is `false` or if there the [member vectors] array is empty.
#endregion


#region Signals
signal willStartMove ## Emitted after [member currentVector] has been set.
signal didFinishMove
#endregion


func _ready() -> void:
	if vectors.is_empty():
		printWarning("No vectors in list")
		self.hasNoMoreMoves = true
		return

	if not Tools.validateArrayIndex(vectors, currentMoveIndex):
		printWarning("Invalid index: " + str(currentMoveIndex, " for size: ", vectors.size()))
		self.hasNoMoreMoves = true
		return

	if self.nodeOverride:
		self.node = self.nodeOverride
	elif self.parentEntity:
		self.node = self.parentEntity
	elif self.get_parent():
		self.node = self.get_parent()
	else:
		printError("No parent entity or node!")
		self.isEnabled = false
		return

	if initialDelay > 0:
		self.isInDelay = true # Prevent frame updates
		await get_tree().create_timer(initialDelay).timeout
		self.isInDelay = false

	setCurrentVector()
	willStartMove.emit()


func _physics_process(delta: float) -> void:
	if (not isEnabled) or isInDelay or hasNoMoreMoves or self.currentVector.is_zero_approx(): return

	# The node's position after applying the current movement vector.
	var entityDestination: Vector2 = node.position + self.currentVector

	# The segment of the vector which will be applied to the node during this frame.
	var movementForThisFrame: Vector2 = node.position.move_toward(entityDestination, speed * delta) - node.position

	# Apply movment
	node.position += movementForThisFrame

	# Reduce the remaining vector
	self.currentVector -= movementForThisFrame

	# Has the current movement vector been "depleted?"
	if self.currentVector.is_zero_approx():
		didFinishMove.emit()
		setNextMove()


func setNextMove() -> void:

	if delayBetweenMoves > 0:
		self.isInDelay = true # Prevent frame updates
		await get_tree().create_timer(delayBetweenMoves).timeout # TODO: BUG: Is this causing inconsistency?
		self.isInDelay = false

	currentMoveIndex += 1

	if currentMoveIndex >= vectors.size():
		if shouldLoop:
			currentMoveIndex = 0
			self.hasNoMoreMoves = false # CHECK: Should we set this?
		else:
			self.hasNoMoreMoves = true

	setCurrentVector()
	willStartMove.emit()


## Returns: `Vector2.ZERO` if [member currentMoveIndex] is invalid.
func setCurrentVector() -> Vector2:
	if Tools.validateArrayIndex(vectors, currentMoveIndex):
		self.currentVector = vectors[currentMoveIndex]
	else:
		self.currentVector = Vector2.ZERO

	return currentVector
