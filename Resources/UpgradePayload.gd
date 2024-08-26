## Abstract base class for Scripts for an [Upgrade] to execute when it is "installed" or "uninstalled" in an [Entity]'s [UpgradesComponent].
## MUST be subclassed.
## TIP: Use the `Templates/Scripts/Resource/UpgradePayloadTemplate.gd` template.

class_name UpgradePayload
extends Resource


static func onUpgrade_didAcquireOrLevelUp(upgrade: Upgrade, entity: Entity) -> bool:
	Debug.printWarning(str("onUpgrade_didAcquireOrLevelUp() not implemented! entity: ", entity), str(upgrade))
	return false


static func onUpgrade_willDiscard(upgrade: Upgrade, entity: Entity) -> bool:
	Debug.printWarning(str("onUpgrade_willDiscard() not implemented! entity: ", entity), str(upgrade))
	return false
