## Plots the value of a variable over time in a chart.
## NOTE: For best results, attach script to a [Node2D] which is a child of a [CanvasLayer] and vertically centered on the screen.

class_name Chart
extends Node2D

# TODO: Path validation
# TODO: More colors


#region Parameters

@export var nodeToMonitor:		NodePath ## See [NodePath] documentation for examples of paths.
@export var propertyToMonitor:	NodePath ## A path to the node's property, beginning with ":"

## How many instances of values to record for the [member Chart.propertyToMonitor].
# NOTE: This is the first INVALID index outside the bounds of the [member Chart.monitoredVariableHistory] array; it must be compared with a >=.
@export_range(100, 500, 50) var maxHistorySize: int = 300:
	set(newValue):
		maxHistorySize = newValue
		resizeArrays()

## The height of the Y axis on EACH side, positive and negative.
@export_range(100, 200, 5) var verticalHeight: float = 100

# Multiples the monitored variable's value by this scale, effectively reducing or enlarging the chart's Y axis, to better fit the screen.
@export_range(0.1, 2.0, 0.05) var valueScale: float = 0.5

@export var lineColor:	Color = Color(0.0, 1.0, 0.25, 0.5)
@export var gridColor:	Color = Color(0.0, 0.2, 0.3,  0.5)
@export var headColor:	Color = Color(0.5, 0.5, 0.75, 0.25) ## The color of the vertical "head" or "tracker" line.

@export var isEnabled:	bool = true

#endregion


#region State

@onready var nameLabel: Label = %NameLabel
@onready var maxLabel:  Label = %MaxLabel
@onready var minLabel:  Label = %MinLabel

var monitoredVariableHistory:	Array[float]
var currentHistoryIndex:		int = 0

var minRecordedValue:	float
var maxRecordedValue:	float

var valueLines:		PackedVector2Array
var gridLines:		PackedVector2Array

var lineWidth:		float = 1.0
var gridwidth:		float = 1.0 # NOTE: Grid lines may not be visible at smaller scales on a Nearest texture mapping.

var headLineStart:	Vector2
var headLineEnd:	Vector2

#endregion


func _ready() -> void:
	resizeArrays()
	createGridLines()
	updateNameLabel()


func resizeArrays() -> void:
	monitoredVariableHistory.resize(maxHistorySize)
	valueLines.resize(maxHistorySize * 2) # Each line needs 2 vectors


func _draw() -> void:
	if not isEnabled: return
	draw_multiline(gridLines,  gridColor, gridwidth, false)

	# Draw the "head" line
	draw_line(headLineStart, headLineEnd, headColor, 1.0, false)

	draw_multiline(valueLines, lineColor, lineWidth, false)


func _process(_delta: float) -> void:
	if not isEnabled: return
	recordMonitoredVariable()
	updateMinMaxLabels()

	# DEBUG:
	# Debug.watchList.historyIndex = currentHistoryIndex
	# Debug.watchList.historyValue = monitoredVariableHistory[currentHistoryIndex]

	headLineStart.x	= currentHistoryIndex
	headLineEnd.x	= currentHistoryIndex
	queue_redraw()


func recordMonitoredVariable() -> void:
	var node:  Node  = self.get_node(nodeToMonitor)
	if not is_instance_valid(node): return
	var value: float = node.get_indexed(propertyToMonitor)

	monitoredVariableHistory[currentHistoryIndex] = value * valueScale

	# Record the minimum and maximum values
	if value < minRecordedValue: minRecordedValue = value
	if value > maxRecordedValue: maxRecordedValue = value

	# DEBUG:
	# Debug.printLog(str("velocity: ", platformerPhysicsComponent.body.velocity.y))
	# Debug.printLog(str("currentHistoryIndex: ", currentHistoryIndex))

	# Add a line
	createLine(currentHistoryIndex) # NOTE: Update BEFORE incrementing `currentHistoryIndex`

	# Increment or wrap-around the index
	currentHistoryIndex += 1
	if currentHistoryIndex >= maxHistorySize:
		currentHistoryIndex = 0


func createLine(index: int) -> void:
	# NOTE: Each line needs 2 vectors.

	var currentLineIndex: int = index * 2

	# DEBUG:Debug.printLog(str("currentLineIndex: ", currentLineIndex))

	valueLines[currentLineIndex] = Vector2(currentHistoryIndex, 0)

	valueLines[currentLineIndex + 1] = Vector2( \
		currentHistoryIndex,
		# NOTE: Negative Y values must go DOWNWARDS in the chart
		# NOTE: If the monitored variable is 0 then there should be no line (cleaner and more accurate)
		-monitoredVariableHistory[currentHistoryIndex])

	# DEBUG:
	# Debug.printLog(str("Vector ", currentLineIndex, ": ", valueLines[currentLineIndex]))
	# Debug.printLog(str("Vector ", currentLineIndex+1, ": ", valueLines[currentLineIndex+1]))


func createGridLines() -> void:
	# TBD: Export these as parameters?

	var gridMinY:	float = -verticalHeight
	var gridMaxY:	float = verticalHeight

	var gridStepX:	int = 10
	var gridStepY:	int = 10

	headLineStart.y	= gridMinY
	headLineEnd.y	= gridMaxY

	# PERFORMANCE: Calculate and set the total size before appending each line.

	@warning_ignore("integer_division")
	var numberOfGridLinesX: int = maxHistorySize / gridStepX
	@warning_ignore("narrowing_conversion")
	var numberOfGridLinesY: int = (gridMaxY - gridMinY) / gridStepY

	# TODO: Verify calculation
	#gridLines.resize((numberOfGridLinesX * numberOfGridLinesY) * 2) # Each line needs 2 vectors.

	# DEBUG: Debug.printLog(str("numberOfGridLines X, Y: ", numberOfGridLinesX, ", ", numberOfGridLinesY))

	var start:	Vector2
	var end:	Vector2

	# Vertical lines (X Axis)

	start.y	= gridMinY
	end.y	= gridMaxY

	for line in numberOfGridLinesX:

		start.x	= gridStepX * line
		end.x	= gridStepX * line

		# DEBUG: Debug.printLog(str("line X #", line, ": ", start, " → ", end))

		gridLines.append(start)
		gridLines.append(end)

	# Horizontal lines (Y Axis)

	start.x	= 0
	start.y	= gridMinY
	end.x	= maxHistorySize
	end.y	= gridMinY

	for line in numberOfGridLinesY:
		# DEBUG: Debug.printLog(str("line Y #", line, ": ", start, " → ", end))

		gridLines.append(start)
		gridLines.append(end)

		# Go up

		start.y	+= gridStepY
		end.y	+= gridStepY


func updateNameLabel() -> void:
	nameLabel.text = str(propertyToMonitor)


func updateMinMaxLabels() -> void:
	minLabel.text = str("MIN: ", minRecordedValue)
	maxLabel.text = str("MAX: ", maxRecordedValue)
