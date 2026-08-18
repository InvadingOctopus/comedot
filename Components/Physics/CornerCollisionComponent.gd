## Places a set of 4 [Area2D] nodes at the corners of the entity's [Sprite2D],
## for helping other components quickly detect floors, walls and ceilings etc. in a specific direction.
## By default, the collision mask is set to `terrain` only.
## Requirements: [Sprite2D]
## Editable Children: [Area2D]

# @tool
class_name CornerCollisionComponent
extends Component


#region Parameters

@export var fitAreasAutomatically: bool = true

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue
		setCollisionEnabled(isEnabled)

#endregion


#region State

@onready var areasContainer: Node2D = %Areas
@onready var areaNW: Area2D = %AreaNW
@onready var areaNE: Area2D = %AreaNE
@onready var areaSE: Area2D = %AreaSE
@onready var areaSW: Area2D = %AreaSW

var sprite: Sprite2D:
	get:
		if not sprite: sprite = entity.findFirstChildOfType(Sprite2D) # TODO: Check that this also picks up [AnimatedSprite2D]
		return sprite

var areaNWCollisionCount:	int
var areaNECollisionCount:	int
var areaSECollisionCount:	int
var areaSWCollisionCount:	int

var isCollidingOnRight:		bool
var isCollidingOnLeft:		bool
var isCollidingOnTop:		bool
var isCollidingOnBottom:	bool

var defaultAreasProcessMode: Node.ProcessMode

#endregion


#region Signals
# ...
#endregion


func _ready() -> void:
	self.defaultAreasProcessMode = areasContainer.process_mode
	for area: Area2D in areasContainer.get_children():
		# Exclude all child Area2Ds from physics processing when disabled
		area.disable_mode = CollisionObject2D.DISABLE_MODE_REMOVE
	areasContainer.process_mode = self.defaultAreasProcessMode if isEnabled else Node.PROCESS_MODE_DISABLED
	if fitAreasAutomatically: setAreaPositions()


## Places the [Area2D]s at the corners of the entity's [Sprite2D]
func setAreaPositions() -> void:
	if not sprite: return # TBD: Should we reset the raycass to a default position if there is no sprite?
	var spriteRect: Rect2 = sprite.get_rect()

	areaNW.position = RectTools.getRectCorner(spriteRect, Tools.CompassVectors.northWest)
	areaNE.position = RectTools.getRectCorner(spriteRect, Tools.CompassVectors.northEast)
	areaSE.position = RectTools.getRectCorner(spriteRect, Tools.CompassVectors.southEast)
	areaSW.position = RectTools.getRectCorner(spriteRect, Tools.CompassVectors.southWest)

	if debugMode: printTrace([areaNW.position, areaNE.position, areaSE.position, areaSW.position])


func setCollisionEnabled(enabled: bool) -> void:
	if not areasContainer: return
	# DISABLE_MODE_REMOVE excludes the child Area2Ds from physics while disabled and emits signals for existing contacts when re-enabled.
	areasContainer.set_deferred(&"process_mode", self.defaultAreasProcessMode if enabled else Node.PROCESS_MODE_DISABLED) # set_deferred() avoids the Godot error: "Function blocked during in/out signal"


func onAreaEntered(_area: Area2D) -> void:
	updateFlags()


func onAreaExited(_area: Area2D) -> void:
	updateFlags()


func onBodyEntered(_body: Node2D) -> void:
	updateFlags()


func onBodyExited(_body: Node2D) -> void:
	updateFlags()


func updateFlags() -> void:
	updateCollisionCount()
	isCollidingOnLeft	= (areaNWCollisionCount >= 1) or (areaSWCollisionCount >= 1)
	isCollidingOnRight	= (areaNECollisionCount >= 1) or (areaSECollisionCount >= 1)
	isCollidingOnTop	= (areaNWCollisionCount >= 1) or (areaNECollisionCount >= 1)
	isCollidingOnBottom	= (areaSWCollisionCount >= 1) or (areaSECollisionCount >= 1)
	# DEBUG: showDebugInfo()


func updateCollisionCount() -> void:
	areaNWCollisionCount = areaNW.get_overlapping_areas().size() + areaNW.get_overlapping_bodies().size()
	areaNECollisionCount = areaNE.get_overlapping_areas().size() + areaNE.get_overlapping_bodies().size()
	areaSECollisionCount = areaSE.get_overlapping_areas().size() + areaSE.get_overlapping_bodies().size()
	areaSWCollisionCount = areaSW.get_overlapping_areas().size() + areaSW.get_overlapping_bodies().size()


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.addComponentWatchList(self, {
		NW		= areaNWCollisionCount,
		NE		= areaNECollisionCount,
		SE		= areaSECollisionCount,
		SW		= areaSWCollisionCount,
		left	= isCollidingOnLeft,
		right	= isCollidingOnRight,
		top		= isCollidingOnTop,
		bottom	= isCollidingOnBottom,
		})
