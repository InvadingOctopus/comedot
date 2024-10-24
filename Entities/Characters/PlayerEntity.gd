## A subclass of [Entity] specialized for player-controlled characters.
## ALERT: Game-specific subclasses which extend [PlayerEntity] MUST call `_super.ready()` etc. if those methods are overridden.

class_name PlayerEntity
extends Entity


#region Shortcuts
# Quick access to common components
# NOTE: Not cached, because components may change during runtime.
# INFO: Use direct access on Dictionary for better performance instead of `getComponent()`

var bodyComponent: CharacterBodyComponent:
	get: return self.components.get(&"CharacterBodyComponent")

var healthComponent: HealthComponent:
	get: return self.components.get(&"HealthComponent")

var statsComponent: StatsComponent:
	get: return self.components.get(&"StatsComponent")

var inventoryComponent: InventoryComponent:
	get: return self.components.get(&"InventoryComponent")

var actionsComponent: ActionsComponent:
	get: return self.components.get(&"ActionsComponent")

var upgradesComponent: UpgradesComponent:
	get: return self.components.get(&"UpgradesComponent")

#endregion


func _enter_tree() -> void:
	super._enter_tree()
	self.add_to_group(Global.Groups.players, true) # persistent


func _ready() -> void:
	printLog("_ready()")
	GameState.addPlayer(self)
	GameState.playerReady.emit(self)


func _exit_tree() -> void:
	super._exit_tree()
	GameState.removePlayer(self)
