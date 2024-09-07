# meta-default: true

## A script to execute when the associated [Action] is performed by an [Entity] with an [ActionsComponent].

class_name _CLASS_
extends ActionPayload


static func onAction_didPerform(action: Action, entity: Entity) -> bool:
	Debug.printLog(str("onAction_didPerform() entity: ", entity), str(action))
	return false
