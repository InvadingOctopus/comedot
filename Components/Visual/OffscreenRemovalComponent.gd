## Calls [method Entity.requestDeletion] → [method Node.queue_free] on the parent [Entity] when the bounding [member VisibleOnScreenNotifier2D.rect] of the [VisibleOnScreenNotifier2D] goes off screen.
## May have an optional delay to allow an entity some time to return back on screen.

class_name OffscreenRemovalComponent
extends Component

## The time in seconds to wait for before removing the Entity after it goes offscreen. If 0 the removal is instant.
@export var removalDelay: float = 0


## Delete parent node when offscreen
func onScreenExited() -> void:
	if removalDelay > 0 and not is_zero_approx(removalDelay): # Just to be safe
		await self.get_tree().create_timer(removalDelay).timeout

	parentEntity.requestDeletion()
