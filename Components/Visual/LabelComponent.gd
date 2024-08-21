## Displays a text label atop the Entity node with an animation.
class_name LabelComponent
extends Component


## If unspecified then the parent [Entity]'s node will be used.
@export var parentNodeOverride: Node2D = null


@onready var label: Label = %Label

func _ready() -> void:
	# Just in case we left it visible in the editor.
	label.visible = false


func display(text: String, animation: StringName = Animations.blink) -> void:
	label.text = text
	playAnimation(animation)


func blink(text: String) -> void:
	label.text = text
	playAnimation("blink")


func playAnimation(animationName: StringName) -> void:
	%AnimationPlayer.stop()
	label.visible = true # Just in case
	%AnimationPlayer.play(animationName)
	await %AnimationPlayer.animation_finished
	label.visible = false # Just in case
