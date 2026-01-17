## Displays a label showing the parent entity's current turn number and turn phase from when this component was last updated,
## as a debug/testing aid.

class_name TurnBasedCounterComponent
extends TurnBasedComponent


#region State
@onready var selfAsLabel: Label = self.get_node(^".") as Label
#endregion


func processTurnBegin() -> void:
	updateLabel()


func processTurnUpdate() -> void:
	updateLabel()


func processTurnEnd() -> void:
	updateLabel()


func updateLabel() -> void:
	if parentEntity is TurnBasedEntity:
		selfAsLabel.text = str(
			"T", parentEntity.currentTurn,
			"\n", TurnBasedCoordinator.turnStateNames[parentEntity.currentTurnState].capitalize())
