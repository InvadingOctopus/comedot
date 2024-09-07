## Abstract base class for Scripts that will be executed by an [Action] when it is performed by an Entity.
## MUST be subclassed.
## TIP: Use the `Templates/Scripts/Resource/ActionPayloadTemplate.gd` template.

class_name ActionPayload
extends Resource


static func onAction_didPerform(action: Action, entity: Entity) -> bool:
	Debug.printWarning(str("onAction_didPerform() not implemented! entity: ", entity), str(action))
	return false
