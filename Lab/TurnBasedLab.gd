## A temporary scene for testing new [TurnBasedComponent]s.
## For core tests, see `//Tests/TurnBased/TurnBasedTest.tscn`

extends Start


func onNextTurnButton_pressed() -> void:
	TurnBasedCoordinator.startTurnProcess()
