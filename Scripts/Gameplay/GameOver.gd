## YOU DIED! Script for any node (recommended to be a [CanvasLayer]) which displays "Game Over" graphics and pauses the gameplay when the global [signal GameState.gameDidOver] signal is emitted, 
## such as when the player entity's [HealthComponent] drops to 0.
## Add game-specific nodes/labels/etc. for the Game Over visuals as children of this node; this script automatically hides the node on [method _ready] and makes it visible when the game is over.
## For other game-specific animations or conditions, extend from this script and override the [method displayGameOver] method. IMPORTANT: `super.displayGameOver()` MUST Be called.

class_name GameOver
extends Node

# TODO: Option to restart


#region Parameters
@export var isEnabled: bool = true
#endregion


#region State
var isDisplayingGameOver: bool = false
#endregion


func _ready() -> void:
	self.visible = false # Hide Game Over graphics
	self.process_mode = Node.PROCESS_MODE_ALWAYS # Run even when the rest of the scene tree is paused
	connectSignals()


func connectSignals() -> void:
	Tools.reconnectSignal(GameState.playerRemoved, self.gameState_playerRemoved)
	Tools.reconnectSignal(GameState.gameDidOver,   self.gameState_gameDidOver)


func disconnectSignals() -> void:
	Tools.disconnectSignal(GameState.playerRemoved, self.gameState_playerRemoved)
	Tools.disconnectSignal(GameState.gameDidOver,   self.gameState_gameDidOver)


func gameState_playerRemoved(_player: Entity) -> void:
	if isEnabled and GameState.players.is_empty():
		disconnectSignals()
		if not isDisplayingGameOver: displayGameOver()


func gameState_gameDidOver() -> void:
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
	if isDisplayingGameOver: return
	self.get_tree().current_scene.process_mode = Node.PROCESS_MODE_DISABLED # Pause the gameplay
	self.visible = true # Show Game Over graphics
	self.isDisplayingGameOver = true
