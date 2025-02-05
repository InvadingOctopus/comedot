## Displays messages & other UI to show the state of the turn-based system, in response to signals from its parent [TurnBasedEntity] and the global [TurnBasedCoordinator].
## IMPORTANT: Use only ONE instance of this component, on a "master" Entity which manages the turn-based UI.
## TIP: May be used as a base class for more complex turn-based UI.
## Requirements: [TurnBasedEntity]
## @experimental

class_name TurnBasedStateUIComponent
extends TurnBasedComponent

# TBD: Better name? ; — ;


#region Parameters

## The delay after updating each [TurnBasedEntity]. May be used for aesthetics or debugging.
## NOTE: Overrides [member TurnBasedCoordinator.delayBetweenEntities].
@export_range(0, 10, 0.05) var delayBetweenEntities: float = TurnBasedCoordinator.delayBetweenEntities

## The delay after each [enum TurnBasedState]. May be used for debugging.
## NOTE: The delay will occur BEFORE the [member TurnBasedCoordinator.currentTurnState] is incremented.
## NOTE: Overrides [member TurnBasedCoordinator.delayBetweenStates].
@export_range(0, 10, 0.05) var delayBetweenStates: float = TurnBasedCoordinator.delayBetweenStates

@export var colorBegin:	 Color = Color.GREEN
@export var colorUpdate: Color = Color.YELLOW
@export var colorEnd:	 Color = Color.ORANGE

@export var shouldShowMessages: bool = false
@export var shouldRepeatMessageAsLog: bool = false
#endregion


#region State
var shouldUpdateStateTimerBar:  bool = false
var shouldUpdateEntityTimerBar: bool = false
#endregion


#region UI
@onready var turnLabel: Label = %TurnLabel
@onready var stateColorRect: ColorRect = %StateColorRect
#endregion


func _ready() -> void:
	TurnBasedCoordinator.delayBetweenEntities = self.delayBetweenEntities
	TurnBasedCoordinator.delayBetweenStates = self.delayBetweenStates

	updateUI()
	initializeTimerBars()
	connectSignals()


func connectSignals() -> void:
	TurnBasedCoordinator.didAddEntity.connect(self.onTurnBasedCoordinator_didAddEntity)
	TurnBasedCoordinator.didRemoveEntity.connect(self.onTurnBasedCoordinator_didRemoveEntity)

	TurnBasedCoordinator.willBeginTurn.connect(self.onTurnBasedCoordinator_willBeginTurn)
	TurnBasedCoordinator.didBeginTurn.connect(self.onTurnBasedCoordinator_didBeginTurn)
	TurnBasedCoordinator.willUpdateTurn.connect(self.onTurnBasedCoordinator_willUpdateTurn)
	TurnBasedCoordinator.didUpdateTurn.connect(self.onTurnBasedCoordinator_didUpdateTurn)
	TurnBasedCoordinator.willEndTurn.connect(self.onTurnBasedCoordinator_willEndTurn)
	TurnBasedCoordinator.didEndTurn.connect(self.onTurnBasedCoordinator_didEndTurn)

	TurnBasedCoordinator.willProcessEntity.connect(self.onTurnBasedCoordinator_willProcessEntity)
	TurnBasedCoordinator.didProcessEntity.connect(self.onTurnBasedCoordinator_didProcessEntity)

	TurnBasedCoordinator.willStartDelay.connect(self.onTurnBasedCoordinator_willStartDelay)
	TurnBasedCoordinator.stateTimer.timeout.connect(self.onTurnBasedCoordinator_stateTimerTimeout)
	TurnBasedCoordinator.entityTimer.timeout.connect(self.onTurnBasedCoordinator_entityTimerTimeout)

	parentEntity.willBeginTurn.connect(self.onEntity_willBeginTurn)
	parentEntity.didBeginTurn.connect(self.onEntity_didBeginTurn)
	parentEntity.willUpdateTurn.connect(self.onEntity_willUpdateTurn)
	parentEntity.didUpdateTurn.connect(self.onEntity_didUpdateTurn)
	parentEntity.willEndTurn.connect(self.onEntity_willEndTurn)
	parentEntity.didEndTurn.connect(self.onEntity_didEndTurn)


#region TurnBasedCoordinator Signal Handlers

func onTurnBasedCoordinator_didAddEntity(entity: TurnBasedEntity) -> void:
	displayMessage("TurnBasedCoordinator.didAddEntity: " + entity.name, Color.GRAY, 5)


func onTurnBasedCoordinator_didRemoveEntity(entity: TurnBasedEntity) -> void:
	displayMessage("TurnBasedCoordinator.didRemoveEntity: " + entity.name, Color.GRAY, 5)


func onTurnBasedCoordinator_willBeginTurn() -> void:
	displayMessage("TurnBasedCoordinator.willBeginTurn", colorBegin, 5)
	updateUI()
	%StateDoneColorRect.visible = false


func onTurnBasedCoordinator_didBeginTurn() -> void:
	displayMessage("TurnBasedCoordinator.didBeginTurn", colorBegin, 5)
	updateUI()
	%StateDoneColorRect.visible = true


func onTurnBasedCoordinator_willUpdateTurn() -> void:
	displayMessage("TurnBasedCoordinator.willUpdateTurn", colorUpdate, 5)
	updateUI()
	%StateDoneColorRect.visible = false


func onTurnBasedCoordinator_didUpdateTurn() -> void:
	displayMessage("TurnBasedCoordinator.didUpdateTurn", colorUpdate, 5)
	updateUI()
	%StateDoneColorRect.visible = true


func onTurnBasedCoordinator_willEndTurn() -> void:
	displayMessage("TurnBasedCoordinator.willEndTurn", colorEnd, 5)
	updateUI()
	%StateDoneColorRect.visible = false


func onTurnBasedCoordinator_didEndTurn() -> void:
	displayMessage("TurnBasedCoordinator.didEndTurn", colorEnd, 5)
	updateUI()
	%StateDoneColorRect.visible = true


func onTurnBasedCoordinator_willProcessEntity(entity: TurnBasedEntity) -> void:
	displayMessage("TurnBasedCoordinator.willProcessEntity: " + entity.name, Color.GRAY, 5)
	updateUI()


func onTurnBasedCoordinator_didProcessEntity(entity: TurnBasedEntity) -> void:
	displayMessage("TurnBasedCoordinator.didProcessEntity: " + entity.name, Color.GRAY, 5)
	updateUI()

#endregion


#region Parent Entity Signal Handlers

func onEntity_willBeginTurn() -> void:
	displayMessage(parentEntity.name + ".willBeginTurn", colorBegin)

func onEntity_didBeginTurn() -> void:
	displayMessage(parentEntity.name + ".didBeginTurn", colorBegin)

func onEntity_willUpdateTurn() -> void:
	displayMessage(parentEntity.name + ".willUpdateTurn", colorUpdate)

func onEntity_didUpdateTurn() -> void:
	displayMessage(parentEntity.name + ".didUpdateTurn", colorUpdate)

func onEntity_willEndTurn() -> void:
	displayMessage(parentEntity.name + ".willEndTurn", colorEnd)

func onEntity_didEndTurn() -> void:
	displayMessage(parentEntity.name + ".didEndTurn", colorEnd)

#endregion


#region Component TUrn Cycle

func processTurnBegin() -> void:
	displayMessage(str(self.name, ".processTurnBegin()"), colorBegin)


func processTurnUpdate() -> void:
	displayMessage(str(self.name, ".processTurnUpdate()"), colorUpdate)


func processTurnEnd() -> void:
	displayMessage(str(self.name, ".processTurnEnd()"), colorEnd)

#endregion


#region UI

## @experimental
func updateUI() -> void:
	var currentEntityName: String = TurnBasedCoordinator.currentEntityProcessing.name if TurnBasedCoordinator.currentEntityProcessing else &""
	var nextEntityName: String = TurnBasedCoordinator.nextEntityToProcess.name

	turnLabel.text = str(
		"TURN#%02d: " % TurnBasedCoordinator.currentTurn,
		currentEntityName, " > ", nextEntityName)

	match TurnBasedCoordinator.currentTurnState:
		TurnBasedCoordinator.TurnBasedState.turnBegin:  stateColorRect.color = colorBegin
		TurnBasedCoordinator.TurnBasedState.turnUpdate: stateColorRect.color = colorUpdate
		TurnBasedCoordinator.TurnBasedState.turnEnd:	stateColorRect.color = colorEnd
		_: stateColorRect.color = Color.GRAY


func displayMessage(message: String, color: Color = Color.GRAY, outlineSize: int = -1) -> void:
	if not shouldShowMessages:   return
	if shouldRepeatMessageAsLog: self.printLog(message)

	var labelSettings: LabelSettings = GlobalUI.createTemporaryLabel(message).label_settings
	labelSettings.font_color = color
	if outlineSize >= 0: labelSettings.outline_size = outlineSize

#endregion


#region Timers

func initializeTimerBars() -> void:
	%StateTimerBar.max_value	= TurnBasedCoordinator.stateTimer.wait_time
	%StateTimerBar.value		= TurnBasedCoordinator.stateTimer.time_left
	%EntityTimerBar.max_value	= TurnBasedCoordinator.entityTimer.wait_time
	%EntityTimerBar.value		= TurnBasedCoordinator.entityTimer.time_left
	shouldUpdateStateTimerBar	= not TurnBasedCoordinator.stateTimer.is_stopped()
	shouldUpdateEntityTimerBar	= not TurnBasedCoordinator.entityTimer.is_stopped()


func onTurnBasedCoordinator_willStartDelay(timer: Timer) -> void:
	initializeTimerBars() # Update the bars no matter which timer it is.
	# NOTE: Re-evaluate the flags because they will be set to `false` by initializeTimerBars() because the signal is emitted BEFORE the Timer starts :)
	shouldUpdateStateTimerBar  = (timer == TurnBasedCoordinator.stateTimer)
	shouldUpdateEntityTimerBar = (timer == TurnBasedCoordinator.entityTimer)


func _process(_delta: float) -> void:
	if shouldUpdateStateTimerBar:  %StateTimerBar.value  = TurnBasedCoordinator.stateTimer.time_left
	if shouldUpdateEntityTimerBar: %EntityTimerBar.value = TurnBasedCoordinator.entityTimer.time_left


func onTurnBasedCoordinator_stateTimerTimeout() -> void:
	self.shouldUpdateStateTimerBar = false


func onTurnBasedCoordinator_entityTimerTimeout() -> void:
	self.shouldUpdateEntityTimerBar = false

#endregion
