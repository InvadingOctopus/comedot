## YOU DIED! Script for any node (recommended to be a [CanvasLayer]) which displays "Game Over" graphics and pauses the gameplay when the global [signal GameState.gameDidOver] signal is emitted, 
## such as when the player entity's [HealthComponent] drops to 0.
## Add game-specific nodes/labels/etc. for the Game Over visuals as children of this node; this script automatically hides the node on [method _ready] and makes it visible when the game is over.
## For other game-specific animations or conditions, extend from this script and override the [method displayGameOver] method. IMPORTANT: `super.displayGameOver()` MUST Be called.
## @experimental

class_name GameOver
extends Node

# TODO: Option to restart
# TODO: Avoid Game Over during transitions


#region Parameters

## Triggers Game Over after receiving the [signal GameState.playerRemoved] signal if the [member GameState.players] array is empty, i.e. after the last player [Entity] has been removed.
## WARNING: This may trigger an unintended Game Over during scene TRANSITIONS! Such as when calling [method SceneManager.transitionToScene] because of course it removes all existing nodes.
@export var shouldGameOverAfterAllPlayersRemoved: bool = false

@export var isEnabled: bool = true
@export var debugMode: bool = false
#endregion


#region State
var isDisplayingGameOver: bool = false
#endregion


func _ready() -> void:
	self.visible = false # Hide Game Over graphics
	self.process_mode = Node.PROCESS_MODE_ALWAYS # Run even when the rest of the scene tree is paused
	connectSignals()


func connectSignals() -> void:
	Tools.connectSignal(GameState.playerRemoved, self.gameState_playerRemoved)
	Tools.connectSignal(GameState.gameDidOver,   self.gameState_gameDidOver)


func disconnectSignals() -> void:
	Tools.disconnectSignal(GameState.playerRemoved, self.gameState_playerRemoved)
	Tools.disconnectSignal(GameState.gameDidOver,   self.gameState_gameDidOver)


func gameState_playerRemoved(player: Entity) -> void:
	if isEnabled and shouldGameOverAfterAllPlayersRemoved and GameState.players.is_empty():
		if debugMode: Debug.printDebug(str("gameState_playerRemoved() last player Entity: ", player), self)
		disconnectSignals()
		if not isDisplayingGameOver: displayGameOver()


func gameState_gameDidOver() -> void:
	if debugMode: Debug.printDebug(str("gameState_gameDidOver(): GameOver.isEnabled: ", isEnabled), self)
	if isEnabled:
		# NOTE: Make sure ALL players are dead before Overing the Game!
		if GameState.players.is_empty():
			disconnectSignals()
			if not isDisplayingGameOver: displayGameOver()
		else:
			Debug.printDebug(str("gameState_gameDidOver(): GameState.players remaining: ", GameState.players.size(), " ", GameState.players), self)


## Pauses the gameplay and makes the node visible.
## For other game-specific animations, override this method.
## IMPORTANT: `super.displayGameOver()` MUST Be called.
func displayGameOver() -> void:
	if isDisplayingGameOver: 
		Debug.printDebug("displayGameOver() called while already isDisplayingGameOver")
		return
	
	Debug.printLog("displayGameOver()", self)
	
	var currentScene: Node
	if is_instance_valid(self) and is_instance_valid(self.get_tree()):
		currentScene = self.get_tree().current_scene
	if not currentScene: # Avoid crash if triggered during scene transitions
		Debug.printWarning(str("displayGameOver(): Cannot get SceneTree.current_scene! Called during scene transition? shouldGameOverAfterAllPlayersRemoved: ", shouldGameOverAfterAllPlayersRemoved), self)
		return 

	currentScene.process_mode = Node.PROCESS_MODE_DISABLED # Pause the gameplay. FIXME: Weird Godot error: "Condition "!is_inside_tree()" is true. Returning: false"
	self.visible = true # Show Game Over graphics
	self.isDisplayingGameOver = true
