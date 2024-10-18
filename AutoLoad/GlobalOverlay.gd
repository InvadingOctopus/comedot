## AutoLoad
## A scene containing graphics which are overlaid on top of or underneath the actual game content at all times.
## Used for performing transition effects between scenes such as fade-in and fade-out.
## The [process_mode] is set to `PROCESS_MODE_ALWAYS` which ignores the [SceneTree.paused] flag in order to perform transition animations while the actual gameplay is paused.

#class_name GlobalOverlay
extends Node


#region Parameters
var maximumNumberOfSounds: int = 10 # TBD
#endregion


#region State
var pauseOverlay: PauseOverlay
var audioPlayers: Array[AudioStreamPlayer2D]
var currentAudioPlayerIndex: int
#endregion


#region Signals
signal didShowPauseOverlay
signal didHidePauseOverlay
#endregion


#region Dependencies
const pauseOverlayScene := preload("res://UI/PauseOverlay.tscn")

@onready var foregroundOverlay	:CanvasLayer = %ForegroundOverlay
@onready var animationPlayer	:AnimationPlayer = %AnimationPlayer
@onready var pauseButton		:Button = %PauseButton
@onready var labelsList			:TemporaryLabelList = %LabelsList
@onready var sounds				:Node = %Sounds
#endregion


func showPauseVisuals(isPaused: bool) -> void:
	if isPaused: GlobalOverlay.fadeIn()
	else: GlobalOverlay.fadeOut()

	pauseButton.updateState()
	pauseButton.visible = isPaused
	
	if isPaused:
		
		if not self.pauseOverlay:
			self.pauseOverlay = pauseOverlayScene.instantiate() # NOTE: Create only here; not in property getter
		
		if pauseOverlay.get_parent() != foregroundOverlay: 
			foregroundOverlay.add_child(pauseOverlay)
			pauseOverlay.owner = foregroundOverlay # Necessary for persistence to a [PackedScene] for save/load.
		foregroundOverlay.move_child(pauseOverlay, 1)  # Put it above the fullscreen overlay effect.
		pauseOverlay.visible = true # Just in case
		didShowPauseOverlay.emit()

	elif not isPaused and pauseOverlay:
		foregroundOverlay.remove_child(pauseOverlay)
		self.pauseOverlay = null
		didHidePauseOverlay.emit()


func createTemporaryLabel(text: String) -> Label:
	return labelsList.createTemporaryLabel(text)


## Creates an [AudioStreamPlayer2D], plays the specified sound, then deletes the node.
## Used for playing sound effects for nodes and entities that may be deleted before the audio finishes playing,
## such as enemy destruction or collectible pickups etc.
## If [param stream] is `null`, then a [AudioStreamPlayer2D] node will be created only, but not played or automatically removed later.
## Returns: The newly created [AudioStreamPlayer2D] node.
func createAudioPlayer(
	stream:   AudioStream,
	position: Vector2 = Vector2.ZERO,
	bus:	  StringName = Global.AudioBuses.sfx) -> AudioStreamPlayer2D:
	
	# Check the limit on maximum number of sounds
	# TODO: A better implementation, like [TemporaryLabelList]'s?
	
	if sounds.get_child_count() >= maximumNumberOfSounds:
		# Delete the oldest sound (the one at the top of the subtree)
		sounds.remove_child(sounds.get_child(0))

	# Create the new sound
	var audioPlayer: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	audioPlayer.bus = bus
	audioPlayer.stream = stream
	audioPlayer.position = position
	
	sounds.add_child(audioPlayer, true) # force_readable_name
	audioPlayer.owner = sounds # Necessary for persistence to a [PackedScene] for save/load.
	audioPlayer.add_to_group(Global.Groups.audio, true) # persistent 
	
	if stream:
		audioPlayer.play() # TBD: Add playback position argument? TBD: Find a way to move along with node and continue playing after the node is destroyed?
		audioPlayer.finished.connect(audioPlayer.queue_free)
	
	return audioPlayer


## Creates a "pool" of reusable [AudioStreamPlayer2D] nodes for [method playAudioPlayerPool].
## May provide better performance compared to [method createAudioPlayer].
## NOTE: Deletes all existing children already in the `Sounds` node.
func createAudioPlayerPool() -> Array[AudioStreamPlayer2D]:
	# Delete existing children
	self.audioPlayers.clear()
	Tools.removeAllChildren(sounds)

	# Fill the pool
	for count in maximumNumberOfSounds:
		var newAudioPlayer: AudioStreamPlayer2D = createAudioPlayer(null)
		self.audioPlayers.append(newAudioPlayer)
	
	currentAudioPlayerIndex = 0 # Reset the index
	return self.audioPlayers


## Plays a sound via one of the existing [AudioStreamPlayer2D] nodes from the "pool" in the `Sounds` parent node.
## May provide better performance compared to [method createAudioPlayer].
## Used for playing sound effects for nodes and entities that may be deleted before the audio finishes playing,
## such as enemy destruction or collectible pickups etc.
## Returns: The [AudioStreamPlayer2D] node which was used.
func playAudioPlayerPool(
	stream:   AudioStream,
	position: Vector2 = Vector2.ZERO,
	_bus:	  StringName = Global.AudioBuses.sfx) -> AudioStreamPlayer2D:
	
	# Cycle through the available AudioStremPlayer2D nodes,
	# so we can have a pool of simultaneous sounds up to a limit.

	var audioPlayer: AudioStreamPlayer2D

	if audioPlayers.size() <= 0:
		createAudioPlayerPool()
		# TBD: Debug.printWarning("No AudioStreamPlayer2D in audioPlayers pool", self)
		# return null
	
	audioPlayer = audioPlayers[currentAudioPlayerIndex]
	
	currentAudioPlayerIndex += 1
	if currentAudioPlayerIndex >= audioPlayers.size():
		currentAudioPlayerIndex = 0

	# Configure the new sound
	audioPlayer.stream = stream
	audioPlayer.position = position
	audioPlayer.play() # TBD: Add playback position argument? TBD: Find a way to move along with node and continue playing after the node is destroyed?
	
	return audioPlayer

#region Animations

## Fades in the global overlay, which may be a solid black rectangle, effectively fading OUT the actual game content.
func fadeIn() -> void:
	animationPlayer.play(Animations.overlayFadeIn)
	await animationPlayer.animation_finished


## Fades out the global overlay, which may be a solid black rectangle, effectively fading IN the actual game content.
func fadeOut() -> void:
	# Playing the fade-in animation backwards allows for smoother-looking blending from the current values,
	# in case the fade-out happens during the previous fade-in.
	# TODO: CHECK: Is the visibility still set correctly afterwards?
	animationPlayer.play_backwards(Animations.overlayFadeIn)
	#animationPlayer.play(Animations.overlayFadeOut)
	await animationPlayer.animation_finished

#endregion
