## Deletes the parent Entity when the child `VisibleOnScreenNotifier2D` goes off screen.

class_name OffscreenRemovalComponent
extends Component

@export var rectangle: Rect2:
	get: return %VisibleOnScreenNotifier2D.rect
	set(newValue): %VisibleOnScreenNotifier2D.rect = newValue


func onScreenExited() -> void:
	self.parentEntity.queue_free()
