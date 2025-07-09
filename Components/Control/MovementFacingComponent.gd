## Rotates a node based on an [InputComponent]'s movement direction as per [member InputComponent.horizontalInput] and/or [member InputComponent.verticalInput].
## TIP: EXAMPLE USAGE: Apply to a [GunComponent] in platformer games, to make the player shoot in the direction the character was walking in.
## Requirements: BEFORE [InputComponent]

class_name MovementFacingComponent
extends Component


#region Parameters
@export var nodeToRotate:				Node2D		## If not specified, the parent Entity is used.
@export var shouldFaceHorizontalInput:	bool = true ## Rotate the [member nodeToRotate] to face an [InputComponent]'s [member InputComponent.horizontalInput]. TIP: Always enable in platformer games.
@export var shouldFaceVerticalInput:	bool = true ## Rotate the [member nodeToRotate] to face an [InputComponent]'s [member InputComponent.verticalInput].
#endregion


#region Dependencies
@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent)

func getRequiredComponents() -> Array[Script]:
	return [InputComponent]
#endregion


func _ready() -> void:
	if not nodeToRotate: nodeToRotate = parentEntity
	if inputComponent: Tools.connectSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput)
	else: printWarning(str("Missing InputComponent in ", parentEntity.logFullName))


func onInputComponent_didProcessInput(_event: InputEvent) -> void:
	if not inputComponent.movementDirection.is_zero_approx(): faceInputDirection()


func faceInputDirection() -> void:
	nodeToRotate.rotation = Vector2(
		inputComponent.horizontalInput * int(shouldFaceHorizontalInput), # PERFORMANCE: AWESOME: Branchless boolean checks! ^ — ^
		inputComponent.verticalInput   * int(shouldFaceVerticalInput)).angle()
