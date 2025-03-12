## A [Payload] which calls a specific function/method from the specified `.gd` script file.
## TIP: If your script requires more complex parameters than just the `source` and `target`, create a new custom subclass of [Payload].

class_name ScriptPayload
extends Payload

# TBD: Should the script method arguments include a reference to the calling Payload?
# TBD: Instead of taking different `script` parameters, should we just use different subclasses of `ScriptPayload`?


#region Parameters

## A script to run when this [Payload] is executed.
## IMPORTANT: The script MUST have a function with the same name as [member payloadScriptMethodName] and the following arguments:
## `static func [payloadScriptMethodName](payload: Payload, source: Variant, target: Variant) -> Variant`
## IMPORTANT: The method MUST be `static` so as to avoid the need for creating an instance of the script.
## [method executeImplementation] will return the result of that method.
## TIP: Use the `Templates/Scripts/Resource/ScriptPayloadScriptTemplate.gd` template.
## TIP: The parameter names and the [Variant] types may be replaced with any name and any specific type, for better reliability and performance.
## If not specified, a `.gd` script file matching the same name as this Payload's `.tres` filename is used, if found, e.g. `GunUpgradePayload.tres`: `GunUpgradePayload.gd`
@export var payloadScript: GDScript: # TODO: Stronger typing when Godot allows it :')
	get:
		if not payloadScript:
			printLog("payloadScript not assigned. Searching for a .gd with the same filename as: " + self.resource_path.get_file())
			payloadScript = load(Tools.getPathWithDifferentExtension(self.resource_path, ".gd"))
		return payloadScript

## The method/function which will be executed from the [member payloadScript].
@export var payloadScriptMethodName: StringName = &"onPayload_didExecute" # TBD: Better default name?

#endregion


## Returns the result of the called method.
func executeImplementation(source: Variant, target: Variant) -> Variant:
	printLog(str("executeImplementation() script: ", payloadScript, " ", payloadScript.get_global_name(), ", source: ", source, ", target: ", target))

	if self.payloadScript:
		if not Tools.findMethodInScript(payloadScript, payloadScriptMethodName):
			Debug.printWarning(str("Missing method: ", payloadScriptMethodName), self.logName)
			return false

		self.willExecute.emit(source, target)

		# A script that matches this interface:
		# static func [payloadScriptMethodName](payload: Payload, source: Variant, target: Variant) -> Variant
		Debug.printLog(str(payloadScriptMethodName, "() source: ", source, ", target: ", target), str(self.logName, " payloadScript: ", self.payloadScript, " ", self.payloadScript.resource_path.get_file()), "", "pink") # A custom log to show the script as part of the logging object
		return self.payloadScript.call(self.payloadScriptMethodName, self, source, target)
	else:
		Debug.printWarning("Missing payloadScript", self.logName)
		return false
