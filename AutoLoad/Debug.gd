## AutoLoad
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

@onready var debugBackground: Node2D = %DebugBackground

var previousChartWindowInitialPosition: Vector2i

static var lastFrameLogged:		 int  = -1 # Start at -1 so the first frame 0 can be printed.
static var isTraceLogAlternateRow: bool = false ## Used by [method printTrace] to alternate the row background etc. for clarity.
static var customLogColorFlag:	 bool

## A custom log that holds extra on-demand information for each component and its parent entity etc.
## @experimental
static var customLog:			Array[Dictionary]

static var testMode:			bool ## Set by [TestMode].gd for use by other scripts, for temporary gameplay testing.

#endregion


#region Initialization

func _enter_tree() -> void:
	displayInitializationMessage()


func _ready() -> void:
	Debug.printLog("_ready()", self.get_script().resource_path.get_file(), "", "WHITE")
	initializeLogWindow()
	initializeDebugWindow()
	resetLabels()
	setLabelVisibility()
	performFrameworkChecks()


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
		warnings.append("! Start.gd script missing\nAttach to root node of main scene")

	warningLabel.text = "\n".join(warnings)


func displayInitializationMessage() -> void:
	# Get the actual input key
	var debugWindowInput: String = GlobalInput.getInputEventText(GlobalInput.Actions.debugWindow)[0] # .front() not for PackedStringArray :(

	var message: String = \
		"_enter_tree()\n" + \
		"\t" + debugWindowInput + ": Toggle Debug Window\n" + \
		"\tSee Input Map for more shortcuts"

	Debug.printAutoLoadLog(message)
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
## TIP: For gameplay related messages, use [method GlobalUI.createTemporaryLabel]
## NOTE: Does NOT use [FadingLabel.tscn]
func addTemporaryLabel(key: StringName, text: String, duration: float = 3.0) -> void:
	watchList[key] = text

	# Create a temporary timer to remove the key
	await self.get_tree().create_timer(duration, false, false, true).timeout
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
func createChartWindow(nodeToMonitor: NodePath, propertyToMonitor: NodePath, verticalHeight: float = 100, valueScale: float = 0.5) -> Chart:
	var newChartWindow: Window = preload("res://UI/ChartWindow.tscn").instantiate()
	var newChart: Chart = Tools.findFirstChildOfType(newChartWindow, Chart)

	newChart.nodeToMonitor = nodeToMonitor
	newChart.propertyToMonitor = propertyToMonitor
	newChart.verticalHeight = verticalHeight
	newChart.valueScale = valueScale

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


func printLog(message: String = "", object: Variant = null, messageColor: String = "", objectColor: String = "") -> void:
	updateLastFrameLogged()
	print_rich(str("[color=", objectColor, "]", object, "[/color] [color=", messageColor, "]", message)) # [/color] not necessary


## Prints a log message for an AutoLoad script without using any state variables such as the current frame.
## Useful for logging entries before the framework is completely ready.
func printAutoLoadLog(message: String = "") -> void:
	var caller: String = get_stack()[1].source.get_file().trim_suffix(".gd")
	print_rich(str("[color=ORANGE]", caller, "[/color] ", message))


## Prints a faded message to reduce visual clutter.
## Affected by [member shouldPrintDebugLogs]
func printDebug(message: String = "", object: Variant = null, _objectColor: String = "") -> void:
	if Debug.shouldPrintDebugLogs:
		#updateLastFrameLogged() # OMIT: Do not print frames on a separate line, to reduce clutter.
		#print_debug(str(Engine.get_frames_drawn()) + " " + message) # OMIT: Not useful because it will always say it was called from this Debug script.
		print_rich(str("[right][color=dimgray]F", Engine.get_frames_drawn(), " ", object, " ", message)) # [/color] not necessary


## Prints a warning message in the Output Log and Godot Debugger Console.
## TIP: To see the chain of recent function calls which led to a warning, use [method Debug.printTrace]
func printWarning(message: String = "", object: Variant = null, _objectColor: String = "") -> void:
	updateLastFrameLogged()
	push_warning(str("Frame ", lastFrameLogged, " ⚠️ ", object, " ", message))
	print_rich(str("[indent]􀇿 [color=yellow]", object, " ", message)) # [/color] not necessary


## Prints an error message in the Output Log and Godot Debugger Console. Includes the caller's file and method.
## NOTE: In release builds, if [member Settings.shouldAlertOnError] is true, displays an OS alert which blocks engine execution.
## TIP: To see the chain of recent function calls which led to an error, use [method Debug.printTrace]
func printError(message: String = "", object: Variant = null, _objectColor: String = "") -> void:
	updateLastFrameLogged()
	var plainText: String = str("Frame ", lastFrameLogged, " ", getCaller(3), " ❗️ ", object, " ", message)
	push_error(plainText)
	printerr(plainText)
	# Don't print a duplicate line, to reduce clutter.
	#print_rich("[indent]❗️ [color=red]" + objectName + " " + message) # [/color] not necessary

	# WARNING: Crash on error if not developing in the editor.
	if Settings.shouldAlertOnError and not OS.is_debug_build():
		OS.alert(message, "Framework Error")


## Prints the message in bold and a bright color, with empty lines on each side.
## Helpful for finding important messages quickly in the debug console.
func printHighlight(message: String = "", object: Variant = null, _objectColor: String = "") -> void:
	print_rich(str("\n[indent]􀢒 [b][color=white]", object, " ", message, "\n")) # [/color][/b] not necessary


## Prints an array of variables in a highlighted color.
## Affected by [member shouldPrintDebugLogs]
func printVariables(values: Array[Variant], separator: String = "\t ", color: String = "orange") -> void:
	if shouldPrintDebugLogs:
		print_rich(str("[color=", color, "][b]", separator.join(values)))


## Prints an array of variables in a highlighted color, along with a "stack trace" of the 3 most recent functions and their filenames before the log method was called.
## TIP: Helpful for quick/temporary debugging of bugs currently under attention.
## NOTE: NOT affected by [member shouldPrintDebugLogs] but only prints if running in a debug build.
func printTrace(values: Array[Variant] = [], object: Variant = null, stackPosition: int = 2, separator: String = " [color=dimgray]•[/color] ") -> void:
	if OS.is_debug_build():
		const textColorA1: String = "[color=FF80FF]"
		const textColorA2: String = "[color=C060C0]"
		const textColorB1: String = "[color=8080FF]"
		const textColorB2: String = "[color=6060C0]"

		var textColor1:	   String = textColorA1 if not isTraceLogAlternateRow else textColorB1
		var textColor2:    String = textColorA2 if not isTraceLogAlternateRow else textColorB2

		var backgroundColor: String = "[bgcolor=101020]" if not isTraceLogAlternateRow else "[bgcolor=001030]"
		var bullet: String = " ⬥ " if not isTraceLogAlternateRow else " ⬦ "

		print_rich(str(backgroundColor, textColor1, bullet, "F", Engine.get_frames_drawn(), " ", float(Time.get_ticks_msec()) / 1000, " [b]", object if object else "", "[/b] @ ", getCaller(stackPosition), textColor2, " ← ", getCaller(stackPosition+1), " ← ", getCaller(stackPosition+2)))

		if not values.is_empty():
			# SORRY: This mess instead of just `separator.join(values)` is so we can alternate color between values for better readability
			# PERFORMANCE: Watch out for any FPS impact! :')
			var joinedValues: String = ""
			var isAlternateValueColor: bool
			var valueColor: String
			for value: Variant in values:
				if not isTraceLogAlternateRow: valueColor = textColorA1 if not isAlternateValueColor else textColorA2
				else: valueColor = textColorB1 if not isAlternateValueColor else textColorB2
				joinedValues += str(valueColor, value, separator)
				isAlternateValueColor = not isAlternateValueColor
			print_rich(str(backgroundColor, " 　 ", joinedValues.trim_suffix(separator)))
		isTraceLogAlternateRow = not isTraceLogAlternateRow


## Logs and returns a string showing a variable's previous and new values, IF there is a change and [member shouldPrintDebugLogs]
## Affected by [member shouldPrintDebugLogs]
func printChange(variableName: String, previousValue: Variant, newValue: Variant, logAsDebug: bool = true) -> String:
	# TODO: Optional charting? :)
	if shouldPrintDebugLogs and previousValue != newValue:
		var string: String = str(previousValue, " → ", newValue)
		if not logAsDebug: printLog(string, variableName, "dimgray", "gray")
		else: printDebug(string, variableName)
		return string
	else:
		return ""


## Returns a string denoting the script file & function name from the specified [param stackPosition] on the call stack.
## Default: 2 which is the function that called the CALLER of this method.
## Example: If `_ready()` in `Component.gd` calls [method Debug.printError], then `printError()` calls `getCaller()`, then `get_stack()[2]` is `Component.gd:_ready()`
## [0] is `getCaller()` itself, [1] would be `printError()` and so on.
## If the position is larger than the stack, a "?" is returned.
## NOTE: Does NOT include function arguments.
static func getCaller(stackPosition: int = 2) -> String:
	if stackPosition > get_stack().size() - 1: return "?" # TBD: Return an empty string or what?
	var caller: Dictionary = get_stack()[stackPosition] # CHECK: Get the caller of the caller (function that wants to log → log function → this function)
	return caller.source.get_file() + ":" + caller.function + "()"


## Updates the frame counter and prints an extra line between logs from different frames for clarity of readability.
static func updateLastFrameLogged() -> void:
	if not lastFrameLogged == Engine.get_frames_drawn():
		lastFrameLogged = Engine.get_frames_drawn()
		print_rich(str("\n[right][u][b]Frame ", lastFrameLogged, "[/b] ", float(Time.get_ticks_msec()) / 1000))

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


## Returns a dictionary of almost all details about an object, using the [Debug.CustomLogKeys]
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
