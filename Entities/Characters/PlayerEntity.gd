## A subclass of [Entity] specialized for player-controlled characters.
## ALERT: Game-specific subclasses which extend [PlayerEntity] MUST call `super._ready()` etc. if those methods are overridden.

class_name PlayerEntity
extends Entity


#region Shortcuts
# Quick access to common components
# DESIGN: Not cached, because components may change during runtime.
# NOTE: Use `.get(StringName)` instead of direct access to avoid crash if missing.
# TIP: findFirstComponentSubclass() to include subclasses such as ShieldedHealthComponent
# PERFORMANCE: Use direct access on Dictionary for better performance instead of getComponent()

var actionsComponent: ActionsComponent:
	get: return self.components.get(&"ActionsComponent")

var bodyComponent: CharacterBodyComponent:
	get: return self.components.get(&"CharacterBodyComponent")

var healthComponent: HealthComponent: ## ALERT: Does NOT return subclasses like [ShieldedHealthComponent]
	get: return self.components.get(&"HealthComponent")

var inventoryComponent: InventoryComponent:
	get: return self.components.get(&"InventoryComponent")

var statsComponent: StatsComponent:
	get: return self.components.get(&"StatsComponent")

var tileBasedPositionComponent: TileBasedPositionComponent:
	get: return self.components.get(&"TileBasedPositionComponent")

var upgradesComponent: UpgradesComponent:
	get: return self.components.get(&"UpgradesComponent")

#endregion


func _enter_tree() -> void:
	super._enter_tree()
	self.add_to_group(Global.Groups.players, true) # persistent
	GameState.addPlayer(self) # DESIGN: Add player in _enter_tree() so that other scripts can quickly access the Entity even before its components are _ready()


func _ready() -> void:
	super._ready()
	printLog("􀆅 [b]_ready()")
	GameState.playerReady.emit(self)


func _exit_tree() -> void:
	super._exit_tree()
	GameState.removePlayer(self)
