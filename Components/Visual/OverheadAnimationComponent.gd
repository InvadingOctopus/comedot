## Plays idle/walk animations on the entity's [AnimatedSprite2D] in response to changes in an [InputComponent]'s [member InputComponent.movementDirection]
## for use in conjunction with [OverheadPhysicsComponent] or [BasicOverheadPhysicsComponent]
## A more simple alternative to [AnimationTree]
## IMPORTANT: The [AnimatedSprite2D] [SpriteFrames] animations match a specific naming convention:
## "idleN" for North/Up, "walkN", "idleSE" for Southeast/Down-right, "walkSE" and so on.
## NOTE: Diagonal movement keeps the previous animation.
## TIP: Use `/Scripts/Visual/CreateSpriteFramesFromSheet.gd` to automatically create [AnimatedSprite2D] [SpriteFrames] animations from a sprite sheet image
## Requirements: [AnimatedSprite2D], [InputComponent]

class_name OverheadAnimationComponent
extends AnimationComponentBase


#region Parameters
@export var idlePrefix: StringName = &"idle" ## The prefix before the compass letters such as "N", "NE", "E" etc. for idle animation names.
@export var walkPrefix: StringName = &"walk" ## The prefix before the compass letters such as "N", "NE", "E" etc. for walk animation names.
#endregion


#region Dependencies
@onready var inputComponent: InputComponent = getCoComponent(InputComponent, true) # findSubclasses

func getRequiredComponents() -> Array[Script]:
	return [InputComponent]
#endregion


func _ready() -> void:
	super._ready()
	Tools.connectSignal(inputComponent.didUpdateMovementDirection, self.onInputComponent_didUpdateMovementDirection)
	self.set_physics_process(false) # No per-frame updates; only on input signals.


func onInputComponent_didUpdateMovementDirection(movementDirection: Vector2, difference: Vector2) -> void:
	if not isEnabled: return

	var animationToPlay:	StringName
	var animationDirection:	Vector2 = movementDirection
	var compassSuffix:		StringName

	# Use the previous direction when not moving, so idle animations keep facing the previous movement direction.
	# DESIGN: Diagonal movement keeps the previous animation

	if  animationDirection.is_zero_approx():
		animationDirection -= difference
	
	if not animationDirection.is_zero_approx(): # NOTE: Don't use `else` because we want to check `animationDirection` again after the previous `if`
		# Convert the movement vector to a 45°-snapped compass direction
		compassSuffix = Tools.compassDirectionLetters[
			wrapi(
				int(round(rad_to_deg(animationDirection.angle()) / Tools.degreesPerCompassDirection)) * Tools.degreesPerCompassDirection, 0, 360)
			as Tools.CompassDirection]

	# Idling or Walking?
	if  movementDirection.is_zero_approx():
		animationToPlay = StringName(idlePrefix + compassSuffix)
	else:
		animationToPlay = StringName(walkPrefix + compassSuffix)

	# Play the chosen animation
	if  animatedSprite.animation != animationToPlay:
		animatedSprite.play(animationToPlay)

	# Debug info
	if  debugMode:
		Debug.addComponentWatchList(self, {
			animation = animationToPlay,
			})
