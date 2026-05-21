## Takes player/AI input from an [InputComponent] to modify the [Entity]'s position on a [TileMapLayer] via a [TileBasedPositionComponent]
## Requirements: [TileBasedPositionComponent], [InputComponent]

class_name TileBasedControlComponent
extends Component

# TODO: Allow movement on input `is_just_released`


#region Parameters

@export var shouldAllowDiagonals:	bool = false ## If `false` (default) then pressing 2 inputs such as Up+Right will result in NO movement.

@export var shouldMoveContinuously:	bool = true: ## If `true` then the entity keeps moving as long as the input direction is pressed. If `false` then the input must be released before moving again.
	set(newValue):
		if newValue != shouldMoveContinuously:
			shouldMoveContinuously = newValue
			self.set_physics_process(hasInput and isEnabled and shouldMoveContinuously)

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_physics_process(isEnabled and hasInput and shouldMoveContinuously)
			if self.is_node_ready(): Tools.toggleSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput, self.isEnabled)
			# TBD: Resync & poll InputComponent when re-enabled? or require a new press?
			if not isEnabled: recentInputVector = Vector2.ZERO

#endregion


#region State
var recentInputVector: Vector2i:
	set(newValue):
		if newValue != recentInputVector:
			if debugMode: Debug.printChange("recentInputVector", recentInputVector, newValue, self.debugModeTrace) # logAsTrace
			recentInputVector = newValue
			hasInput = recentInputVector.length_squared() != 0 # PERFORMANCE: length_squared() is faster than length() CHECK: Does this cause any false positives?
			self.set_physics_process(hasInput and isEnabled and shouldMoveContinuously)

var hasInput: bool   = recentInputVector.length_squared() != 0 # DESIGN: "has" instead of "have" so we can write "if someComponent.hasSomething" :)

@onready var stepTimer: Timer = self.get_node(^".") as Timer
#endregion


#region Dependencies
@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent
@onready var inputComponent:			 InputComponent = getCoComponent(InputComponent, true) # findSubclasses

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent, InputComponent]
#endregion


func _ready() -> void:
	# Apply setters because Godot doesn't on initialization
	self.set_physics_process(hasInput and isEnabled and shouldMoveContinuously)
	Tools.toggleSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput, self.isEnabled)

	# TBD: inputComponent.resyncInput()?
	# NOTE: Was an input already pressed before this component was ready?
	if not inputComponent.movementDirection.is_zero_approx():
		self.onInputComponent_didProcessInput(null)


#region Input

func onInputComponent_didProcessInput(event: InputEvent) -> void:
	if not isEnabled: return

	# TBD: PERFORMANCE: Check for presses & releases only, or accept analog input too?
	# TBD: PERFORMANCE: Use GlobalInput.hasActionTransitioned()?

	# Manually stop echoes in case `inputComponent.shouldIgnoreEchoes` is `false`
	if not shouldMoveContinuously and event and event.is_echo(): return

	# NOTE: InputComponent emits "dummy" InputEventAction.new() events after clearing state on disable/pause.
	# DESIGN: Held input is not resumed after unpause/re-enable & requires a new movement press, as that would be the more intuitive behavior, # TBD: right?
	if inputComponent.movementDirection.is_zero_approx():
		self.recentInputVector = Vector2.ZERO
		return

	# Move only on the relevant input, to avoid movement when other input like jump/fire/etc. is pressed
	# Include button/key releases too
	# Allow null events for the inital sync on _ready()
	if event == null \
	or event.is_action(GlobalInput.Actions.moveLeft)  \
	or event.is_action(GlobalInput.Actions.moveRight) \
	or event.is_action(GlobalInput.Actions.moveUp)    \
	or event.is_action(GlobalInput.Actions.moveDown): 
	
		if shouldAllowDiagonals:
			self.recentInputVector = Vector2i(int(signf(inputComponent.movementDirection.x)), int(signf(inputComponent.movementDirection.y)))
		else:
			# NOTE: Fractional axis values will get zeroed in the conversion to integers,
			# so a normalized diagonal input from Input.get_vector() such as Up+Right = (0.707,-0.707) will become (0,0) 
			# TBD: Fix <1 analog joystick input?
			self.recentInputVector = inputComponent.movementDirection # CHECK: No need to explicitly cast float Vector2 to Vector2i, right?

		if hasInput and (shouldMoveContinuously or event == null or event.is_pressed()): # Non-repeated movement on input press only
			move()

#endregion


#region Movement

func _physics_process(_delta: float) -> void:
	# NOTE: `isEnabled` and `shouldMoveContinuously` checked by property setters
	move() # `hasInput` is checked by move() and set_physics_process()
	if debugMode: showDebugInfo()


## Tells the [TileBasedPositionComponent] to move to the [member recentInputVector]
## Uses a [Timer] to add a delay between each step.
## NOTE: Does NOT check [member isEnabled]
func move() -> void:
	if not self.hasInput \
	or not is_zero_approx(stepTimer.time_left) \
	or not tileBasedPositionComponent.tileMap:
		return

	tileBasedPositionComponent.inputVector = self.recentInputVector
	if tileBasedPositionComponent.processInput():
		stepTimer.start() # NOTE: Start the cooldown only if the new destination is accepted, to avoid input lag after blocked moves or slow tile animations.

#endregion


func showDebugInfo() -> void:
	# if not debugMode: return # Checked by caller
	Debug.addComponentWatchList(self, {
		recentInputVector	= recentInputVector,
		stepTimer			= stepTimer.time_left })
