## YOU DIED! Script for any node (recommended to be a [CanvasLayer]) which displays "Game Over" graphics and pauses the gameplay when an entity's (such the player) [HealthComponent] drops to 0.
## Add game-specific nodes/labels/etc. for the Game Over visuals as children of this node; this script automatically hides the node on [method _ready] and makes it visible when the game is over.
## For other game-specific animations or conditions, extend from this script and override the [method displayGameOver] method. IMPORTANT: `super.displayGameOver()` MUST Be called.

class_name GameOver
extends Node


#region Parameters
## The index into the [member GameState.players] array.
## NOTE: Ignored if [member entityOverride] is set.
@export var playerIndex: int = 0

## A custom [Entity] instead of a member of the [member GameState.players] array.
## NOTE: Overrides [member playerIndex].
@export var entityOverride: Entity

@export var isEnabled: bool = true
#endregion


#region State
var entityToMonitor: Entity:
	get: return entityOverride if entityOverride else player
#endregion


#region Dependencies
var player: Entity:
	get: return GameState.getPlayer(playerIndex)

var healthComponent: HealthComponent:
	get: return entityToMonitor.findFirstComponentSubclass(HealthComponent)
#endregion


func _ready() -> void:
	self.visible = false # Hide Game Over graphics
	self.get_tree().process_mode = Node.PROCESS_MODE_ALWAYS # Run even when the rest of the scene tree is paused
	connectSignals()


func connectSignals() -> void:
	Tools.reconnectSignal(healthComponent.healthDidZero, self.healthComponent_healthDidZero)


func healthComponent_healthDidZero() -> void:
	if isEnabled: 
		disconnect(&"healthDidZero", self.healthComponent_healthDidZero)
		displayGameOver()


## Pauses the gameplay and makes the node visible.
## For other game-specific animations, override this method.
## IMPORTANT: `super.displayGameOver()` MUST Be called.
func displayGameOver() -> void:
	GameState.gameDidOver.emit() # Let all know You Died.
	self.get_tree().process_mode = Node.PROCESS_MODE_DISABLED # Pause the gameplay
	self.visible = true # Show Game Over graphics
