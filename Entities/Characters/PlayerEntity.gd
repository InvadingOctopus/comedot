## A subclass of [Entity] specialized for player-controlled characters.

class_name PlayerEntity
extends Entity


func _enter_tree() -> void:
	super._enter_tree()
	self.add_to_group(Global.Groups.players, true)


func _ready() -> void:
	GameState.addPlayer(self)


func _exit_tree() -> void:
	super._exit_tree()
	GameState.removePlayer(self)
