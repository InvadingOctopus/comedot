## A [Payload] which calls a specific function/method from the specified `.gd` script file.

class_name ScriptPayload
extends Payload

# TBD: Should the script method arguments include a reference to the calling Payload?


#region Parameters

## A script to run when this [Payload] is executed.
## IMPORTANT: The script MUST have a function with the same name as [member payloadScriptMethodName] and the following arguments:
## `static func [payloadScriptMethodName](source: Variant, target: Variant) -> Variant`
## IMPORTANT: The method MUST be `static` so as to avoid the need for creating an instance of the script.
## [method executeImplementation] will return the result of that method.
## TIP: Use the `Templates/Scripts/Resource/ScriptPayloadScriptTemplate.gd` template.
## TIP: The parameter names and the [Variant] types may be replaced with any name and any type, for better clarity.
@export var payloadScript: GDScript # TODO: Stronger typing when Godot allows it :')

## The method/function which will be executed from the [member payloadScript].
@export var payloadScriptMethodName: StringName = &"onPayload_didExecute" # TBD: Better default name?

#endregion


## Returns the result of the called method.
func executeImplementation(source: Variant, target: Variant) -> Variant:
	printLog(str("executeImplementation() script: ", payloadScript, " ", payloadScript.get_global_name(), ", source: ", source, " target: ", target))

	# TODO: Check for method availability
	
	if self.payloadScript:
		self.willExecute.emit(source, target)
		# A script that matches this interface:
		# static func [payloadScriptMethodName](source: Variant, target: Variant) -> Variant
		return self.payloadScript.call(self.payloadScriptMethodName, source, target)
	else:
		Debug.printWarning("Missing payloadScript", self.logName)
		return false
