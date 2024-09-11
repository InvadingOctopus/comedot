## Represents an action that may be performed by the player or any other character. May have a cost and may require a target to be chosen.
## It may be a special skill/spell such as "Fireball", an innate ability such as "Fly", or a trivial command like "Examine".
## @experimental

class_name Action
extends StatDependentResourceBase


#region Parameters

@export var requiresTarget: bool

## The code to execute when this Action is performed. See [Payload] for explanation and possible options.
@export var payload: Payload

@export var shouldShowDebugInfo: bool

#endregion


#region Derived Properties
var logName: String:
	get: return str(self, " ", self.name)
#endregion


#region Interface

## Returns the result of the [member payload].
func perform(source: Entity, target: Entity = null) -> Variant:
	# TODO: Handle target acquisition.

	printLog(str("perform() source: ", source, ", target: ", target))

	if not self.payload:
		Debug.printWarning("Missing payload", str(self))
		return false
	
	return payload.execute(source, target)

#endregion


func printLog(message: String) -> void:
	if shouldShowDebugInfo: Debug.printLog(message, str(self.logName))
