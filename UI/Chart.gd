## Plots the value of a variable over time on a chart.
## NOTE: For best results, attach script to a [Node2D] which is a child of a [CanvasLayer] and vertically centered on the screen.
## TIP: Use [method Debug.createChartWindow] to create chart windows, prevent duplicates, and automatically close windows when a node is removed.

class_name Chart
extends Node2D

# TODO: Path validation
# TODO: More colors


#region Parameters

@export var nodeToMonitor:		NodePath: ## See [NodePath] documentation for examples of paths.
	set(newValue):
		nodeToMonitor = newValue
		self.set_process(isEnabled and not nodeToMonitor.is_empty() and not propertyToMonitor.is_empty())
		# TBD: Reset data & rebuild chart?

@export var propertyToMonitor:	NodePath: ## A path to the node's property, beginning with ":" ## IMPORTANT: The property must be a [float] or an [int]
	set(newValue):
		propertyToMonitor = newValue
		self.set_process(isEnabled and not nodeToMonitor.is_empty() and not propertyToMonitor.is_empty())
		# TBD: Reset data & rebuild chart?

## How many instances of values to record for the [member Chart.propertyToMonitor].
# NOTE: This is the first INVALID index outside the bounds of the [member Chart.monitoredVariableHistory] array; it must be compared with a >=.
@export_range(100, 500, 50) var maxHistorySize: int = 300:
	set(newValue):
		maxHistorySize = newValue
		resizeArrays()
		# TBD: Reset data & rebuild chart?

## The height of the Y axis on EACH side, positive and negative.
@export_range(100, 200, 5)		var height: float = 100

# Multiples the monitored variable's value by this scale when drawing the chart, visually reducing or enlarging the chart's Y axis, to improve readability and better fit the screen.
@export_range(0.1, 2.0, 0.05)	var yScale: float = 0.5

@export var shouldRandomizeLineColor: bool = true ## Overrides [member lineColor]
@export var lineColor:	Color = Color(0.0, 1.0, 0.25, 0.5) ## Overridden by [member shouldRandomizeLineColor], otherwise, if [member nodeToMonitor] is a [Component], then the [member Component.randomDebugColor] is used.
@export var gridColor:	Color = Color(0.0, 0.2, 0.3,  0.5)
@export var headColor:	Color = Color(0.5, 0.5, 0.75, 0.25) ## The color of the vertical "head" or "tracker" line.

@export var isEnabled:	bool = true:
	set(newValue):
		isEnabled = newValue # Don't bother checking for a change
		self.set_process(isEnabled and not nodeToMonitor.is_empty() and not propertyToMonitor.is_empty()) # PERFORMANCE: Set once instead of every frame

#endregion


#region State

@onready var nameLabel: Label = %NameLabel
@onready var maxLabel:  Label = %MaxLabel
@onready var minLabel:  Label = %MinLabel

var monitoredVariableHistory:	Array[float]
var currentHistoryIndex:		int = 0

var minRecordedValue:	float
var maxRecordedValue:	float
var shouldResetMinMax:	bool = true ## Sets [member minRecordedValue] & [member maxRecordedValue] to the next sample, then this flag is cleared to `false`. NOTE: Defaults to `true` so that the first sample should be both the min & the max, instead of just starting at 0

var valueLines:		PackedVector2Array
var gridLines:		PackedVector2Array

var lineWidth:		float = 1.0
var gridWidth:		float = 1.0 # NOTE: Grid lines may not be visible at smaller scales on a Nearest texture mapping.

var headLineStart:	Vector2
var headLineEnd:	Vector2

#endregion


#region Setup

func _ready() -> void:
	# Give a distinct random color to each chart?
	if shouldRandomizeLineColor: self.lineColor = Tools.getRandomQuantizedColorHue(Tools.sequenceTenths, Tools.sequenceQuarters.slice(1).pick_random(), 1.0, 0.5) # Prevent low saturation

	resizeArrays()
	createGridLines()
	updateNameLabel()
	self.set_process(isEnabled and not nodeToMonitor.is_empty() and not propertyToMonitor.is_empty()) # Apply setters because Godot doesn't on initialization


func resizeArrays() -> void:
	currentHistoryIndex = clampi(currentHistoryIndex, 0, maxHistorySize - 1) # The last valid index is size - 1 # TBD: Clamp or just reset to 0?
	monitoredVariableHistory.resize(maxHistorySize) # TBD: No need to reset prior history, right?
	valueLines.resize(maxHistorySize * 2) # Each line needs 2 vectors


func createGridLines() -> void:
	# TBD: Export these as parameters?

	var gridMinY:	float = -height
	var gridMaxY:	float =  height

	var gridStepX:	int = 10
	var gridStepY:	int = 10

	headLineStart.y	= gridMinY
	headLineEnd.y	= gridMaxY

	# PERFORMANCE: Calculate and set the total size before appending each line
	# GODOT: "Calling this method once and assigning the new values is faster than calling append() for every new element."
	# NOTE: Add +1 to grid lines otherwise 1 line will be missing. e.g. -100 to +100 in steps of 10 needs 21 grid lines

	@warning_ignore("integer_division")
	var numberOfGridLinesX: int = (maxHistorySize / gridStepX) + 1

	@warning_ignore("narrowing_conversion")
	var numberOfGridLinesY: int = ((gridMaxY - gridMinY) / gridStepY) + 1

	var gridLinesCount:		int = (numberOfGridLinesX + numberOfGridLinesY) * 2 # Each line needs 2 vectors

	if  gridLines.size() != gridLinesCount: gridLines.resize(gridLinesCount)

	# DEBUG: Debug.printLog(str("numberOfGridLines X, Y: ", numberOfGridLinesX, ", ", numberOfGridLinesY))

	var start:	Vector2
	var end:	Vector2
	var index:	int = 0

	# Vertical lines (X Axis)

	start.y	= gridMinY
	end.y	= gridMaxY

	for line in numberOfGridLinesX:
		start.x	= gridStepX * line
		end.x	= gridStepX * line
		# DEBUG: Debug.printLog(str("line X #", line, ": ", start, " → ", end))
		gridLines[index] = start;	index += 1
		gridLines[index] = end;		index += 1

	# Horizontal lines (Y Axis)
	# NOTE: Do not reset `index` because we're still filling the remaining array

	start.x	= 0
	start.y	= gridMinY
	end.x	= maxHistorySize
	end.y	= gridMinY

	for line in numberOfGridLinesY:
		# DEBUG: Debug.printLog(str("line Y #", line, ": ", start, " → ", end))
		gridLines[index] = start;	index += 1
		gridLines[index] = end;		index += 1
		# Go up
		start.y	+= gridStepY
		end.y	+= gridStepY


func updateNameLabel() -> void:
	nameLabel.text = str(propertyToMonitor).trim_prefix(":")


func updateMinMaxLabels() -> void:
	minLabel.text = str("MIN: ", minRecordedValue)
	maxLabel.text = str("MAX: ", maxRecordedValue)

#endregion


#region Data

func recordMonitoredVariable() -> void:
	var node: Node = self.get_tree().root.get_node_or_null(nodeToMonitor) # TBD: PERFORMANCE: Should we resolve the [NodePath] once & cache `node`?
	if  not is_instance_valid(node):
		nameLabel.text = str("INVALID:", nodeToMonitor)
		return

	var variant: Variant = node.get_indexed(propertyToMonitor)
	var value:	 float
	if  variant is float:
		value = variant
	elif variant is int:
		value = float(variant)
	else:
		nameLabel.text = str("INVALID:", propertyToMonitor)
		return

	monitoredVariableHistory[currentHistoryIndex] = value

	# Record the minimum and maximum values
	if shouldResetMinMax:
		minRecordedValue  = value
		maxRecordedValue  = value
		shouldResetMinMax = false
	else:
		if value < minRecordedValue: minRecordedValue = value
		if value > maxRecordedValue: maxRecordedValue = value

	# DEBUG:
	# Debug.printLog(str("velocity: ", platformerPhysicsComponent.body.velocity.y))
	# Debug.printLog(str("currentHistoryIndex: ", currentHistoryIndex))

	# Add a line
	if not self.shouldRandomizeLineColor and node is Component: self.lineColor = node.randomDebugColor
	createLine(currentHistoryIndex) # NOTE: Update BEFORE incrementing `currentHistoryIndex`

	# Increment or wrap-around the index
	currentHistoryIndex += 1
	if  currentHistoryIndex >= maxHistorySize:
		currentHistoryIndex = 0


func createLine(index: int = currentHistoryIndex) -> void:
	# NOTE: Each line needs 2 vectors.

	var currentLineIndex: int = index * 2

	# DEBUG: Debug.printLog(str("currentLineIndex: ", currentLineIndex))

	valueLines[currentLineIndex] = Vector2(index, 0)

	valueLines[currentLineIndex + 1] = Vector2( \
		index,
		# NOTE: Negative Y values must go DOWNWARDS in the chart
		# NOTE: If the monitored variable is 0 then there should be no line (cleaner and more accurate)
		-(monitoredVariableHistory[index] * yScale))

	# DEBUG:
	# Debug.printLog(str("Vector ", currentLineIndex, ": ", valueLines[currentLineIndex]))
	# Debug.printLog(str("Vector ", currentLineIndex+1, ": ", valueLines[currentLineIndex+1]))

#endregion


#region Draw

func _process(_delta: float) -> void:
	recordMonitoredVariable()
	updateMinMaxLabels()

	# DEBUG:
	# Debug.watchList.historyIndex = currentHistoryIndex
	# Debug.watchList.historyValue = monitoredVariableHistory[currentHistoryIndex]

	headLineStart.x	= currentHistoryIndex
	headLineEnd.x	= currentHistoryIndex
	queue_redraw()


func _draw() -> void:
	if not isEnabled: return
	
	# Grid
	draw_multiline(gridLines,  gridColor, gridWidth, false)

	# Draw the "head"/"tracker" line
	draw_line(headLineStart, headLineEnd, headColor, 1.0, false)

	# Data
	draw_multiline(valueLines, lineColor, lineWidth, false)

#endregion
