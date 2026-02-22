## Emits [TextBubble]s and displays other UI over the Entity whenever one of the chosen [Stat]s changes in value.
## NOTE: The visuals are displayed at the position of the component, not the entity, so they may be offset from the entity's position.
## NOTE: The bubble is emitted from COLLECTOR Entity, NOT the collectible item. To display [Stat]-related bubbles from collectibles, use [CollectibleStatComponent].

class_name StatsVisualComponent
extends Component

# TODO: Avoid overlapping bubbles
# TODO: Add attached [StatsList]
# TODO: Support array additions at runtime


#region Parameters

@export var isEnabled:				 bool = true

@export_group("Stats")
@export var statsToMonitor:			 Array[Stat] ## ALERT: Superceded by [member statsToExclude],
@export var statsToExclude:			 Array[Stat] ## ALERT: Supercedes entries in [member statsToMonitor],

## If `true` then [member statsToMonitor] will include the [Stat]s from an [StatsComponent], if any.
## IMPORTANT: TIP: Enable this if any of the relevant Stats are "Local to Scene" [member Resource.resource_local_to_scene] because the [Stat]s added via the Godot Editor Inspector may not match the locally-unique runtime instance.
@export var shouldCopyFromStatsComponent: bool = true

@export_group("Visual")
@export var shouldAppendDisplayName: bool = false
@export var shouldDisplayChange:	 bool = true ## If `true` (default) then the CHANGE in value is displayed e.g. "+1" or "-1". If `false` then the exact value is displayed.
@export var shouldColorBubble:		 bool = true
@export var customAnimation:		 StringName  ## An optional name of a method in `Animations.gd` to call on the [GameplayResourceBubble]. Example: `blink`

#endregion


#region Dependencies
var statsComponent: StatsComponent:
	get:
		if not statsComponent: statsComponent = coComponents.get(&"StatsComponent")
		return statsComponent
#endregion


func _ready() -> void:
	if shouldCopyFromStatsComponent and statsComponent:
		for stat in statsComponent.stats:
			if not self.statsToExclude.has(stat): # Respect exclusions instead of just adding everything with append_array()
				self.statsToMonitor.append(stat)

	if debugMode: printDebug(str(statsToMonitor, ", exclude: ", statsToExclude))
	connectSignals()


func connectSignals() -> void:
	for stat in statsToMonitor:
		if not statsToExclude.has(stat): # TBD: Check again or just let _ready() take care of it?
			Tools.connectSignal(stat.changed, self.onStatChanged.bind(stat))


func onStatChanged(stat: Stat) -> void:
	# Double-check if the Stat is in the array, to support removals during runtime.
	if not statsToMonitor.has(stat):
		Tools.disconnectSignal(stat.changed, self.onStatChanged)
		return
	if not isEnabled and not statsToExclude.has(stat): return

	var bubble: GameplayResourceBubble

	# TBD: Put a space between text & number?
	if shouldDisplayChange: bubble = GameplayResourceBubble.createForStatChange(stat, self, Vector2(0, -16), shouldAppendDisplayName, shouldColorBubble)
	else: bubble = GameplayResourceBubble.createForStat(stat, self, Vector2(0, -16), shouldAppendDisplayName, shouldColorBubble)

	if customAnimation: Tools.callCustom(Animations, customAnimation, bubble)
