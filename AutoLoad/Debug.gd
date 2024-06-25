# AutoLoad
## Displays a list of variables updated per frame. To watch a variable, add it to the `watchList` property

#class_name Debug
extends CanvasLayer


#region Parameters

## Sets the visibility of "debug"-level messages in the log.
## NOTE: Does NOT affect normal logging.
@export var printDebugLogs: bool = true # TBD: Should this be a constant to improve performance?

## Sets the visibility of the debug information overlay text.
## NOTE: Does NOT affect the visibility of the framework warning label.
@export var showDebugLabels: bool = true:
	set(newValue):
		showDebugLabels = newValue
		setLabelVisibility()

## A dictionary of variables to monitor at runtime. The keys are the names of the variables or properties from other nodes.
@export var watchList := {}

#endregion


#region State

@onready var labels:			Node  = %Labels
@onready var label:				Label = %Label
@onready var warningLabel:		Label = %WarningLabel
@onready var watchListLabel:	Label = %WatchListLabel

#endregion


#region Logging

var lastFrameLogged: int = -1 # Start at -1 so the first frame 0 can be printed.

func printLog(message: String = "", messageColor: String = "", objectName: String = "", objectColor: String = ""):
	updateLastFrameLogged()
	print_rich("[color=" + objectColor + "]" + objectName + "[/color] [color=" + messageColor + "]" + message + "[/color]")


## Prints a faded message to reduce apparent visual clutter.
func printDebug(message: String = "", objectName: String = "", _objectColor: String = ""):
	if Debug.printDebugLogs:
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
	resetLabels()
	setLabelVisibility()
	performFrameworkChecks()


func resetLabels():
	label.text = ""
	warningLabel.text = ""
	watchListLabel.text = ""


func setLabelVisibility():
	# NOTE: The warning label must always be visible
	if label: label.visible = self.showDebugLabels
	if watchListLabel: watchListLabel.visible = self.showDebugLabels


func performFrameworkChecks():
	var warnings: PackedStringArray

	if not Global.hasStartScript:
		warnings.append("! Start.gd script not executed\nAttach to root node of main scene")

	warningLabel.text = "\n".join(warnings)


func _process(delta: float):
	if not showDebugLabels: return

	var text := ""

	for value: Variant in watchList:
		text += str(value) + ": " + str(watchList[value]) + "\n"

	watchListLabel.text = text


func showTemporaryLabel(key: StringName, text: String, duration: float = 3.0):
	watchList[key] = text

	# Create a temporary timer to remove the key
	await get_tree().create_timer(duration, false, false, true).timeout
	watchList.erase(key)
