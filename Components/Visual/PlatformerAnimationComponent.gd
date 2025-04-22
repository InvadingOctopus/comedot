## Tells the Entity's [AnimatedSprite2D] to play different animations based on the [member PlatformerControlComponent.lastInputDirection] movement.
## If a [PlatformerControlComponent] is not present, then [member CharacterBodyComponent.previousVelocity] is used.
## Requirements: [AnimatedSprite2D], AFTER [PlatformerControlComponent] (optional) & [CharacterBodyComponent]

class_name PlatformerAnimationComponent
extends Component

# TBD: A better name? :)


#region Parameters
## If omitted, then the parent Entity is used if it is an [AnimatedSprite2D], or then the first matching child node of the parent Entity is used, if any.
@export var animatedSprite: AnimatedSprite2D

@export var idleAnimation: StringName = &"idle"
@export var walkAnimation: StringName = &"walk"
@export var jumpAnimation: StringName = &"jump"
@export var fallAnimation: StringName = &"fall"

@export var flipWhenWalkingLeft: bool = true
@export var isEnabled: bool = true
#endregion


#region Dependencies
var characterBodyComponent:		CharacterBodyComponent
var body:						CharacterBody2D
var platformerControlComponent: PlatformerControlComponent

func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent]
#endregion


func _ready() -> void:
	if not self.animatedSprite:
		self.animatedSprite	= parentEntity.findFirstChildOfType(AnimatedSprite2D, true) # includeEntity
		if not self.animatedSprite: printWarning("Missing AnimatedSprite2D!")

	self.characterBodyComponent		= parentEntity.findFirstComponentSubclass(CharacterBodyComponent) # TBD: Include entity?
	self.body						= characterBodyComponent.body
	self.platformerControlComponent	= coComponents.get(&"PlatformerControlComponent") # Optional


func _process(_delta: float) -> void:
	if not isEnabled or not animatedSprite: return

	# INFO: Animations are checked in order of priority: "walk" overrides "idle"

	var animationToPlay: StringName

	if flipWhenWalkingLeft:
		if platformerControlComponent:
			animatedSprite.flip_h = true if signf(platformerControlComponent.lastInputDirection) < 0.0 else false
		else:
			animatedSprite.flip_h = true if characterBodyComponent.previousVelocity.x < 0 else false
		# Debug.watchList.hDirection = platformControlComponent.lastDirection

	if not idleAnimation.is_empty() \
	and body.velocity.is_zero_approx():
		animationToPlay = idleAnimation

	if not walkAnimation.is_empty() \
	and not body.velocity.is_zero_approx():
		animationToPlay = walkAnimation

	# Debug.watchList.onFloor = body.is_on_floor()

	if not characterBodyComponent.isOnFloor:
		var verticalDirection: float = signf(body.velocity.y)

		if not jumpAnimation.is_empty() \
		and verticalDirection < 0.0:
			animationToPlay = jumpAnimation
		elif not fallAnimation.is_empty() \
		and verticalDirection > 0.0:
			animationToPlay = fallAnimation

		# Debug.watchList.vDirection = verticalDirection

	animatedSprite.play(animationToPlay)
