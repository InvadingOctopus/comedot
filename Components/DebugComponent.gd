## Displays debugging information and charts about the entity and other components or nodes.
## TIP: See [NodePath] documentation for examples of paths.

class_name DebugComponent
extends Component

# TODO: Use `PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT`?


#region Parameters

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled: # Avoid unnecessary updateLabelsVisibility()
			isEnabled = newValue
			self.set_process(isEnabled) # PERFORMANCE: Set once instead of every frame
			if self.is_node_ready(): updateLabelsVisibility()


@export_group("Label Overlays")

## A list of [NodePaths] of the nodes & their properties to show [Label]s for.
## Example: `../HealthComponent:health:value` (use `/` for nodes and `:` for properties)
@export_node_path var propertiesToLabel: Array[NodePath]:
	set(newValue):
		if newValue != propertiesToLabel:
			propertiesToLabel = newValue
			self.set_process(not propertiesToLabel.is_empty())
			if self.is_node_ready(): %PropertiesLabel.visible = not propertiesToLabel.is_empty()

@export var shouldHideLabelsUntilHover: bool = false:
	set(newValue):
		if newValue != shouldHideLabelsUntilHover:
			shouldHideLabelsUntilHover = newValue
			if self.is_node_ready(): updateLabelsVisibility()


@export_group("Chart Windows")

## A list of [NodePaths] of the nodes & their properties to create [Chart] windows for.
## Example: `../CharacterBodyComponent:body:velocity:x` (use `/` for nodes and `:` for properties)
@export_node_path var propertiesToChart: Array[NodePath]

@export_range(100, 200, 5) var chartVerticalHeight: float = 100
@export_range(0.1, 2.0, 0.05) var chartValueScale:  float = 0.5

#endregion


#region State
@onready var entityLabel:		Label = %EntityLabel
@onready var propertiesLabel:	Label = %PropertiesLabel

var propertiesToChartAbsolutePaths: Array[NodePath]
var propertiesToLabelAbsolutePaths: Array[NodePath]
#endregion


func _ready() -> void:
	%PropertiesLabel.self_modulate = self.randomDebugColor # Differentiate from other DebugComponents
	updateLabelsVisibility()
	self.set_process(isEnabled) # Apply setter because Godot doesn't on initialization

	if not isEnabled: return

	entityLabel.text = parentEntity.name
	entityLabel.tooltip_text = parentEntity.logFullName

	propertiesToChartAbsolutePaths = convertPathsToAbsolute(propertiesToChart)
	propertiesToLabelAbsolutePaths = convertPathsToAbsolute(propertiesToLabel)
	createCharts()


## Convert the `./` paths to the absolute representation (from `/root/`) including the property paths `:`
func convertPathsToAbsolute(relativePaths: Array[NodePath]) -> Array[NodePath]:
	var absolutePath:	NodePath
	var absolutePaths:	Array[NodePath]

	for relativePath: NodePath in relativePaths:
		if not self.get_node(relativePath):
			printWarning(str("Invalid path: ", relativePath))
			continue
		absolutePath = Tools.convertRelativeNodePathToAbsolute(self, relativePath)
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


#region Labels

func registerEntity(newParentEntity: Entity) -> void:
	super.registerEntity(newParentEntity)
	if self.is_node_ready():
		entityLabel.text = parentEntity.name
		entityLabel.tooltip_text = parentEntity.logFullName


func updateLabelsVisibility() -> void:
	# DESIGN: The Entity/Component name labels can be set manually via "Editable Children"
	$VisibilityToggleHotspot.visible = isEnabled and shouldHideLabelsUntilHover
	%Labels.visible = isEnabled and not shouldHideLabelsUntilHover
	%Labels.z_index = 2000 if shouldHideLabelsUntilHover else 100
	%PropertiesLabel.visible = not propertiesToLabel.is_empty()


func _process(_delta: float) -> void:
	if propertiesToLabel.is_empty(): # In case the array was modified at runtime
		self.set_process(false)
		return
	$VisibilityToggleHotspot.modulate = Color(randf(), randf(), randf())
	updatePropertiesLabel()


func updatePropertiesLabel() -> void:
	# TODO: PERFORMANCE: More efficient lookups
	var nodeAndPropertyPaths: Array[NodePath]
	var nodeToWatch: Node
	var propertiesText: String = ""

	for path: NodePath in propertiesToLabelAbsolutePaths:
		nodeAndPropertyPaths = Tools.splitPathIntoNodeAndProperty(path)
		# DEBUG: Debug.printLog(str("path: ", path, ", nodePath: ", nodeAndPropertyPaths[0], ", propertyPath: ", nodeAndPropertyPaths[1]))
		nodeToWatch = self.get_tree().current_scene.get_node(nodeAndPropertyPaths[0]) # TBD: Should it be `self` or the SceneTree root?
		propertiesText += str(nodeAndPropertyPaths[1].get_subname(nodeAndPropertyPaths[1].get_subname_count() - 1), ": ", nodeToWatch.get_indexed(nodeAndPropertyPaths[1]), "\n")

	propertiesLabel.text = propertiesText


func onVisibilityToggleHotspot_mouseEntered() -> void:
	if shouldHideLabelsUntilHover:
		%Labels.modulate = Color(%Labels.modulate, 1.0) # Recover from fade-out
		%Labels.visible = true


func onVisibilityToggleHotspot_mouseExited() -> void:
	if shouldHideLabelsUntilHover: Animations.fadeOut(%Labels, 2.0) # Fade slowly instead of hiding instantly, to allow some time to hover over the Entity name to see its tooltip

#endregion
