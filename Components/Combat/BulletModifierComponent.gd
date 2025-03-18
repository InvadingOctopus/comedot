## Modifies the "bullet" (or other projectile) entities emitted by a [GunComponent].
## May be used as a buff that increases their damage, or add extra visual effects et.
## Requirements: AFTER [GunComponent]

class_name BulletModifierComponent
extends Component

# TODO: Modifiers for speed etc.


#region Parameters
@export_range(-1000, 1000, 1) var damageModifier: int = 0
@export var componentsToRemove: Array[Script] ## Occurs BEFORE [member componentsToCreate]
@export var componentsToCreate: Array[Script] ## Occurs AFTER [member componentsToRemove]
@export var isEnabled:			bool = true
#endregion


#region Signals
signal didModifyBullet(bullet: Entity)
#endregion


#region Dependencies

@onready var gunComponent: GunComponent = self.coComponents.GunComponent

## Returns a list of required component types that this component depends on.
func getRequiredComponents() -> Array[Script]:
	return [GunComponent]

#endregion


func _ready() -> void:
	Tools.connectSignal(gunComponent.didFire, self.onGunComponent_didFire)


func onGunComponent_didFire(bullet: Entity) -> void:
	if not isEnabled: return

	bullet.components.DamageComponent.damageOnCollision += self.damageModifier
	bullet.removeComponents(componentsToRemove)
	bullet.createNewComponents(componentsToCreate)
	didModifyBullet.emit(bullet)
