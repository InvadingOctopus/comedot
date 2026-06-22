## Takes player/AI input from an [InputComponent] to modify the [Entity]'s position on a [TileMapLayer] via a [TileBasedPositionComponent]
## TIP: For random monster/NPC movement see [TileBasedRandomMovementComponent] or [RandomInputComponent]
## Requirements: [TileBasedPositionComponent], [InputComponent]

class_name TileBasedControlComponent
extends TileBasedControlComponentBase

# TODO: Allow movement on input `is_just_released`


#region Parameters
## If `false` (default) then pressing 2 inputs such as Up+Right will result in NO movement.
@export var shouldAllowDiagonals:	bool = false
#endregion


#region Dependencies
@onready var inputComponent: InputComponent = getCoComponent(InputComponent, true) # findSubclasses

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent, InputComponent]
#endregion


func _ready() -> void:
	super._ready()

	# Check if an input already pressed before this component was ready
	# TBD: inputComponent.resyncAllInputs()?
	if not inputComponent.movementDirection.is_zero_approx():
		self.onInputComponent_didProcessInput(null)


#region Input

func toggleSignals() -> void:
	super.toggleSignals()
	Tools.toggleSignal(inputComponent.didProcessInput,					self.onInputComponent_didProcessInput,					self.isEnabled)
	# TRIED: Tools.toggleSignal(inputComponent.didUpdateMovementDirection,self.onInputComponent_didUpdateMovementDirection,		self.isEnabled) # Can't use because this cannot detect press/release


func onInputComponent_didProcessInput(event: InputEvent) -> void:
	# TRIED: Cannot use `inputComponent.didUpdateMovementDirection` because we need to detect press↔release transitions
	if not isEnabled: return

	# TODO: Add a little delay before processing input so the player has time to input diagonal movement instead of moving on the first orthogonal keypress.
	# TBD: PERFORMANCE: Check for presses & releases only, or accept analog input too?
	# TBD: PERFORMANCE: Use GlobalInput.hasActionTransitioned()?

	# Manually stop echoes in case `inputComponent.shouldIgnoreEchoes` is `false`
	if not shouldRepeatOnHeldInput and event and event.is_echo(): return

	# DESIGN: Held input is not resumed after unpause/re-enable & requires a new movement press, as that would be the more intuitive behavior, # TBD: right?
	if inputComponent.movementDirection.is_zero_approx():
		self.gridMovementVector = Vector2i.ZERO
		return

	# Move only on the relevant input, to avoid movement when other input like jump/fire/etc. is pressed
	# Include button/key releases too
	# Allow null events for the initial sync on _ready()
	if event == null \
	or event.is_action(GlobalInput.Actions.moveLeft)  \
	or event.is_action(GlobalInput.Actions.moveRight) \
	or event.is_action(GlobalInput.Actions.moveUp)    \
	or event.is_action(GlobalInput.Actions.moveDown): 
		
		var newVector: Vector2i = self.chooseDiagonalOrOrthogonal()

		if newVector == Vector2i.ZERO:
			setMovementVector(Vector2i.ZERO) # Also resets queued movement
		elif shouldRepeatOnHeldInput or event == null or event.is_pressed(): # Non-repeated movement on input press only
			setMovementVector(newVector)


## Chooses between orthogonal or diagonal movement depending on [member shouldAllowDiagonals]
func chooseDiagonalOrOrthogonal() -> Vector2i:
	if shouldAllowDiagonals:
		return Vector2i(int(signf(inputComponent.movementDirection.x)), int(signf(inputComponent.movementDirection.y)))
	else:
		# NOTE: If diagonals are not allowed, fractional axis values will get zeroed when converted to Vector2i integers,
		# so a normalized diagonal input from Input.get_vector() such as Up+Right = (0.707,-0.707) will become (0,0)
		# TBD: Fix <1 analog joystick input?
		return inputComponent.movementDirection # NOTE: No need to explicitly cast float Vector2 to Vector2i because we want truncation

#endregion


#region Movement

## Called by the [TileBasedControlComponentBase] superclass to reapply the current [member InputComponent.movementDirection] for held-input repeated movement if [member shouldRepeatOnHeldInput]
func getRepeatedMovementVector() -> Vector2i:
	return chooseDiagonalOrOrthogonal()

#endregion
