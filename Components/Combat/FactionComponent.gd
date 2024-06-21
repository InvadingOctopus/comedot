class_name FactionComponent
extends Component

@export_flags("neutral", "players", "playerAllies", "enemies") var factions: int = 1:
	set(newValue):
		factions = newValue
		if %DebugIndicator: %DebugIndicator.text = str(newValue)
