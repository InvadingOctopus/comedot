# AutoLoad
## Displays a list of variables updated per frame. To watch a variable, add it to the `watchList` property

extends CanvasLayer


#region Flags
const shouldPrintDebugLogs: bool = true
#endregion


@export var isVisible: bool = false:
	set(newValue):
		isVisible = newValue
		if %Label: %Label.visible = isVisible


## A dictionary of variables to monitor at runtime. The keys are the names of the variables or properties from other nodes.
@export var watchList = {}


#region Logging

var lastFrameLogged: int = -1 # Start at -1 so the first frame 0 can be printed.

func printLog(message: String = "", messageColor: String = "", objectName: String = "", objectColor: String = ""):
	updateLastFrameLogged()
	print_rich("[color=" + objectColor + "]" + objectName + "[/color] [color=" + messageColor + "]" + message + "[/color]")


## Prints a faded message to reduce apparent visual clutter.
func printDebug(message: String = "", objectName: String = "", _objectColor: String = ""):
	if Debug.shouldPrintDebugLogs:
		# Do not print frames on a separate line to reduce less clutter.
		#updateLastFrameLogged()
		#print_debug(str(Engine.get_frames_drawn()) + " " + message) # Not useful because it will always say it was called from this Debug script.
		print_rich("[right][color=dimgray]F" + str(Engine.get_frames_drawn()) + " " + objectName + " " + message + "[/color]")


## Prints the message in bold and a bright color, with empty lines on each side.
## For finding important messages quickly in the debug console.
func printHighlight(message: String = "", objectName: String = "", _objectColor: String = ""):
	print_rich("\n[indent]􀢒 [b][color=white]" + objectName + " " + message + "[/color][/b]\n")


func printWarning(message: String = "", objectName: String = "", _objectColor: String = ""):
	updateLastFrameLogged()
	push_warning("Frame " + str(lastFrameLogged) + " ⚠️ " + objectName + " " + message)
	print_rich("[indent]􀇿 [color=yellow]" + objectName + " " + message + "[/color]")


func printError(message: String = "", objectName: String = "", _objectColor: String = ""):
	updateLastFrameLogged()
	var plainText: String = "Frame " + str(lastFrameLogged) + " ❗️ " + objectName + " " + message
	push_error(plainText)
	printerr(plainText)
	# Don't pring a duplicate line to reduce clutter.
	#print_rich("[indent]❗️ [color=red]" + objectName + " " + message + "[/color]")


## Updates the frame counter and prints an extra line between logs from different frames for clarity of readability.
func updateLastFrameLogged():
	if not lastFrameLogged == Engine.get_frames_drawn():
		lastFrameLogged = Engine.get_frames_drawn()
		print("\n[right][b][u]Frame " + str(lastFrameLogged) + "[/u][/b]")

#endregion


func _ready():
	%Label.visible = self.isVisible


func _process(delta: float):
	if not isVisible: return

	var text := ""

	for value: Variant in watchList:
		text += str(value) + ": " + str(watchList[value]) + "\n"

	%Label.text = text


func showTemporaryLabel(key: StringName, text: String, duration: float = 3.0):
	watchList[key] = text

	# Create a temporary timer to remove the key
	await get_tree().create_timer(duration, false, false, true).timeout
	watchList.erase(key)
