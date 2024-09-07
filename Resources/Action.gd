## Represents an action that may be performed by the player or any other character. May have a cost and may require a target to be chosen.
## It may be a special skill/spell such as "Fireball", an innate ability such as "Fly", or a trivial command like "Examine".
## @experimental

class_name Action
extends StatDependentResourceBase


#region Parameters

@export var requiresTarget: bool

## The code to execute when this Action is performed.
## IMPORTANT: The script MUST have functions matching these signatures; the same interface as [ActionPayload]:
## `static func onAction_didPerform(action: Action, entity: Entity) -> bool`
## TIP: Use the `Templates/Scripts/Resource/ActionPayloadTemplate.gd` template.
## If not specified, a `.gd` script file matching the same name as the Action `.tres` is used, if found, e.g. `FireballAction.tres`: `FireballAction.gd`
@export var payload: GDScript: # TODO: Stronger typing when Godot allows it :')
	get:
		if not payload:
			payload = load(Tools.getPathWithDifferentExtension(self.resource_path, ".gd"))
		return payload

const payloadMethodName: StringName = &"onAction_didPerform" ## The method/function which will be executed from the [member payload] when this Action is performed.

@export var shouldShowDebugInfo: bool

#endregion


#region Derived Properties
var logName: String:
	get: return str(self, " ", self.name)
#endregion


#region Interface

func perform(entity: Entity, target: Entity = null) -> bool:
	# TODO: Handle target
	printLog(str("perform() entity: ", entity, ", target: ", target))

	if not self.payload:
		Debug.printWarning("Missing payload", str(self))
		return false
	
	return payload.call(self.payloadMethodName, entity)

#endregion


func printLog(message: String) -> void:
	if shouldShowDebugInfo: Debug.printLog(message, str(self.logName))