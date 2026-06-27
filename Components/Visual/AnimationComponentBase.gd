## An abstract base class for other components which require an [AnimatedSprite2D]
## such as [PlatformerAnimationComponent] or [OverheadAnimationComponent] etc.
## Requirements: [AnimatedSprite2D]

@abstract class_name AnimationComponentBase
extends Component


#region Parameters

## If omitted, then the parent Entity's [member Entity.sprite] property is used, or the Entity node ITSELF if it is an [AnimatedSprite2D], otherwise the first matching child node of the Entity is used, if any.
@export var animatedSprite: AnimatedSprite2D:
	set(newValue):
		if newValue != animatedSprite:
			animatedSprite = newValue
			self.set_physics_process(is_instance_valid(animatedSprite) and isEnabled)

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_physics_process(isEnabled and is_instance_valid(animatedSprite))

#endregion


func _ready() -> void:
	entity.getSprite() # Let the Entity decide its own sprite, even if it's just a Sprite2D, so we can flip it when the direction changes

	if not self.animatedSprite: # If this component's property is unspecified
		if entity.sprite is AnimatedSprite2D: # Try the Entity's sprite in case it's animated
			self.animatedSprite	= entity.sprite
		if not self.animatedSprite: # Find some other AnimatedSprite2D if it'the Entity's primary sprite isn't one
			self.animatedSprite	= entity.findFirstChildOfType(AnimatedSprite2D, true) # includeEntity
		if not self.animatedSprite: printWarning("Missing AnimatedSprite2D")

	self.set_physics_process(isEnabled and is_instance_valid(animatedSprite))
