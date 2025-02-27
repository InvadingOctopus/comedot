## Displays debugging information and charts about the entity and other components or nodes.
## TIP: See [NodePath] documentation for examples of paths.

class_name DebugComponent
extends Component

# TODO: Use `PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT`?


#region Parameters

## A list of [NodePaths] of the nodes & their properties to create [Chart] windows for.
## Example: `../CharacterBodyComponent:body:velocity:x` (use `/` for nodes and `:` for properties)
@export_node_path var propertiesToChart: Array[NodePath]

## A list of [NodePaths] of the nodes & their properties to show [Label]s for.
## Example: `../HealthComponent:health:value` (use `/` for nodes and `:` for properties)
@export_node_path var propertiesToWatch: Array[NodePath]

@export_range(100, 200, 5) var chartVerticalHeight: float = 100
@export_range(0.1, 2.0, 0.05) var chartValueScale:  float = 0.5

@export var isEnabled: bool = true
#endregion


#region State
@onready var label: Label = %DebugLabel
var propertiesToChartAbsolutePaths: Array[NodePath]
var propertiesToWatchAbsolutePaths: Array[NodePath]
#endregion


func _ready() -> void:
	label.visible = isEnabled
	if not isEnabled: return

	propertiesToChartAbsolutePaths = convertPathsToAbsolute(propertiesToChart)
	propertiesToWatchAbsolutePaths = convertPathsToAbsolute(propertiesToWatch)
	createCharts()


## Convert the `./` paths to the absolute representation (from `/root/`) including the property paths `:`
func convertPathsToAbsolute(relativePaths: Array[NodePath]) -> Array[NodePath]:
	var absolutePath:	NodePath
	var absolutePaths:	Array[NodePath]

	for relativePath: NodePath in relativePaths:
		absolutePath = Tools.convertRelativePathToAbsolute(self, relativePath)
		if debugMode: printDebug(str("convertPathsToAbsolute() relativePath: ", relativePath, " → ", absolutePath))
		absolutePaths.append(absolutePath)

	return absolutePaths


func createCharts() -> void:
	var nodeAndPropertyPaths: Array[NodePath]

	for path: NodePath in propertiesToChartAbsolutePaths:
		nodeAndPropertyPaths = Tools.splitPathIntoNodeAndProperty(path)
		# DEBUG: Debug.printLog(str("path: ", path, ", nodePath: ", nodeAndPropertyPaths[0], ", propertyPath: ", nodeAndPropertyPaths[1]))
		var newChart: Chart = Debug.createChartWindow(nodeAndPropertyPaths[0], nodeAndPropertyPaths[1], self.chartVerticalHeight, self.chartValueScale)
		newChart.lineColor  = Color(0.2 * randi_range(1, 4), 0.2 * randi_range(1, 5), 0.2 * randi_range(1, 5), 0.5) # Give a distinct random color to each chart


func _physics_process(_delta: float) -> void:
	if not isEnabled: return
	updateLabel()


func updateLabel() -> void:
	# TODO: PERFORMANCE: More efficient lookups
	var nodeAndPropertyPaths: Array[NodePath]
	var nodeToWatch: Node
	var labelText: String = ""

	for path: NodePath in propertiesToWatchAbsolutePaths:
		nodeAndPropertyPaths = Tools.splitPathIntoNodeAndProperty(path)
		# DEBUG: Debug.printLog(str("path: ", path, ", nodePath: ", nodeAndPropertyPaths[0], ", propertyPath: ", nodeAndPropertyPaths[1]))
		nodeToWatch = self.get_node(nodeAndPropertyPaths[0]) # TBD: Should it be `self` or the SceneTree root?
		labelText += str(nodeAndPropertyPaths[1].get_subname(nodeAndPropertyPaths[1].get_subname_count() - 1), ": ", nodeToWatch.get_indexed(nodeAndPropertyPaths[1]), "\n")

	label.text = labelText
