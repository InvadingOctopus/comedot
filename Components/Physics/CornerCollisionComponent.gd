## Places a set of 4 [Area2D] nodes at the corners of the entity's [Sprite2D],
## for helping other components quickly detect floors, walls and ceilings etc. in a specific direction.
## By default, the collision mask is set to `terrain` only.
## Requirements: [Sprite2D]
## Editable Children: [Area2D]

#@tool
class_name CornerCollisionComponent
extends Component


#region Parameters

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue
		# When this component is disabled, reset the collision flags only once, to avoid doing it every frame.
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
		if not sprite: sprite = parentEntity.findFirstChildOfType(Sprite2D) # TODO: Check that this also picks up [AnimatedSprite2D]
		return sprite

var areaNWCollisionCount:	int
var areaNECollisionCount:	int
var areaSECollisionCount:	int
var areaSWCollisionCount:	int

var isCollidingOnRight:		bool
var isCollidingOnLeft:		bool
var isCollidingOnTop:		bool
var isCollidingOnBottom:	bool

#endregion


#region Signals
# ...
#endregion


func _ready() -> void:
	setAreaPositions()


func _physics_process(_delta: float) -> void:
	pass


## Places the [Area2D]s at the corners of the entity's [Sprite2D]
func setAreaPositions() -> void:
	if not sprite: return # TBD: Should we reset the raycass to a default position if there is no sprite?
	var spriteRect: Rect2 = sprite.get_rect()

	areaNW.position = Tools.getRectCorner(spriteRect, Tools.CompassDirections.northWest)
	areaNE.position = Tools.getRectCorner(spriteRect, Tools.CompassDirections.northEast)
	areaSE.position = Tools.getRectCorner(spriteRect, Tools.CompassDirections.southEast)
	areaSW.position = Tools.getRectCorner(spriteRect, Tools.CompassDirections.southWest)

	#Debug.watchList.areaNW = areaNW.position
	#Debug.watchList.areaNE = areaNE.position
	#Debug.watchList.areaSE = areaSE.position
	#Debug.watchList.areaSW = areaSW.position


func setCollisionEnabled(enabled: bool) -> void:
	if not areasContainer: return
	for area: Area2D in areasContainer.get_children():
		#if is_instance_of(area, Area2D):
		area.monitoring  = enabled
		area.monitorable = enabled

	# TBD: Should the container node be toggled like this?
	if not enabled: areasContainer.process_mode = Node.PROCESS_MODE_DISABLED
	else: areasContainer.process_mode = Node.PROCESS_MODE_INHERIT


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
	#showDebugInfo()


func updateCollisionCount() -> void:
	areaNWCollisionCount = areaNW.get_overlapping_areas().size() + areaNW.get_overlapping_bodies().size()
	areaNECollisionCount = areaNE.get_overlapping_areas().size() + areaNE.get_overlapping_bodies().size()
	areaSECollisionCount = areaSE.get_overlapping_areas().size() + areaSE.get_overlapping_bodies().size()
	areaSWCollisionCount = areaSW.get_overlapping_areas().size() + areaSW.get_overlapping_bodies().size()


func showDebugInfo() -> void:
	Debug.watchList.NW = areaNWCollisionCount
	Debug.watchList.NE = areaNECollisionCount
	Debug.watchList.SE = areaSECollisionCount
	Debug.watchList.SW = areaSWCollisionCount
	Debug.watchList.left	= isCollidingOnLeft
	Debug.watchList.right	= isCollidingOnRight
	Debug.watchList.top		= isCollidingOnTop
	Debug.watchList.bottom	= isCollidingOnBottom
