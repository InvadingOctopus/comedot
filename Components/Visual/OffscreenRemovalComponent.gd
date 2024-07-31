## Deletes the parent Entity when the child `VisibleOnScreenNotifier2D` goes off screen.

class_name OffscreenRemovalComponent
extends Component


@export var rectangle: Rect2:
	get: return onScreenNotifier.rect
	set(newValue):
		rectangle = newValue
		if onScreenNotifier: onScreenNotifier.rect = rectangle

@onready var onScreenNotifier: VisibleOnScreenNotifier2D = %OnScreenNotifier


func _ready() -> void:
	onScreenNotifier.rect = self.rectangle
	
	
func onScreenExited() -> void:
	self.parentEntity.queue_free()
