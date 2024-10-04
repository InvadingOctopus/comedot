## A script called by a [ScriptPayload] when an [Upgrade] is "installed" into or removed from an [UpgradesComponent].

extends GDScript


@warning_ignore("unused_parameter")
static func onPayload_didExecute(payload: Payload, source: Upgrade, target: Entity) -> Variant:
	var gunComponent: GunComponent = target.getComponent(GunComponent)
	var mouseRotationComponent: MouseRotationComponent = target.getComponent(MouseRotationComponent)
	gunComponent.visible = true
	gunComponent.isEnabled = true
	mouseRotationComponent.isEnabled = true

	return true
