## Animates the Entity's [AnimatedSprite2D] based on the [TileBasedPositionComponent]'s movement.
## Requirements: [TileBasedPositionComponent], [AnimatedSprite2D]

class_name TileBasedAnimationComponent
extends Component


#region Parameters
@export var idleAnimation: StringName = &"idle"
@export var walkAnimation: StringName = &"walk"

@export var flipWhenWalkingLeft: bool = true
@export var isEnabled := true
#endregion


#region Dependencies

@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent # TBD: Static or dynamic?

var animatedSprite: AnimatedSprite2D:
	get:
		if not animatedSprite: animatedSprite = parentEntity.findFirstChildOfType(AnimatedSprite2D)
		return animatedSprite

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent]

#endregion


func _ready() -> void:
	tileBasedPositionComponent.willStartMovingToNewCell.connect(onTileBasedPositionComponent_willStartMovingToNewCell)
	tileBasedPositionComponent.didArriveAtNewCell.connect(onTileBasedPositionComponent_didArriveAtNewCell)


func onTileBasedPositionComponent_willStartMovingToNewCell(_newDestination: Vector2i) -> void:
	if not isEnabled: return

	animatedSprite.play(walkAnimation)

	if flipWhenWalkingLeft:
		# Maintain the flip when moving vertically only
		animatedSprite.flip_h = (tileBasedPositionComponent.inputVector.x < 0) \
			or (animatedSprite.flip_h and not tileBasedPositionComponent.inputVector.x > 0)


func onTileBasedPositionComponent_didArriveAtNewCell(_newDestination: Vector2i) -> void:
	if not isEnabled: return

	animatedSprite.play(idleAnimation)
