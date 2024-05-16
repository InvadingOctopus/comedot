## Applies a set of relative movements to a [Node2D]

extends Node2D


#region Parameters

@export_range(0, 1000, 5) var speed: float = 50.0

@export var vectors: Array[Vector2]

@export_range(0, 10, 0.1, "seconds") var delayBetweenMoves: float = 0.0

@export var shouldLoop: bool = true

@export var isEnabled: bool = true
#endregion


#region State
var currentMoveIndex: int = 0
var currentDestination: Vector2
var isWaiting: bool = false
#endregion


func _ready():
	setCurrentDestination()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float):
	if (not isEnabled) or isWaiting: return
	self.position = self.position.move_toward(currentDestination, speed * delta)

	if self.position.is_equal_approx(currentDestination):
		setNextMove()


func setNextMove():

	if delayBetweenMoves > 0:
		isWaiting = true # Prevent frame updates
		await get_tree().create_timer(delayBetweenMoves).timeout
		isWaiting = false

	currentMoveIndex += 1

	if currentMoveIndex >= vectors.size():
		if shouldLoop:
			currentMoveIndex = 0
		else:
			self.isEnabled = false

	setCurrentDestination()


func setCurrentDestination() -> Vector2:
	var currentVector: Vector2 = vectors[currentMoveIndex] # TODO: Checks
	self.currentDestination = self.position + currentVector
	return currentDestination
