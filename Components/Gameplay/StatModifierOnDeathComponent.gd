## Modifies [Stat] Resources when the parent Entity's [HealthComponent] drops to 0.
## May be used for incrementing the player's score and XP when a monster is killed, or decreasing the player's lives when an ally NPC is killed, etc.
## TIP: To modify Stats repeatedly based on a time interval, such as draining/healing a character's life or mana etc., use [StatModifierComponent].

class_name StatModifierOnDeathComponent
extends Component


#region Parameters
@export var statsToModify:		Dictionary[Stat, int] ## A [Dictionary] where the keys are [Stat] Resources and the values are the positive or negative modifier to apply to that respective Stat.
@export var shouldEmitBubble:	bool = true ## Spawns a visual [TextBubble] saying the Stat's name and change in value that floats up from the Entity.
@export var shouldColorBubble:	bool = true
@export var isEnabled:			bool = true
#endregion


#region Dependencies
@onready var healthComponent: HealthComponent = parentEntity.findFirstComponentSubclass(HealthComponent) ## May be a subclass such as [ShieldedHealthComponent].
func getRequiredComponents() -> Array[Script]:
	return [HealthComponent]
#endregion


func _ready() -> void:
	healthComponent.healthDidZero.connect(self.onHealthComponent_healthDidZero)


func onHealthComponent_healthDidZero() -> void:
	modifyStats()


func modifyStats() -> void:
	var bubbleOffsetY: float = 0
	for stat in statsToModify:
		stat.value += statsToModify[stat]
		if shouldEmitBubble:
			# NOTE: Check the `Stat.previousChange` to see the actual difference in value instead of just the modifier we attempted to apply.
			# NOTE: Spawn the Bubble in the Entity's parent, not as a child of the Entity itself, as we're about to die anyway :'(
			# TBD:  Put a space between text & number?
			var labelSettings: LabelSettings = TextBubble.create( \
				str(stat.displayName, "%+d" % stat.previousChange), \
				parentEntity.get_parent(), \
				Vector2(parentEntity.position.x, parentEntity.position.y + bubbleOffsetY)) \
					.label.label_settings
			if shouldColorBubble:
				if   stat.previousChange > 0: labelSettings.font_color = Color.GREEN
				elif stat.previousChange < 0: labelSettings.font_color = Color.ORANGE
			bubbleOffsetY -= 10 # Add some spacing between each Stat
