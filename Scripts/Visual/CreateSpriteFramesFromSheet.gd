## Automatically sets up the [member sprite_frames] for an [AnimatedSprite2D] from a sprite sheet image.
## Adds a "Create Animations" button in the Godot Editor's Inspector Dock.
## TIP: This is a convenient alternative to the cumbersome workflow of manually clicking Add → Select File → Select Frames for each animation in the Godot Editor's SpriteFrames Dock.

@tool
extends AnimatedSprite2D

# TODO: Support variable number of frames per animation?

@export_tool_button("Create Animations", "SpriteFrames") var createSpriteFramesButton: Callable = createSpriteFramesInEditor


#region Parameters

const defaultAnimationName := &"default"

@export var spriteSheet:	Texture2D:
	set(newValue):
		if newValue != spriteSheet:
			spriteSheet = newValue
			if validateSheet(): calculateColumnsAndRows()
			else: columns = 0;  rows = 0

@export var frameSize:		Vector2i = Vector2i(16, 16):
	set(newValue):
		if newValue != frameSize:
			frameSize = newValue
			if validateSheet(): calculateColumnsAndRows()
			else: columns = 0;  rows = 0

## The number of frames to add to each animation, starting from its value in [member animationStartFrames]
## May be clamped to the actual number of frames available as determined by the [member spriteSheet] size & [member frameSize]
@export_range(1, 256, 1, "or_greater") var framesPerAnimation: int = 2

## A [Dictionary] where the keys are animation names, and their values are the first frame of that animation,
## counting from 0 at the top-left of the [member spriteSheet] and increasing right and downwards.
## Each animation must have the same number of frames in the [member spriteSheet] image.
@export var animationStartFrames: Dictionary[StringName, int] = { &"default": 0 }

## If `true` then the animations are created when this node is [method _ready] at game runtime.
## If `false` (default) then animations must be manually created at development time inside the Godot Editor
## by clicking the custom button in the Inspector Dock.
@export var shouldCreateAnimationsOnReady: bool = false

#endregion


#region State
# TBD: Recalculate `frameSize` when `columns` or `rows` are directly modified?
var columns:int
var rows:	int
#endregion


func _ready() -> void:
	# NOTE: This is a `@tool` script, meaning it can run inside the Godot Editor,
	# so we don't want to automatically recreate animations
	# before the developer presses the button in the Godot Inspector UI.
	if shouldCreateAnimationsOnReady \
	and not Engine.is_editor_hint()  \
	and validateSheet():
		calculateColumnsAndRows()
		createSpriteFrames()


#region Validation

func validateSheet() -> bool:
	if not spriteSheet:
		printError("validateSheet(): spriteSheet is missing")
		return false

	var sheetSize: Vector2i = spriteSheet.get_size()

	if  sheetSize.x <= 0 or sheetSize.y <= 0:
		printError(str("validateSheet() sheetSize <= 0: ", sheetSize))
		return false
	
	if  frameSize.x <= 0 or frameSize.y <= 0:
		printError(str("validateSheet() frameSize <= 0: ", frameSize))
		return false

	if  sheetSize.x % frameSize.x != 0 or sheetSize.y % frameSize.y != 0:
		printWarning(str("validateSheet(): spriteSheet size: ", sheetSize, " cannot divide evenly by frameSize: ", frameSize))
		return false
	# else
	return true


## Verifies [member animationStartFrames] and checks each animation's starting and ending frame is within the total count defined by [member columns] * [member rows]
func validateAnimations() -> bool:
	if  animationStartFrames.is_empty():
		printError("validateAnimations(): animationStartFrames is empty")
		return false

	var totalFrames:int = columns * rows
	if  totalFrames <= 0:
		printError(str("validateAnimations(): totalFrames <= 0: ", columns, " × ", rows, " • Call calculateColumnsAndRows()"))
		return false 
		
	var startFrame:	int
	var lastFrame:	int

	for animationName: StringName in animationStartFrames:

		startFrame = animationStartFrames[animationName]
		lastFrame  = startFrame + framesPerAnimation - 1

		if startFrame < 0 or startFrame >= totalFrames or startFrame > lastFrame:
			printWarning(str("createSpriteFrames(): ", animationName, " has invalid starting frame: ", startFrame, ", framesPerAnimation: ", framesPerAnimation, ", last frame: ", lastFrame, ", total columns * rows in sheet: ", totalFrames))
			return false

		if lastFrame >= totalFrames:
			printWarning(str("createSpriteFrames(): ", animationName, " has invalid ending frame: ", lastFrame, ", start frame: ", startFrame, ", framesPerAnimation: ", framesPerAnimation, ", total columns * rows in sheet: ", totalFrames))
			return false

	return true

#endregion


#region Interface

## Sets [member columns] & [member rows] from the dimensions of the [member spriteSheet] divided by [member frameSize] 
## IMPORTANT: [method validateSheet] should be called to verify all parameters first.
func calculateColumnsAndRows() -> Vector2i:
	columns = 0; rows = 0 # Reset in case there's a failure ahead
	var sheetSize: Vector2i = spriteSheet.get_size()

	@warning_ignore_start("integer_division") # validateSheet() should have already checked divisibility with %
	columns	= sheetSize.x / frameSize.x
	rows	= sheetSize.y / frameSize.y
	@warning_ignore_restore("integer_division")

	if  framesPerAnimation > columns * rows:
		framesPerAnimation = columns * rows

	return Vector2i(columns, rows)


func createSpriteFramesInEditor() -> SpriteFrames:
	var newSpriteFrames: SpriteFrames			= createSpriteFrames(false) # not updateSelf
	if  newSpriteFrames:
		var undoManager: EditorUndoRedoManager  = EditorInterface.get_editor_undo_redo()
		undoManager.create_action("Create AnimatedSprite2D Sprite Frames Animations")
		undoManager.add_do_property(self,	&"sprite_frames", newSpriteFrames)
		undoManager.add_undo_property(self,	&"sprite_frames", self.sprite_frames)
		undoManager.commit_action()
	return self.sprite_frames # TBD: Return current frames or `null` on failure?


## Creates and returns a new set of [SpriteFrames] built from the [member spriteSheet]
## and if [param updateSelf] is `true` (default), updates this sprite's own [member AnimatedSprite2D.sprite_frames] and [member AnimatedSprite2D.animation]
func createSpriteFrames(updateSelf: bool = true) -> SpriteFrames:
	# Validate parameters

	if columns <= 0 or rows <= 0:
		printError(str("createSpriteFrames() columns/rows <= 0: ", columns, ",", rows, " • Call calculateColumnsAndRows()"))
		return null

	# Make sure the sheet can be divided evenly so that all frames are the same size
	var sheetSize: Vector2i = spriteSheet.get_size()
	if  sheetSize.x % columns != 0 or sheetSize.y % rows != 0:
		printWarning(str("createSpriteFrames(): spriteSheet size ", sheetSize, " cannot divide evenly by grid ", Vector2i(columns, rows)))
		return null

	if not validateAnimations(): return null

	# Use/overwrite existing `sprite_frames` or create a new set
	
	var newSpriteFrames: SpriteFrames
	
	if updateSelf: newSpriteFrames = self.sprite_frames

	if not newSpriteFrames:
		newSpriteFrames	= SpriteFrames.new()
		
		# Remove the empty &"default" animation
		if not newSpriteFrames.get_animation_names().is_empty():
			newSpriteFrames.remove_animation(newSpriteFrames.get_animation_names()[0]) # AVOID: &"default" may change in future Godot versions so we shouldn't hardcode the name, just whatever the first animation is
		
		if updateSelf: self.sprite_frames = newSpriteFrames

	# Add frames for each animation in the list
	for animationName: StringName in animationStartFrames:
		addFramesToAnimation(newSpriteFrames, animationName, animationStartFrames[animationName], framesPerAnimation)

	# DESIGN: If the new set of frames has our currently playing animation, let it be.
	# If our current animation is not already in the new set of frames
	# or it's an empty animation (i.e. Godot's &"default" placeholder),
	# then play the first animation from the new set.
	if updateSelf and (
	not newSpriteFrames.has_animation(self.animation)
	or  newSpriteFrames.get_frame_count(self.animation) <= 0):
		self.animation = animationStartFrames.keys().front()

	return newSpriteFrames


## Builds an animation from the [member spriteSheet] according to [member frameSize] etc.
## WARNING: Overwrites any existing animation/frames with the same name!
## TIP: If [param preserveExistingProperties] is `true` (default) then [method SpriteFrames.clear] is used instead of [method SpriteFrames.remove_animation] in case of a conflict.
## [method SpriteFrames.clear] only removes an existing animation's frames while preserving other properties such as framerate etc.
func addFramesToAnimation(
	newSpriteFrames: SpriteFrames,
	animationName:	 StringName,
	startFrame:		 int,
	frameCount:		 int = self.framesPerAnimation,
	preserveExistingProperties: bool = true) -> void:

	# If there is already an animation with the same name, replace it
	if  newSpriteFrames.has_animation(animationName):
		printLog(str("addFramesToAnimation() replacing existing animation: ", animationName))
		if preserveExistingProperties:
			newSpriteFrames.clear(animationName) # Keeps FPS etc.
		else:
			newSpriteFrames.remove_animation(animationName)
			newSpriteFrames.add_animation(animationName)
	else:
		newSpriteFrames.add_animation(animationName)

	var frameIndex:			int
	var frameCoordinates:	Vector2i
	var frameTexture:		AtlasTexture
		
	for frameOffset: int in frameCount:
		frameIndex			= startFrame + frameOffset
		frameCoordinates	= Vector2i(frameIndex % columns, floori(float(frameIndex) / columns))
		frameTexture		= AtlasTexture.new()
		frameTexture.atlas  = spriteSheet
		frameTexture.region = Rect2(Vector2(frameCoordinates * frameSize), Vector2(frameSize))
		newSpriteFrames.add_frame(animationName, frameTexture)

#endregion


#region Debugging

func printLog(message: String) -> void:
	if Engine.is_editor_hint(): print(str(self, ": ", message))
	else: Debug.printLog(message, self)


func printWarning(message: String) -> void:
	if Engine.is_editor_hint(): push_warning(str(self, ": ", message))
	else: Debug.printWarning(message, self)


func printError(message: String) -> void:
	if Engine.is_editor_hint(): push_error(str(self, ": ", message))
	else: Debug.printError(message, self)

#endregion
