## Modifies [Stat] Resources when the parent Entity's [HealthComponent] drops to 0.
## May be used for incrementing the player's score and XP when a monster is killed, or decreasing the player's lives when an ally NPC is killed, etc.
## TIP: To modify Stats repeatedly based on a time interval, such as draining/healing a character's life or mana etc., use [StatModifierComponent].

class_name StatModifierOnDeathComponent
extends Component


#region Parameters
@export var statsToModify:	Dictionary[Stat, int] ## A [Dictionary] where the keys are [Stat] Resources and the values are the positive or negative modifier to apply to that respective Stat.
@export var isEnabled:		bool = true
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
	for stat in statsToModify:
		stat.value += statsToModify[stat]
