## Moves a node in the opposite horizontal direction of another node.
## Used to simulate a basic parallax effect. For proper parallax, use [Parallax2D].
## @experimental

# class_name FakeParallax
extends CanvasItem


#region Parameters

@export var focalNode:	 Node2D: ## The node which acts as the "camera" such as the player sprite. If omitted, the first [member GameState.players] Entity is used.
	set(newValue):
		if newValue != focalNode:
			focalNode = newValue
			self.set_process(isEnabled and is_instance_valid(focalNode)) # PERFORMANCE: Set once instead of every frame

@export var scrollScale: Vector2 = Vector2(1, 0)

@export var isEnabled:	 bool	 = true:
	set(newValue):
		isEnabled = newValue # Don't bother checking for a change
		self.set_process(isEnabled and is_instance_valid(focalNode)) # PERFORMANCE: Set once instead of every frame

#endregion

#region State
var previousFocalPosition: Vector2
#endregion


func _ready() -> void:
	if not focalNode: focalNode = GameState.getPlayer(0)
	if focalNode: self.previousFocalPosition = focalNode.global_position
	self.set_process(isEnabled and is_instance_valid(focalNode)) # Apply setter because Godot doesn't on initialization


func _process(_delta: float) -> void:
	if self.previousFocalPosition != focalNode.global_position:
		var difference: Vector2 = previousFocalPosition - focalNode.global_position
		self.position += (difference * scrollScale)

	self.previousFocalPosition = focalNode.global_position
