## Plays idle/walk animations on the entity's [AnimatedSprite2D] in response to changes in an [InputComponent]'s [member InputComponent.movementDirection]
## for use in conjunction with [OverheadPhysicsComponent] or [BasicOverheadPhysicsComponent]
## A more simple alternative to [AnimationTree]
## IMPORTANT: The [AnimatedSprite2D] [SpriteFrames] animation names MUST match this specific convention:
## "idleN" for North/Up, "walkN", "idleSE" for Southeast/Down-right, "walkSE" and so on.
## TIP: If [member shouldReuseAndRotateEast] is enabled, only "idleE" & "walkE" are required.
## NOTE: If no diagonal animations are provided, diagonal movement keeps any ongoing N/E/S/W animation, unless [member shouldReuseAndRotateEast] is set.
## TIP: Use `/Scripts/Visual/CreateSpriteFramesFromSheet.gd` to automatically create [AnimatedSprite2D] [SpriteFrames] animations from a sprite sheet image
## Requirements: [AnimatedSprite2D], [InputComponent]

class_name OverheadAnimationComponent
extends AnimationComponentBase


#region Parameters

const defaultIdlePrefix := &"idle"
const defaultWalkPrefix := &"walk"
@export var idlePrefix: StringName = defaultIdlePrefix ## The prefix before the compass letters such as "N", "NE", "E" etc. for idle animation names.
@export var walkPrefix: StringName = defaultWalkPrefix ## The prefix before the compass letters such as "N", "NE", "E" etc. for walk animation names.

## If `true`, only the "idleE" & "walkE" animations are usedm and the [AnimatedSprite2D] is rotated to face other compass directions, with East = 0°
## The entity root node is NOT rotated.
## TIP: This option requires fewer animation assets and may be useful for quick prototyping etc.
## WARNING: Pixel art generally looks ugly when rotated diagonally.
@export var shouldReuseAndRotateEast: bool = false # TODO: Add option for orthogonal-only because diagonal rotation in pixel art is ugly

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
	var compassDirection:	Tools.CompassDirection = Tools.CompassDirection.none
	var compassSuffix:		StringName

	# Use the previous direction when not moving, so idle animations keep facing the previous movement direction.
	# DESIGN: Idle animations should keep facing the last movement direction.

	if  animationDirection.is_zero_approx():
		animationDirection -= difference

	if not animationDirection.is_zero_approx(): # NOTE: Don't use `else` because we want to check `animationDirection` again after the previous `if`
		# Convert the movement vector angle from radians to degrees, 
		# snap it to the nearest 45° compass step,
		# then wrap 360° back to 0°
		compassDirection = \
			wrapi(  \
				int(round(rad_to_deg(animationDirection.angle()) / Tools.degreesPerCompassDirection)) * Tools.degreesPerCompassDirection, \
			0, 360) \
			as Tools.CompassDirection

		compassSuffix = Tools.compassDirectionLetters[compassDirection]

	# Reuse "East" animations for all other directions?
	# TIP: Handy for games with simple graphics or when prototyping etc.
	if shouldReuseAndRotateEast:
		if  compassDirection == Tools.CompassDirection.none:
			compassDirection  = Tools.CompassDirection.east

		# Rotate Your Owl
		compassSuffix = Tools.compassDirectionLetters[Tools.CompassDirection.east]
		animatedSprite.rotation_degrees = float(compassDirection)

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
