# SaveComponent - Proof of Concept

A component-based save/load system for persisting entity state across game sessions. This feature allows you to save and restore entity properties, component additions/removals, and track entity deletions.

## Overview

The SaveComponent system provides a flexible way to persist game state by:

- **Saving entity properties** - Track changes to specific properties on entities
- **Saving component changes** - Record when components are added, removed, or modified
- **Tracking entity removal** - Mark entities that should be deleted on load
- **JSON serialization** - Save and load state from JSON files

## Architecture

The system consists of three main components:

### 1. SavableStateManager (Autoload)

A singleton that manages the global save state. It stores data in `GameState.globalData` under the `"saveState"` key.

**Key Features:**
- Manages save state dictionary structure
- Provides JSON file save/load functionality
- Wraps entity data in `GameStateEntity` objects for easy manipulation
- Utilities for nested dictionary access

**Setup:**
Add `SavableStateManager` to your `GameState` autoload node.

### 2. SaveComponent

A component that can be added to any `Entity` to enable save/load functionality for that entity.

**Key Features:**
- **Active Persist**: Methods to create/remove components that automatically persist changes
- **Passive Persist**: Save entity properties on demand
- **Auto-apply**: Automatically applies saved changes when the entity loads

**Exported Properties:**
- `entityUid` (String) - Unique identifier for this entity in the save system
- `persistProps` (Array[String]) - List of entity property names to persist
- `persistFreed` (bool) - Whether to record entity removal when freed

### 3. PersistComponentPayload

A variant of `ComponentPayload` that automatically persists component changes when applied to entities with `SaveComponent`.

## Usage

### Basic Setup

1. **Add SavableStateManager to GameState:**
   - Open your `GameState` scene
   - Add `SavableStateManager` as a child node
   - The manager will automatically initialize on `_ready()`

2. **Add SaveComponent to an Entity:**
   - Add `SaveComponent.tscn` to your entity
   - Set a unique `entityUid` (e.g., "player", "enemy_001", "chest_42")
   - Configure `persistProps` with property names you want to save
   - Optionally enable `persistFreed` to track entity deletion

### Saving Entity Properties

**Passive Persist:**
```gdscript
# In your entity or component code
var saveComponent: SaveComponent = entity.getComponent(SaveComponent)
if saveComponent:
    saveComponent.save()  # Saves all properties in persistProps
```

**Manual Property Recording:**
```gdscript
# Direct access via SavableStateManager
var manager: SavableStateManager = GameState.get_node("SavableStateManager")
var entityWrapper = manager.getEntity("player_uid")
entityWrapper.recordProp("health", 100)
entityWrapper.recordProp("position", Vector2(100, 200))
```

### Saving Component Changes

**Active Persist Methods:**
```gdscript
# Use these methods instead of the regular Entity methods
var saveComponent: SaveComponent = entity.getComponent(SaveComponent)

# Create a component (persists automatically)
saveComponent.createNewComponentPersist(HealthComponent)

# Create multiple components
saveComponent.createNewComponentsPersist([HealthComponent, DamageComponent])

# Remove a component (persists automatically)
saveComponent.removeComponentPersist(HealthComponent)

# Remove multiple components
saveComponent.removeComponentsPersist([Component1, Component2])
```

### Saving and Loading Game State

**Save to File:**
```gdscript
var manager: SavableStateManager = GameState.get_node("SavableStateManager")

# Save all entities with SaveComponent
var saveables: Array[Node] = get_tree().get_nodes_in_group("saveables")
for node in saveables:
    if node.has_method("save"):
        node.save()

# Write to JSON file
manager.saveStateAsJson("user://saved_games/mysave.json")
```

**Load from File:**
```gdscript
var manager: SavableStateManager = GameState.get_node("SavableStateManager")

# Load state from JSON
if manager.loadStateFromFile("user://saved_games/mysave.json"):
    # Entities with SaveComponent will automatically apply changes on _ready()
    GameState.startMainScene()
```

**Reset Save State:**
```gdscript
var manager: SavableStateManager = GameState.get_node("SavableStateManager")
manager.resetSaveState()  # Clears all saved entity data
```

### Save State Structure

The save state is stored as a nested dictionary:

```json
{
  "entities": {
    "player_uid": {
      "propertyChanges": {
        "health": "100",
        "position": "Vector2(100, 200)"
      },
      "componentChanges": {
        "HealthComponent": {
          "action": "add",
          "properties": {}
        },
        "DamageComponent": {
          "action": "edit",
          "properties": {
            "damage": "25"
          }
        },
        "OldComponent": {
          "action": "remove"
        }
      },
      "removed": false
    }
  }
}
```

## Example: Complete Save/Load Flow

```gdscript
# 1. Setup - In your game scene
func _ready():
    # Entities with SaveComponent will auto-apply saved changes
    
# 2. During gameplay - Modify entity state
func takeDamage():
    entity.health -= 10
    var saveComponent = entity.getComponent(SaveComponent)
    if saveComponent:
        saveComponent.save()  # Persist the health change

# 3. Save game
func saveGame():
    var manager = GameState.get_node("SavableStateManager")
    
    # Save all entities
    var saveables = get_tree().get_nodes_in_group("saveables")
    for node in saveables:
        if node.has_method("save"):
            node.save()
    
    # Write to file
    manager.saveStateAsJson("user://saved_games/save1.json")

# 4. Load game
func loadGame():
    var manager = GameState.get_node("SavableStateManager")
    if manager.loadStateFromFile("user://saved_games/save1.json"):
        # Reload scene - entities will auto-apply saved state
        get_tree().reload_current_scene()
```

## Limitations & Notes

⚠️ **This is a proof of concept** - Use with caution in production code.

**Current Limitations:**
- Property values are serialized as strings using `var_to_str()` and `str_to_var()` - complex objects may not serialize correctly
- Component property modifications are recorded but not automatically applied (only component add/remove is auto-applied)
- No versioning system for save files
- No compression or encryption
- Entity UIDs must be manually managed to ensure uniqueness

**Best Practices:**
- Always set unique `entityUid` values for each entity
- Call `save()` on entities before writing to file
- Test save/load thoroughly with your specific data types
- Consider implementing save file versioning for production use

## Testing

See `SaveTest/` directory for example scenes demonstrating:
- Save/load UI menus
- Checkpoint system
- Entity state persistence


