## Displays debugging information and charts about the entity and other components or nodes.
## TIP: See [NodePath] documentation for examples of paths.

class_name DebugComponent
extends Component

# TODO: Use `PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT`?


#region Parameters
@export_node_path var propertiesToChart: Array[NodePath]
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
		if shouldShowDebugInfo: printDebug(str("convertPathsToAbsolute() relativePath: ", relativePath, " → ", absolutePath))
		absolutePaths.append(absolutePath)

	return absolutePaths


func createCharts() -> void:
	var nodeAndPropertyPaths: Array[NodePath]

	for path: NodePath in propertiesToChartAbsolutePaths:
		nodeAndPropertyPaths = Tools.splitPathIntoNodeAndProperty(path)
		# DEBUG: Debug.printLog(str("path: ", path, ", nodePath: ", nodeAndPropertyPaths[0], ", propertyPath: ", nodeAndPropertyPaths[1]))
		Debug.createChartWindow(nodeAndPropertyPaths[0], nodeAndPropertyPaths[1], self.chartVerticalHeight, self.chartValueScale)


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
