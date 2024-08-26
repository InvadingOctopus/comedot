## Abstract base class for Scripts for an [Upgrade] to execute when it is "installed" or "uninstalled" in an [Entity]'s [UpgradesComponent].
## MUST be subclassed.
## TIP: Use the `Templates/Scripts/Resource/UpgradePayloadTemplate.gd` template.

class_name UpgradePayload
extends Resource


static func onUpgrade_didAcquireOrLevelUp(upgrade: Upgrade, entity: Entity) -> bool:
	Debug.printLog(str("onUpgrade_didAcquireOrLevelUp() entity: ", entity), str(upgrade)) # TBD: Should there be a warning if this abstract method is unimplemented?
	return false


static func onUpgrade_willDiscard(upgrade: Upgrade, entity: Entity) -> bool:
	Debug.printLog(str("onUpgrade_willDiscard() entity: ", entity), str(upgrade)) # TBD: Should there be a warning if this abstract method is unimplemented?
	return false
