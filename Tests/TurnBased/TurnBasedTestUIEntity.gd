## Tests the turn-based system. For use in [TurnBasedTest.tscn]
## @experimental

class_name TurnBasedTestUIEntity
extends TurnBasedEntity


func _enter_tree() -> void:
	super._enter_tree()


func _ready() -> void:
	TurnBasedCoordinator.entityTimer.wait_time = 3
	TurnBasedCoordinator.stateTimer.wait_time  = 3


func connectSignals() -> void:
	TurnBasedCoordinator.willBeginTurn.connect(self.onTurnBasedCoordinator_willBeginTurn)
	TurnBasedCoordinator.didEndTurn.connect(self.onTurnBasedCoordinator_didEndTurn)


func onNextTurnButton_pressed() -> void:
	TurnBasedCoordinator.startTurn()


func onTurnBasedCoordinator_willBeginTurn() -> void:
	pass


func processTurnBegin() -> void:
	%NextTurnButton.disabled = true
	%ExecuteLabel.visible = false
	%EndLabel.visible = false

	%BeginLabel.text = str("TURN ", currentTurn, " START")
	%BeginLabel.visible = true

	%UIAnimationPlayer.play(&"showBeginLabel")
	await %UIAnimationPlayer.animation_finished

	%UITimer.start()
	await %UITimer.timeout

	%BeginLabel.text = str("GET READY")
	#%BeginLabel.visible = false
	super.processTurnBegin()


func processTurnExecute() -> void:
	%BeginLabel.modulate.a = 0
	%ExecuteLabel.visible = true
	super.processTurnExecute()
	if not is_zero_approx(TurnBasedCoordinator.entityTimer.wait_time):
		Tools.skipTimer(TurnBasedCoordinator.entityTimer)


func processTurnEnd() -> void:
	%ExecuteLabel.modulate.a = 0
	%EndLabel.visible = true
	super.processTurnEnd()


func onTurnBasedCoordinator_didEndTurn() -> void:
	%UITimer.start()
	await %UITimer.timeout
	%ExecuteLabel.visible = false
	%EndLabel.visible = false
	%NextTurnButton.disabled = false
