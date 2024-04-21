## Adds visual effects and indicators of a [HealthComponent].
## Not currently implemented.
class_name HealthVisualComponent
extends Component

# TODO: Implement

@export var healthComponent: HealthComponent


func _ready():
	if not healthComponent: connectToHealthComponent()


func connectToHealthComponent():
	self.healthComponent = findCoComponent(HealthComponent)
	if not healthComponent:
		printWarning("Cannot find a HealthComponent in parent Entity: " + self.parentEntity.logName)
		return

	healthComponent.connect("healthDidDecrease", self.onHealthComponent_healthChanged)
	healthComponent.connect("healthDidIncrease", self.onHealthComponent_healthChanged)


func onHealthComponent_healthChanged(difference: int):
	var health: Stat = healthComponent.health

	var red: float   = 1.0 - (health.percentage / 100.0)
	var green: float = (health.percentage / 100.0) - 0.5
	var blue: float  = (health.percentage / 100.0) - 0.5

	self.parentEntity.modulate = Color(red, green, blue, 1.0)
