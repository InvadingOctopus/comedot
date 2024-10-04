## A script called by a [ScriptPayload] when an [Upgrade] is "installed" into or removed from an [UpgradesComponent].

extends GDScript


@warning_ignore("unused_parameter")
static func onPayload_didExecute(payload: Payload, source: Upgrade, target: Entity) -> Variant:
	target.getComponent(OverheadPhysicsComponent).parameters.speed += 100
	return true
