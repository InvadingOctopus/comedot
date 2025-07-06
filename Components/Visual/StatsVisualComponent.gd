## Emits [TextBubble]s and displays other UI over the Entity whenever one of the chosen [Stat]s changes in value.
## NOTE: The visuals are displayed at the position of the component, not the entity, so they may be offset from the entity's position.
## NOTE: The bubble is emitted from COLLECTOR Entity, NOT the collectible item. To display [Stat]-related bubbles from collectibles, use [CollectibleStatComponent].
## TIP:  To suppress indicators for specific [Stat]s, use [member Stat.shouldSkipEmittingNextChange], as done by [InteractionWithCostComponent] in case of refunds if a [Payload] fails.

class_name StatsVisualComponent
extends Component

# TODO: Avoid overlapping bubbles
# TODO: Add attached [StatsList]
# TODO: Support array additions at runtime


#region Parameters
@export var isEnabled:				 bool = true
@export_group("Stats")
@export var statsToMonitor:			 Array[Stat]
@export var statsToExclude:			 Array[Stat]
@export var shouldCopyFromStatsComponent: bool = true # If `true` then [member statsToMonitor] will include the Stats from an [StatsComponent], if any.
@export_group("Visual")
@export var shouldAppendDisplayName: bool = false
@export var shouldColorBubble:		 bool = true
#endregion


#region Dependencies
var statsComponent: StatsComponent:
	get:
		if not statsComponent: statsComponent = coComponents.get(&"StatsComponent")
		return statsComponent
#endregion


func _ready() -> void:
	if shouldCopyFromStatsComponent and statsComponent:
		self.statsToMonitor.append_array(statsComponent.stats) # NOTE: append, don't override :)
	if debugMode: printDebug(str(statsToMonitor, ", exclude: ", statsToExclude))
	connectSignals()


func connectSignals() -> void:
	for stat in statsToMonitor:
		if not statsToExclude.has(stat):
			Tools.connectSignal(stat.changed, self.onStatChanged.bind(stat))


func onStatChanged(stat: Stat) -> void:
	# Double-check if the Stat is in the array, to support removals during runtime.
	if not statsToMonitor.has(stat):
		Tools.disconnectSignal(stat.changed, self.onStatChanged)
		return
	if not isEnabled and not statsToExclude.has(stat): return

	GameplayResourceBubble.createForStatChange(stat, self, Vector2(0, -16), shouldAppendDisplayName, shouldColorBubble) # TBD: Put a space between text & number?
