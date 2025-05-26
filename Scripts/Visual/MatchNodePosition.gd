## Sets a node's position to another node's, on 1 or both axes.
## Example: An arrow sprite that indicates where the player is.
## @experimental

# class_name MatchNodePosition
extends Node2D


#region Parameters
@export var nodeToMatch: Node2D: ## If omitted, then the first [member GameState.players] Entity is used.
	set(newValue):
		nodeToMatch = newValue
		self.set_process(isEnabled and is_instance_valid(nodeToMatch))

@export var matchX:		bool = true
@export var matchY:		bool = false

@export var isEnabled:	bool = true:
	set(newValue):
		isEnabled = newValue # Don't bother checking for a change
		self.set_process(isEnabled and is_instance_valid(nodeToMatch)) # PERFORMANCE: Set once instead of every frame
#endregion


func _ready() -> void:
	if not nodeToMatch: nodeToMatch = GameState.getPlayer(0)
	self.set_process(isEnabled) # Apply setter because Godot doesn't on initialization


func _process(_delta: float) -> void: # _process() instead of _physics_process() because it should happen every frame regardless of physics.
	# TBD: PERFORMANCE: Assign in 1 call if both flags set?
	if matchX: self.global_position.x = nodeToMatch.global_position.x
	if matchY: self.global_position.y = nodeToMatch.global_position.y
