# AutoLoad
## Displays a list of variables updated per frame. To watch a variable, add it to the `watchList` property

#class_name Debug
extends Node


#region Parameters

## Sets the visibility of "debug"-level messages in the log.
## NOTE: Does NOT affect normal logging.
@export var shouldPrintDebugLogs: bool = OS.is_debug_build() # TBD: Should this be a constant to improve performance?

## Sets the visibility of the debug information overlay text.
## NOTE: Does NOT affect the visibility of the framework warning label.
@export var showDebugLabels: bool = OS.is_debug_build():
	set(newValue):
		showDebugLabels = newValue
		setLabelVisibility()

## A dictionary of variables to monitor at runtime. The keys are the names of the variables or properties from other nodes.
@export var watchList: Dictionary[StringName, Variant] = {}

const customLogEntryScene: PackedScene = preload("res://UI/CustomLogEntryUI.tscn")
const customLogMaximumEntries: int = 100

#endregion


#region State

@onready var debugWindow:	 Window = %DebugWindow
@onready var logWindow:		 Window = %CustomLogWindow

@onready var labels:		 Node   = %Labels
@onready var label:			 Label  = %Label
@onready var warningLabel:	 Label  = %WarningLabel
@onready var watchListLabel: Label  = %WatchListLabel
@onready var customLogList:	 Container = %CustomLogList

@onready var testBackground: Node2D = %TestBackground

var previousChartWindowInitialPosition: Vector2i

static var lastFrameLogged: int = -1 # Start at -1 so the first frame 0 can be printed.
static var customLogColorFlag: bool

## A custom log that holds extra on-demand information for each component and its parent entity etc.
## @experimental
static var customLog: Array[Dictionary]

#endregion


#region Initialization

func _ready() -> void:
	initializeLogWindow()
	initializeDebugWindow()
	resetLabels()
	setLabelVisibility()
	performFrameworkChecks()
	displayInitializationMessage()


func initializeLogWindow() -> void:
	# TBD: # logWindow.visible = OS.is_debug_build()
	# Position the Log Window to the bottom of the main window
	var mainWindow: Window = self.get_window()
	logWindow.position = mainWindow.position
	logWindow.position.y += mainWindow.size.y + 75
	logWindow.size.x = mainWindow.size.x


func initializeDebugWindow() -> void:
	debugWindow.visible = OS.is_debug_build()

	# Position the Debug Window to the right of the main window
	# TBD: Support for Right-To-Left locales? :')
	var mainWindow: Window = self.get_window()
	debugWindow.position = mainWindow.position
	debugWindow.position.x += mainWindow.size.x + 50


func resetLabels() -> void:
	label.text			= ""
	warningLabel.text	= ""
	watchListLabel.text	= ""


func setLabelVisibility() -> void:
	# NOTE: The warning label must always be visible
	if label: label.visible = self.showDebugLabels
	if watchListLabel: watchListLabel.visible = self.showDebugLabels


func performFrameworkChecks() -> void:
	var warnings: PackedStringArray

	if not Global.hasStartScript:
		warnings.append("! Start.gd script not executed\nAttach to root node of main scene")

	warningLabel.text = "\n".join(warnings)


func displayInitializationMessage() -> void:
	# TODO: Get input keys/buttons dynamically
	var message: String = str("Debug.displayInitializationMessage():\n\
	F12: Toggle Debug Window\n\
	See Input Map for more shortcuts")

	print_rich(str("[color=white][b]Comdedot\n", message))

	self.addTemporaryLabel(Global.frameworkTitle, message)

#endregion


#region Runtime

func _process(_delta: float) -> void:
	if not showDebugLabels or not is_instance_valid(debugWindow) or not debugWindow.visible: return

	var text: String = ""

	for value: Variant in watchList:
		text += str(value) + ": " + str(watchList[value]) + "\n"

	watchListLabel.text = text


## Adds a temporary entry to the [member watchList] for the specified number of seconds.
## TIP: For gameplay related messages, use [method GlobalOverlay.createTemporaryLabel].
## NOTE: Does NOT use [TemporaryLabel].
func addTemporaryLabel(key: StringName, text: String, duration: float = 3.0) -> void:
	watchList[key] = text

	# Create a temporary timer to remove the key
	await get_tree().create_timer(duration, false, false, true).timeout
	watchList.erase(key)

#endregion


#region Windows

## Returns: The resulting state of the debug window's visibility.
func toggleDebugWindow() -> bool:
	var isDebugWindowShown: bool

	if is_instance_valid(debugWindow):
		debugWindow.visible = not debugWindow.visible
		isDebugWindowShown  = debugWindow.visible
	else:
		isDebugWindowShown  = false
		# TODO: Recreate the window

	return isDebugWindowShown


## Creates a new window with a [Chart] to graph the specified node's property.
## Returns: The new chart
func createChartWindow(nodeToMonitor: NodePath, propertyToMonitor: NodePath) -> Chart:
	var newChartWindow: Window = preload("res://UI/ChartWindow.tscn").instantiate()
	var newChart: Chart = Tools.findFirstChildOfType(newChartWindow, Chart)

	newChart.nodeToMonitor = nodeToMonitor
	newChart.propertyToMonitor = propertyToMonitor

	newChartWindow.title = str(get_node(nodeToMonitor), propertyToMonitor)
	newChartWindow.close_requested.connect(newChartWindow.queue_free) # TODO: Verify

	# Resize the window and center the chart

	newChartWindow.size.x = int(newChart.maxHistorySize * newChartWindow.content_scale_factor)
	newChartWindow.size.y = int((newChart.verticalHeight * 2) * newChartWindow.content_scale_factor) # NOTE: Twice the height for both sides of the Y axis
	newChart.position.y   = newChart.verticalHeight # NOTE: No scaling here, because it's the "raw" position before scaling.

	# Shift each window so they don't all overlap

	newChartWindow.position = previousChartWindowInitialPosition + Vector2i(newChartWindow.size.x, 0)
	previousChartWindowInitialPosition = newChartWindow.position

	self.add_child(newChartWindow)
	return newChart

#endregion


#region Logging

class CustomLogKeys:
	# NOTE: Must be all lower case for `Tools.setLabelsWithDictionary()`
	const message	= &"message"
	const frameTime	= &"frametime"
	const object	= &"object"
	const instance	= &"instance"
	const name		= &"name"
	const type		= &"type"
	const nodeClass	= &"nodeclass"
	const baseScript = &"basescript"
	const className	= &"classname"
	const parent	= &"parent"

func printLog(message: String = "", messageColor: String = "", objectName: String = "", objectColor: String = "") -> void:
	updateLastFrameLogged()
	print_rich("[color=" + objectColor + "]" + objectName + "[/color] [color=" + messageColor + "]" + message + "[/color]")


## Prints a faded message to reduce visual clutter.
## Affected by [member shouldPrintDebugLogs].
func printDebug(message: String = "", objectName: String = "", _objectColor: String = "") -> void:
	if Debug.shouldPrintDebugLogs:
		#updateLastFrameLogged() # OMIT: Do not print frames on a separate line, to reduce clutter.
		#print_debug(str(Engine.get_frames_drawn()) + " " + message) # OMIT: Not useful because it will always say it was called from this Debug script.
		print_rich(str("[right][color=dimgray]F", Engine.get_frames_drawn(), " ", objectName, " ", message, "[/color]"))


## Prints the message in bold and a bright color, with empty lines on each side.
## For finding important messages quickly in the debug console.
func printHighlight(message: String = "", objectName: String = "", _objectColor: String = "") -> void:
	print_rich("\n[indent]􀢒 [b][color=white]" + objectName + " " + message + "[/color][/b]\n")


func printWarning(message: String = "", objectName: String = "", _objectColor: String = "") -> void:
	updateLastFrameLogged()
	push_warning("Frame " + str(lastFrameLogged) + " ⚠️ " + objectName + " " + message)
	print_rich("[indent]􀇿 [color=yellow]" + objectName + " " + message + "[/color]")


## NOTE: In release builds, if [member Global.shouldAlertOnError] is true, displays an OS alert which blocks engine execution.
func printError(message: String = "", objectName: String = "", _objectColor: String = "") -> void:
	updateLastFrameLogged()
	var plainText: String = "Frame " + str(lastFrameLogged) + " ❗️ " + objectName + " " + message
	push_error(plainText)
	printerr(plainText)
	# Don't print a duplicate line, to reduce clutter.
	#print_rich("[indent]❗️ [color=red]" + objectName + " " + message + "[/color]")

	# WARNING: Crash on error if not developing in the editor.
	if Global.shouldAlertOnError and not OS.is_debug_build():
		OS.alert(message, "Framework Error")


## Logs and returns a string showing a variable's previous and new values, IF there is a change and [member shouldPrintDebugLogs].
## Affected by [member shouldPrintDebugLogs].
func printChange(variableName: String, previousValue: Variant, newValue: Variant, logAsDebug: bool = true) -> String:
	# TODO: Optional charting? :)
	if shouldPrintDebugLogs and previousValue != newValue:
		var string: String = str(previousValue, " → ", newValue)
		if not logAsDebug: printLog(string, "dimgray", variableName, "gray")
		else: printDebug(string)
		return string
	else:
		return ""


## Prints a list of variables in a highlighted color.
## TIP: Helpful for temporary debugging of bugs currently under attention.
## Affected by [member shouldPrintDebugLogs].
func printVariables(values: Array[Variant], separator: String = "\t") -> void:
	if shouldPrintDebugLogs:
		print_rich(str("[indent]F", Engine.get_frames_drawn(), " ", float(Time.get_ticks_msec()) / 1000, " ", getLogCaller(), " \t[color=orange][b]", separator.join(values)))


## Returns a string denoting the script file & function which called the CALLER of this [method getLastCaller()].
## Example: If `_ready()` in `Component.gd` calls [method Debug.printDebug], then `printDebug()` calls `getLastCaller()`, then `Component.gd:_ready()`
## NOTE: Does NOT include function arguments.
## @experimental
static func getLogCaller() -> String:
	var caller: Dictionary = get_stack()[2] # CHECK: Get the caller of the caller (function that wants to log → log function → this function)
	return caller.source.get_file() + ":" + caller.function + "()"


## Updates the frame counter and prints an extra line between logs from different frames for clarity of readability.
static func updateLastFrameLogged() -> void:
	if not lastFrameLogged == Engine.get_frames_drawn():
		lastFrameLogged = Engine.get_frames_drawn()
		print(str("\n[right][u][b]Frame ", lastFrameLogged, "[/b] ", float(Time.get_ticks_msec()) / 1000))

#endregion


#region Custom Log UI

## @experimental
func addCustomLog(object: Variant, parent: Variant, message: String) -> void:
	var customLogEntry: Dictionary[StringName, Variant] = getObjectDetails(object)

	# Unless the object specified a custom parent, like a Component mentioning its Entity, just get the parent Node in the scene
	if parent: customLogEntry[CustomLogKeys.parent] = parent
	elif object is Node: customLogEntry[CustomLogKeys.parent] = object.get_parent()

	customLogEntry[CustomLogKeys.message] = message

	# customLog.append(customLogEntry) # No need to take up memory for an array when we already have the visual UI.
	addCustomLogUIItem(customLogEntry)


## @experimental
func addCustomLogUIItem(customLogEntry: Dictionary) -> void:
	if not logWindow or not logWindow.visible or not customLogList or customLogEntry.is_empty(): return

	var listChildCount: int = customLogList.get_child_count()

	if  listChildCount >= customLogMaximumEntries:
		var childToDelete: Node = customLogList.get_child(0)
		customLogList.remove_child(childToDelete)
		childToDelete.queue_free() # CHECK: Is this needed?

	var newLogEntryUI: CustomLogEntryUI = customLogEntryScene.instantiate()
	newLogEntryUI.logEntry = customLogEntry

	if  customLogColorFlag: # Alternate the color of rows starting from the 2nd row.
		newLogEntryUI.self_modulate = Color(.5, 0, .5)
	customLogColorFlag = not customLogColorFlag

	customLogList.add_child(newLogEntryUI) # Don't call Tools, for performance
	newLogEntryUI.owner = customLogList # CHECK: Is this needed for emphemeral controls?
	# TBD: Return newLogEntryUI?


## Returns a dictionary of almost all details about an object, using the [Debug.CustomLogKeys].
static func getObjectDetails(object: Variant) -> Dictionary[StringName, Variant]:
	# TBD: Should the values be actual variables or Strings?

	var dictionary: Dictionary[StringName, Variant] = {
		CustomLogKeys.frameTime:	str("F", Engine.get_frames_drawn(), " ", float(Time.get_ticks_msec()) / 1000),
		CustomLogKeys.object:		object,
		CustomLogKeys.instance:		object.get_instance_id(),
		CustomLogKeys.name:			object.name,
		CustomLogKeys.type:			type_string(typeof(object)),
		CustomLogKeys.nodeClass:	object.get_class()
	}

	var script: Script = object.get_script()

	if script:
		dictionary[CustomLogKeys.className] = script.get_global_name()

		var baseScript: Script = script.get_base_script()
		if baseScript:  dictionary[CustomLogKeys.baseScript] = baseScript.get_global_name()

	return dictionary

#endregion
