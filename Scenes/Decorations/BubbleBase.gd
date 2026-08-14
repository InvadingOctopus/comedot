## An abstract base class for temporary text labels that float upwards from another [Node2D], such as [TextBubble] & [GameplayResourceBubble]

@abstract class_name BubbleBase
extends Node2D


#region State
var tween: Tween ## The default animation [Tween] that starts on [method _ready]. May be modified or cancelled by custom scripts.
#endregion


#region Animation

func _ready() -> void:
	startDefaultAnimation.call_deferred() # NOTE: Start the initial animation after a short delay, so callers of the create…() methods can apply any modifications before we animate.


func startDefaultAnimation() -> void:
	if tween: return # Check in case whatever created this bubble applied a different animation # TBD: Check is_running()?
	tween = Animations.bubble(self)
	tween.tween_callback(self.queue_free) # Delete when done


## Overrides any ongoing [member tween] and appends [method Node.queue_free].
## @experimental
func applyNewAnimation(newTween: Tween) -> Tween:
	# TODO: Accept callbacks so that they can be started AFTER aborting the previous animation
	if self.tween: self.tween.kill()
	self.cancel_free() # Just in case we were headed for deletion
	self.tween = newTween
	tween.tween_callback(self.queue_free) # Delete when done
	return self.tween

#endregion
