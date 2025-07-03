## Displays a targeting reticle controlled by the Right Joystick or mouse, for aiming [GunComponent] etc.
## Effectively combines some of the behaviors of [MouseTrackingComponent] + [PositionControlComponent] + [TetherComponent] + [NodeFacingComponent] + [StationaryHidingPositionControlComponent].
## TIP: To automatically hide the cursor when there is no movement, use [StationaryHidingPositionControlComponent].
## Requirements: BEFORE [InputComponent]

class_name AimingCursorComponent
extends Component


#region Parameters

const animationDuration: float = 0.5 # For hiding/showing

@export_range(0.0, 1000.0, 10.0) var speed: float = 300
@export_range(0.0, 1000.0, 8.0)  var maximumDistanceFromEntity: float = 96

## If `true`, then the cursor instantly snaps to the edge of the circle defined by [member maximumDistanceFromEntity],
## corresponding to the Right Joystick's [member InputComponent.aimDirection] SNAPPED to 0 or 1, i.e. if the joystick is up (at any strength) then the cursor will be at (0, -max).
## When the aiming joystick is released the cursor will snap back to the center.
## NOTE: Supersedes [member shouldUseAbsolutePosition].
@export var shouldSnapToMaximumDistance: bool = false

## If `true` (default) then the cursor will match the Right Joystick's ABSOLUTE [member InputComponent.aimDirection] within the circle defined by [member maximumDistanceFromEntity].
## e.g. if the joystick is moved up halfway then the cursor will be at (0, -max/2).
## When the aiming joystick is released the cursor will snap back to the center.
## ALERT: Superseded by [member shouldSnapToMaximumDistance].
@export var shouldUseAbsolutePosition:   bool = true

## For mouse control, this flag instantly sets the cursor's position to the mouse pointer on every frame, instead of moving gradually at [member speed].
## Not used when [member InputComponent.shouldSuppressMouse].
@export var shouldSnapToMouse:			 bool = true

## Optional. A node such as [GunComponent] to face towards this component's sprite.
## TIP: [NodeFacingComponent] is a more advanced component for rotating any node to face another node.
@export var nodeToRotate:				 Node2D # DESIGN: We don't need rotational speed parameters etc. because gradual movement is already incorporated into this component's behavior.


## Hides the cursor when there is no movement input. Any aiming input will make make the cursor visible again.
@export var shouldHideIfNotMoving:		 bool = true
@export var shouldHideOnReady:			 bool = true

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process(isEnabled)
			self.visible = isEnabled

#endregion


#region State
@onready var selfAsSprite: Sprite2D = self.get_node(^".") as Sprite2D
@onready var hidingTimer:  Timer = $HidingTimer
var tween: Tween
#endregion


#region Dependencies
@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent)
func getRequiredComponents() -> Array[Script]:
	return [InputComponent]
#endregion


func _ready() -> void:
	selfAsSprite.visible = self.shouldHideOnReady
	if shouldHideIfNotMoving and selfAsSprite.visible: hidingTimer.start()

	# Apply setters because Godot doesn't on initialization
	self.set_process(isEnabled)
	self.set_process_input(shouldHideIfNotMoving and not inputComponent.shouldSuppressMouseMotion)

	Tools.connectSignal(inputComponent.didToggleMouseSuppression, self.onInputComponent_didToggleMouseSuppression)


func onInputComponent_didToggleMouseSuppression(shouldSuppressMouse: bool) -> void:
	self.set_process_input(shouldHideIfNotMoving and not shouldSuppressMouse)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not selfAsSprite.visible or not hidingTimer.is_stopped(): # Halt any ongoing hiding animation
		self.show()


func _process(delta: float) -> void:
	# Using the joystick?
	if inputComponent.shouldSuppressMouseMotion:

		if not inputComponent.aimDirection.is_zero_approx():

			if not selfAsSprite.visible or not hidingTimer.is_stopped(): # Halt any ongoing hiding animation
				self.show()

			if shouldSnapToMaximumDistance:
				selfAsSprite.position  = inputComponent.aimDirection.snappedf(1.0) * maximumDistanceFromEntity

			elif shouldUseAbsolutePosition:
				selfAsSprite.position  = selfAsSprite.position.move_toward(inputComponent.aimDirection * maximumDistanceFromEntity, speed * delta)

			else:
				selfAsSprite.position += inputComponent.aimDirection * self.speed * delta
				selfAsSprite.global_position += Tools.clampPositionToAnchor(selfAsSprite, parentEntity, self.maximumDistanceFromEntity)

	# Following the mouse?
	else:
		# NOTE: Hide/Show is done in _input() because mouse motion is messy

		if shouldSnapToMouse:
			selfAsSprite.global_position = selfAsSprite.get_global_mouse_position()
		else:
			selfAsSprite.global_position = selfAsSprite.global_position.move_toward(selfAsSprite.get_global_mouse_position(), speed * delta)

		selfAsSprite.global_position += Tools.clampPositionToAnchor(selfAsSprite, parentEntity, self.maximumDistanceFromEntity)

	self.reset_physics_interpolation() # NOTE: CHECKED: This is necessary otherwise the node will be at an intermediate position for at least 1 frame.

	if nodeToRotate: nodeToRotate.look_at(selfAsSprite.global_position)



#region Visibility

func show() -> void:
	# TBD: Animate?

	# Halt any ongoing hiding animation
	if not hidingTimer.is_stopped(): hidingTimer.stop()
	if tween: tween.kill()

	# Just modify the alpha of the current modulate to maintain the tint
	selfAsSprite.modulate = Color(selfAsSprite.modulate, 1.0)
	selfAsSprite.visible  = true

	# PERFORMANCE: Start the disappearance countdown immediately, so we don't have to keep rechecking for input
	if shouldHideIfNotMoving: hidingTimer.start()


func hide() -> void:
	if tween: tween.kill()
	tween = selfAsSprite.create_tween()

	# Just modify the alpha of the current modulate to maintain the tint
	tween.tween_property(selfAsSprite, "modulate", Color(selfAsSprite.modulate, 0), animationDuration)
	tween.tween_property(selfAsSprite, "visible",  false, 0)


func onHidingTimer_timeout() -> void:
	self.hide()

#endregion
