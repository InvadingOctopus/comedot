## A subclass of [Entity] specialized for player-controlled characters.

class_name PlayerEntity
extends Entity


func _enter_tree():
	super._enter_tree()
	self.add_to_group(Global.Groups.players, true)


func _ready():
	GameState.addPlayer(self)


func _exit_tree():
	super._exit_tree()
	GameState.removePlayer(self)
