## Tells the Entity's [AnimatedSprite2D] to play different animations based on the [PlatformControlComponent]'s movement.
## Requirements: AnimatedSprite2D, CharacterBody2D, PlatformControlComponent (preceding this)


class_name PlatformControlAnimationComponent
extends Component

# TODO: A better name :)

#region Parameters
@export var idleAnimation: StringName = &"idle"
@export var walkAnimation: StringName = &"walk"
@export var jumpAnimation: StringName = &"jump"
@export var fallAnimation: StringName = &"fall"

@export var flipWhenWalkingLeft: bool = true
@export var isEnabled := true
#endregion


#region State
var animatedSprite: AnimatedSprite2D
var platformControlComponent: PlatformControlComponent
#endregion


#region Signals

#endregion


func _ready():
	self.animatedSprite = parentEntity.findFirstChildOfType(AnimatedSprite2D)
	self.platformControlComponent = self.findCoComponent(PlatformControlComponent)


func _process(delta: float):
	if not isEnabled : return

	# INFO: Animations are checked in order of priority: "walk" overrides "idle"

	var animationToPlay: StringName
	var body: CharacterBody2D = parentEntity.body

	if flipWhenWalkingLeft:
		animatedSprite.flip_h = true if signf(platformControlComponent.lastDirection) < 0.0 else false
		# Debug.watchList.hDirection = platformControlComponent.lastDirection

	if not idleAnimation.is_empty() \
	and body.velocity.is_zero_approx():
		animationToPlay = idleAnimation

	if not walkAnimation.is_empty() \
	and not body.velocity.is_zero_approx():
		animationToPlay = walkAnimation

	# Debug.watchList.onFloor = body.is_on_floor()

	if not body.is_on_floor():
		var verticalDirection: float = signf(body.velocity.y)

		if not jumpAnimation.is_empty() \
		and verticalDirection < 0.0:
			animationToPlay = jumpAnimation
		elif not fallAnimation.is_empty() \
		and verticalDirection > 0.0:
			animationToPlay = fallAnimation

		# Debug.watchList.vDirection = verticalDirection

	animatedSprite.play(animationToPlay)


