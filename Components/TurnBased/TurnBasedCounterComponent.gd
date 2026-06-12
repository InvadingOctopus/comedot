## Displays a label showing the parent entity's current turn number and turn phase from when this component was last updated,
## as a debug/testing aid.

class_name TurnBasedCounterComponent
extends TurnBasedComponent


#region State
@onready var selfAsLabel: Label = self.get_node(^".") as Label
#endregion


func processTurnBegin() -> void:
	updateLabel()


func processTurnExecute() -> void:
	updateLabel()


func processTurnEnd() -> void:
	updateLabel()


func updateLabel() -> void:
	if entity is TurnBasedEntity:
		selfAsLabel.text = str(
			"T", entity.currentTurn,
			"\n", String(entity.currentTurnState).trim_prefix("turn").capitalize())
