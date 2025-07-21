## Displays a text [Label] atop the Entity node with an animation.
## @experimental

class_name LabelComponent
extends Component

# TODO: FIXME: Center the Label alignment on Sprite entities etc.


#region Parameters
@export var shouldAnimateOnReady: bool = false ## If `true` then the [Label] is initially hidden then animated as soon as this component is [method _ready]
#endregion


#region State
@onready var label: Label = self.get_node(^".") as Label
var tween: Tween
#endregion


func _ready() -> void:
	if shouldAnimateOnReady:
		label.visible = false


func display(text: String, animationFunction: Callable = Animations.blink) -> void:
	# TODO: Allow custom arguments for the `animationFunction`
	label.text = text
	playAnimation(animationFunction)


func playAnimation(animationFunction: Callable) -> void:
	# TODO: Allow custom arguments for the `animationFunction`
	if tween: tween.kill()	
	label.visible = true # Just in case
	tween = animationFunction.call(label)
	await tween.finished
	label.visible = false # Just in case
