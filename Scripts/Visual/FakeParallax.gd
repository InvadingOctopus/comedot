## Moves a node in the opposite horizontal direction of another node.
## Used to simulate a basic parallax effect. For proper parallax, use [Parallax2D].
## @experimental

# class_name FakeParallax
extends CanvasItem


#region Parameters
@export var focalNode:	 Node2D ## The node which acts as the "camera" such as the player sprite. If omitted, the first [member GameState.players] Entity is used.
@export var scrollScale: Vector2 = Vector2(1, 0)
@export var isEnabled:	 bool	 = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process(isEnabled)
#endregion

#region State
var previousFocalPosition: Vector2
#endregion


func _ready() -> void:
	if not focalNode: focalNode = GameState.getPlayer(0)

	if focalNode: self.previousFocalPosition = focalNode.global_position


func _process(_delta: float) -> void:
	# if not isEnabled: return # Set by property setter

	if self.previousFocalPosition != focalNode.global_position:
		var difference: Vector2 = previousFocalPosition - focalNode.global_position
		self.position += (difference * scrollScale)

	self.previousFocalPosition = focalNode.global_position
