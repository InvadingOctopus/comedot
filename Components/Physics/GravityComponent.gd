## Applies gravity to the parent entity's [CharacterBody2D] every frame.
## Requirements: Entity with CharacterBody2D


class_name GravityComponent
extends BodyComponent


#region Parameters
@export var isEnabled := true

## 1.0 is normal gravity as defined in Project Settings/Physics/2D
@export_range(0,  10, 0.05) var gravityScale: float = 1.0
#endregion


#region State
var gravity: float = ProjectSettings.get_setting(Global.SettingsPaths.gravity)
#endregion


func _ready() -> void:
	if parentEntity.body:
		printLog("parentEntity.body.motion_mode → Grounded")
		parentEntity.body.motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	else:
		printWarning("Missing parentEntity.body: " + parentEntity.logName)


func _physics_process(delta: float):
	if not isEnabled: return
	processGravity(delta)
	parentEntity.callOnceThisFrame(body.move_and_slide)


func processGravity(delta: float):
	# Vertical Slowdown
	if not body.is_on_floor(): # NOTE: Cache [isOnFloor] after processing gravity.
		body.velocity.y += (gravity * gravityScale) * delta
