## Applies gravity to the parent entity's [CharacterBody2D] every frame.
## WARNING: Do NOT use in conjunction with [PlatformerPhysicsComponent] because that component also processes gravity.
## Requirements: Entity with [CharacterBody2D]. Must precede -ControlComponents

class_name GravityComponent
extends CharacterBodyDependentComponentBase


#region Parameters
@export var isEnabled := true

## 1.0 is normal gravity as defined in Project Settings/Physics/2D
@export_range(-10, 10, 0.05) var gravityScale: float = 1.0

var gravity: float = Settings.gravity
#endregion


func _ready() -> void:
	if parentEntity.body:
		printLog("parentEntity.body.motion_mode → Grounded")
		parentEntity.body.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	else:
		printWarning("Missing parentEntity.body: " + parentEntity.logName)

	if coComponents.get("PlatformerPhysicsComponent"):
		printWarning("GravityComponent & PlatformerPhysicsComponent both process gravity; Remove one!")


func _physics_process(delta: float) -> void:
	# DEBUG: printLog("_physics_process()")
	if not isEnabled: return

	if not characterBodyComponent.isOnFloor:
		body.velocity.y += (gravity * gravityScale) * delta

	characterBodyComponent.queueMoveAndSlide()
