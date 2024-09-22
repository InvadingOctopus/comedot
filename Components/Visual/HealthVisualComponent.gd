## Adds visual effects and indicators based on the state of a [HealthComponent].
## @experimental

class_name HealthVisualComponent
extends Component

# TODO: Better implementation


#region Dependencies
var healthComponent: HealthComponent:
	get:
		if not healthComponent: healthComponent = parentEntity.findFirstComponentSublcass(HealthComponent)
		return healthComponent
#endregion


func _ready() -> void:
	connectSignals()


func connectSignals() -> void:
	healthComponent.healthDidDecrease.connect(self.onHealthComponent_healthChanged)
	healthComponent.healthDidIncrease.connect(self.onHealthComponent_healthChanged)


func onHealthComponent_healthChanged(difference: int) -> void:
	animate(difference)


## @experimental
func animate(difference: int) -> void:
	if difference < 0:
		Animations.blinkNode(self.parentEntity, 3)
	
	var health: Stat  = healthComponent.health
	var red:	float = (1.0 - (health.percentage / 100.0)) * 5.0 # Increase red as health gets lower
	var currentModulate: Color = self.parentEntity.modulate
	var targetModulate:  Color = currentModulate

	targetModulate.r = red
	Animations.tweenProperty(self.parentEntity, ^"modulate", targetModulate, 0.1)
