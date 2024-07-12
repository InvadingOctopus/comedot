## Applies gravity to the parent entity's [CharacterBody2D] every frame.
## WARNING: Do NOT use in conjuction with [PlatformerPhysicsComponent], as that component also processes gravity.
## Requirements: Entity with [CharacterBody2D]. Must precede -ControlComponents

class_name GravityComponent
extends CharacterBodyManipulatingComponentBase


#region Parameters
@export var isEnabled := true

## 1.0 is normal gravity as defined in Project Settings/Physics/2D
@export_range(-10, 10, 0.05) var gravityScale: float = 1.0

var gravity: float = ProjectSettings.get_setting(Global.SettingsPaths.gravity)
#endregion


#region State
#endregion


func getRequiredComponents() -> Array[Script]:
	return [CharacterBodyComponent]


func _ready() -> void:
	if parentEntity.body:
		printLog("parentEntity.body.motion_mode → Grounded")
		parentEntity.body.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	else:
		printWarning("Missing parentEntity.body: " + parentEntity.logName)


func _physics_process(delta: float) -> void:
	# DEBUG: printLog("_physics_process()")
	if not isEnabled: return
	processGravity(delta)
	characterBodyComponent.queueMoveAndSlide()


func processGravity(delta: float):
	# Vertical Slowdown
	if not characterBodyComponent.isOnFloor:
		body.velocity.y += (gravity * gravityScale) * delta
