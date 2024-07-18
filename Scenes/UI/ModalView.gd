## Displays a control that pauses the gameplay while it is displayed.
## Calls a specified function which may then resume the gameplay. 

class_name ModalView
extends Node


#region Parameters
## Optional: The function to call when the modal UI closes. 
## Must accept a [Variant] argument to receive the result of the modal UI.
## May be omitted if the [signal ModalView.didFinish] signal is used.
@export var callbackOnFinish: Callable
#endregion


#region Signals
signal didFinish(result: Variant)
#endregion


## Closes the modal view and calls the specified function, if any.
func close(result: Variant = 0) -> void:
	Debug.printLog(str("close(): ", result))
	didFinish.emit(result)
	if callbackOnFinish: callbackOnFinish.call(result)
