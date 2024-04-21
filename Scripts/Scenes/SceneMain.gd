extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().call_group("deleteOnSceneReady", "queue_free")

