extends VisibleOnScreenNotifier2D

func onScreenExited() -> void:
	# Delete parent node when offscreen
	# TODO: Get topmost/root parent node?
	var parent: Node = get_parent()
	parent.queue_free()
