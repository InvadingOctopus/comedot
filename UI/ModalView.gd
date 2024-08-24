## Displays a control that pauses the gameplay while it is displayed.
## Calls a specified function which may then resume the gameplay. 

class_name ModalView
extends Node


#region Parameters
## Optional: The function to call when the modal UI closes. 
## Must accept a [Variant] argument to receive the result of the modal UI.
## May be omitted if the [signal ModalView.didFinish] signal is used.
@export var callbackOnFinish: Callable

@export var shouldShowDebugInfo: bool = false
#endregion


#region Signals
signal didFinish(result: Variant)
#endregion


## Closes this modal view and calls the [member callbackOnFinish] function, if any.
func closeModalView(result: Variant = 0) -> void:
	# DESIGN: The name is more verbose than `close()` to reduce ambiguity in more complex scenes which extend this script.
	Debug.printLog(str("closeModalView() ", result), str(self))
	didFinish.emit(result)
	if callbackOnFinish: callbackOnFinish.call(result)
