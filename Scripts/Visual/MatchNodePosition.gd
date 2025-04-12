## Sets a node's position to another node's, on 1 or both axes.
## Example: An arrow sprite that indicates where the player is.
## @experimental

# class_name MatchNodePosition
extends Node2D


#region Parameters
@export var nodeToMatch: Node2D ## If omitted, then the first [member GameState.players] Entity is used.
@export var matchX:		bool = true
@export var matchY:		bool = false
@export var isEnabled:	bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process(isEnabled)
#endregion


func _ready() -> void:
	if not nodeToMatch: nodeToMatch = GameState.getPlayer(0)


func _process(_delta: float) -> void:
	if not isEnabled: return
	# TBD: PERFORMANCE: Assign in 1 call if both flags set?
	if matchX: self.global_position.x = nodeToMatch.global_position.x
	if matchY: self.global_position.y = nodeToMatch.global_position.y
