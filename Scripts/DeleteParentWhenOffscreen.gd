## Calls [method Node.queue_free()] on the parent [Node] when the bounding [member VisibleOnScreenNotifier2D.rect] of this [VisibleOnScreenNotifier2D] goes off screen.

extends VisibleOnScreenNotifier2D


## The time in seconds to wait for before removing the parent after it goes offscreen. If 0 the removal is instant.
@export var removalDelay: float = 0


func _ready() -> void:
	self.screen_exited.connect(onScreenExited)


## Delete parent node when offscreen
func onScreenExited() -> void:
	if removalDelay > 0:
		await self.get_tree().create_timer(removalDelay).timeout

	# TBD: Get topmost/root parent node?
	get_parent().queue_free()
