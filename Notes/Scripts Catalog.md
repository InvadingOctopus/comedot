# Scripts Catalog

An index of reusable Comedot scripts that are not Components or Entities. Includes AutoLoads, Resources, UI scripts, scene scripts, tool helpers, editor plugin scripts, templates, and test helper scripts. Excludes `/Game/`, `/Temporary/`, `/Lab/`, the main `/Components/` and `/Entities/` trees, and scripts that actually extend Component or Entity classes even if they live in Templates or Tests.


## AutoLoads

* Debug: AutoLoad for debug output, log UI, watched values, and chart helpers.
* GameState: AutoLoad for global game state and event-bus signals. Intended for campaign/gameplay state, not player settings.
* Global: AutoLoad for framework-wide constants, flags, node groups, custom data keys, helper methods, and shared framework state.
* GlobalInput: AutoLoad for input action names, labels, and global keyboard shortcuts.
* GlobalSonic: AutoLoad scene for music, sound effects, and script-generated beeps that should outlive normal gameplay nodes.
* GlobalUI: AutoLoad scene for always-present overlays, pause visuals, transitions, and other UI above game content.
* SceneManager: AutoLoad that manages scene changes through a navigation stack and transition flow.
* Settings: AutoLoad for user settings persisted to a configuration file, including dynamically accessed setting keys.
* TurnBasedCoordinator: AutoLoad that coordinates TurnBasedEntity turn order and begin, execute, and end phases.


## Data Scripts

* GlobalName: Registers a node in GameState.globalData using a camelCase version of the node name.
* TileMapLayerWithCellData: TileMapLayer subclass that owns TileMapCellData for runtime per-cell metadata.


## Editor Plugin Scripts

* Comedot: Godot EditorPlugin script for the Comedot dock and editor conveniences. Class name: ComedotPlugin. Not required for runtime use of the framework.
* ComponentsDock: Editor dock that scans Components and helps add Entity and Component scenes.


## Gameplay Scripts

* GameOver: Node script that displays game-over UI and pauses gameplay when GameState.gameDidOver is emitted.
* RandomPlaceholder: InstancePlaceholder subclass that loads or skips a placeholder at runtime based on chance.
* ReplaceWithRandomScene: Node2D script that replaces itself with one randomly selected scene during enter-tree.
* Spawner: Base spawning node that instantiates a configured scene as a child of itself or another parent.


## Payload Scripts

* PlatformerDash: Experimental ScriptPayload target for a basic platformer dash that adds horizontal CharacterBody velocity from recent input.
* RidePayload: ScriptPayload target that lets an InteractionControlComponent rider mount a source RideableComponent vehicle.


## Resources

* Ability: Gameplay Resource representing a selectable action, skill, spell, or command, optionally with Stat costs and target requirements.
* AsteroidsMovementParameters: Movement-parameter Resource for AsteroidsControlComponent.
* CallablePayload: Payload Resource that calls a function or method.
* Collection: Abstract Resource base for reusable item sequences, stacks, cycles, or random collections.
* ColoredTextSequence: TextSequence variant that pairs text entries with colors for dialogue, signboards, or message sequences.
* ComedotProjectSettings: Resource class for development-time Comedot configuration, including startup globals, music, turn-based timing, and debugging behavior.
* ComponentPayload: Payload Resource that creates or removes Components on a receiving Entity.
* ComponentSet: Resource listing Component types for ComponentSwapperComponent and similar runtime component-set switching.
* GameplayResourceBase: Abstract Resource base for gameplay concepts with identity, display name, description, and optional icon.
* GridDictionary: Resource-style coordinate dictionary for grid data keyed by Vector2i-style coordinates.
* GunParameters: Parameter Resource for GunComponent values that are not tied to a specific gun node instance.
* InventoryItem: Gameplay Resource representing an item carried in an InventoryComponent.
* NodePayload: Payload Resource that instantiates a PackedScene and attaches it to a target Node.
* OverheadMovementParameters: Movement-parameter Resource for OverheadPhysicsComponent.
* Payload: Abstract base for deliverable gameplay effects such as signals, callables, scripts, stat changes, or spawned nodes.
* PlatformerJumpParameters: Jump-parameter Resource for JumpComponent and PlatformerPhysicsComponent.
* PlatformerMovementParameters: Movement-parameter Resource for PlatformerPhysicsComponent, JumpComponent, and ClimbComponent.
* ScriptPayload: Payload Resource that calls a function from a specified GDScript file.
* ScrollerMovementParameters: Movement-parameter Resource for ScrollerControlComponent.
* SignalPayload: Payload Resource that emits a Signal defined on GameState.
* Stat: Gameplay Resource representing an integer stat such as health, ammo, XP, attack power, or similar values.
* StatCost: Resource representing a Stat cost for interactions, abilities, purchases, or other gated actions.
* StatDependentResourceBase: Abstract Resource base for gameplay resources that cost a Stat to use or purchase.
* StateMachine: Resource implementing a simple StringName state list with allowed transitions.
* StatModifierPayload: Payload Resource that modifies one or more Stats when executed.
* StatWithModifiers: Experimental Stat variant that keeps a natural value plus stackable positive or negative modifiers.
* TextSequence: Collection Resource for dialogue, tutorial, signboard, or other text sequences.
* TileMapCellData: Runtime cell-data Resource for TileMapLayer cells, such as occupancy or destructible-cell state.
* Upgrade: Gameplay Resource for permanent or repeatable upgrades, unlocks, costs, and upgrade-level effects.


## Scene Scripts

* CollisionsArrayArea: Area2D that tracks contacted Area2Ds in an array. Use AreaContactComponent for Entity-based contact tracking.
* CooldownTimer: Timer subclass for cooldowns with minimum duration, millisecond support, and dedicated cooldown start/finish helpers.
* GameplayResourceBubble: Node2D visual bubble for GameplayResourceBase-derived resources such as Stat changes or loot pickups.
* IOLogoScene: Launch logo scene script for the Invading Octopus logo.
* Lightning: Experimental Node2D lightning flash effect.
* MouseHoverArea: Area2D that shows highlight or hover effects when the mouse enters it.
* PlayerSpawnPosition: Marker2D that moves the configured player Entity to the marker on ready.
* PopulateArea: Experimental Area2D that fills a rectangular area with random copies of a scene.
* RandomSpawnTimer: SpawnTimer variant that has a chance to spawn one scene from a list on each timeout.
* SpawnArea: Area2D that uses a child SpawnTimer to spawn scenes at random positions inside the area.
* SpawnEdge: Positions eight SpawnPoints and four SpawnAreas around the viewport edges, with CanvasLayer support and shared spawn-parent overrides.
* SpawnPoint: Marker2D that uses a child SpawnTimer to spawn scenes at a fixed position.
* SpawnTimer: Timer-based Spawner that creates copies of a specified scene at regular intervals.
* TestMode: Development helper node that toggles selected nodes, debug flags, and test-only changes for a scene.
* TextBubble: Floating text label effect with a static create helper for damage numbers, alerts, and short messages.


## Template Scripts

* AbilityPayloadTemplate: ScriptPayload template for Ability execution scripts.
* CollectiblePayloadTemplate: ScriptPayload template for CollectibleComponent collection scripts.
* ScriptPayloadTemplate: Generic ScriptPayload template.
* ScriptTemplate: Generic Node script template.
* TestModeTemplate: Template for a node visible only during TestMode.
* UpgradePayloadTemplate: ScriptPayload template for Upgrade install/remove scripts.


## Test Scripts

* AreaTest: Manual test scene root for area/collision behavior.
* DestructibleTilesTest: Manual test scene root for destructible tile behavior.
* PopulateTest: Manual test scene root for PopulateArea behavior.
* TestAbilityFallbackReaction: AbilityReactionComponent fallback ScriptPayload test script.
* TestAbilityLook: ScriptPayload test script for the Look ability.
* TestAbilityLookReaction: AbilityReactionComponent ScriptPayload test script for Look reactions.
* TestAbilityZoom: ScriptPayload test script for the Zoom ability.
* TestAmmoUpgradePayload: Upgrade ScriptPayload test script for ammo-related upgrade behavior.
* TestCooldownUpgradePayload: Upgrade ScriptPayload test script for cooldown-related upgrade behavior.
* TestGunUpgradePayload: Upgrade ScriptPayload test script for gun-related upgrade behavior.
* TestSpeedUpgradePayload: Upgrade ScriptPayload test script for speed-related upgrade behavior.
* TileMovementTest: Manual test scene root for tile movement behavior.


## Tool Scripts

* AreaTools: Static helper functions for Area2D-related operations.
* CollisionTools: Static helper functions for CollisionObject2D and CollisionShape2D operations.
* FileSystemTools: Static helper functions for files and folders.
* NodeTools: Static helper functions for Node and Node2D operations.
* RectTools: Static helper functions for Rect2 and Rect2i operations.
* TileMapTools: Static helper functions for TileMap, TileMapLayer, and TileMapCellData operations.
* Tools: Broad static helper collection for built-in Godot nodes and types.


## UI Scripts

* AbilityButton: Experimental Button that displays and triggers one Ability.
* AbilityButtonsList: Experimental Container that creates AbilityButtons for each Ability in an AbilityComponent.
* BusVolumeUI: Control for stepping an audio bus volume up or down.
* CameraFollowingLabel: TextCyclingLabel that follows the camera temporarily, then sticks to a fixed position and deletes itself offscreen.
* Chart: Node2D chart for plotting a variable over time, commonly used through Debug chart-window helpers.
* CustomLogEntryUI: Experimental Control view for one custom log entry and its emitting object details.
* GameplayResourceUI: Abstract Container base for UI controls representing GameplayResourceBase resources.
* InputActionEventUI: Container UI for one InputEvent binding on an input action, including remove controls.
* InputActionsList: Container that creates InputActionUI rows for viewing or remapping input actions.
* InputActionUI: Container UI for one input action and all of its InputEvent bindings.
* InventoryItemUI: GameplayResourceUI subclass for displaying an InventoryItem.
* InventoryList: Container that builds InventoryItemUI entries from an InventoryComponent.
* LongPressButton: Button that emits longPressed only after being held for a configured duration.
* MainMenuButtons: Main menu button template/example script.
* ManualStatsList: Legacy/manual HUD Container that updates named Label children from GameState.statUpdated.
* ModalUI: Node that displays a Control, pauses gameplay, calls a configured function, and can resume afterward.
* OptionsUi: Options menu container for main-menu or pause-screen settings.
* PauseButton: Button that toggles pause/unpause while remaining interactive during pause.
* PauseOverlay: Pause-screen quick settings Control.
* PrintPropertiesToLabels: Container that mirrors named object properties into Label children with matching names.
* ResourceListBase: Abstract Container base for lists of GameplayResourceBase UI entries.
* ScrollWithJoystick: ScrollContainer helper for right-joystick scrolling while left joystick moves UI focus.
* SetInitialFocus: Control helper that gives a Button or Control initial focus for gamepad/keyboard navigation.
* StatBar: StatUI variant backed by a ProgressBar.
* StatPips: StatUI variant that displays small-range Stat values as repeated pips or symbols.
* StatsList: Container that builds StatUI entries for all Stats in a StatsComponent.
* StatUI: Container linked to one Stat and automatically updated when the Stat changes.
* TemporaryLabelList: Container that creates temporary fading-label entries for logs, alerts, or chat-like messages.
* TextCyclingLabel: Label that cycles through multiple text strings on a Timer.
* TimerProgressBar: ProgressBar that displays a Timer's remaining time.
* TreeSearchBox: LineEdit that filters a Tree after a short Timer delay.
* UINavigationButton: Button that asks a parent UINavigationContainer to display a different UI page.
* UINavigationContainer: Container that swaps its first Control child in response to navigation buttons or events.
* UpgradeChoicesList: Container that builds UpgradeChoiceUI entries from a list of Upgrade choices.
* UpgradeChoiceUI: Control representing one Upgrade choice or upgrade-level option.
* UpgradeUI: GameplayResourceUI subclass that displays an Upgrade and updates when it changes.


## Visual Scripts

* Animations: Static or shared code-defined animations that can be applied to nodes.
* CameraMouseTracking: Camera2D script that offsets camera position based on mouse movement.
* CameraZoomBounce: Camera2D zoom bounce effect.
* ClampCameraToArea: Camera2D script that confines the camera inside a rectangular Area2D.
* CopyShapeFromCollisionPolygon: Polygon2D script that copies its polygon from a CollisionPolygon2D.
* CopyShapeFromPolygon: CollisionPolygon2D script that copies another polygon's shape.
* CreateFlippedCopy: Node2D script that creates horizontal and/or vertical flipped copies of a node.
* CreateSpriteFramesFromSheet: AnimatedSprite2D editor helper that builds SpriteFrames animations from a sprite sheet.
* CycleColor: CanvasItem script that cycles HSV color channels over time, including Light2D color support.
* DeleteParentWhenOffscreen: VisibleOnScreenNotifier2D script that queues the parent for deletion when offscreen.
* FakeParallax: Experimental CanvasItem script that simulates simple horizontal parallax against another node.
* Flicker: Experimental CanvasItem flicker effect.
* HideInEditor: CanvasItem script that hides a node only in the Godot editor.
* MatchNodePosition: Experimental Node2D script that follows another node on one or both axes.
* MatchSpriteFlip: Node2D script that mirrors its scale to match Sprite2D or AnimatedSprite2D flip state.
* MoveRandomly: Node2D script that jitters a node randomly each frame, useful for testing visual/physics behavior.
* RandomizeTileMapCells: TileMapLayer script that randomizes or erases cells in a configured atlas-coordinate range.
* RandomModulate: CanvasItem script that assigns a random modulate color.
* RandomSpriteFrame: Node2D script that chooses a random Sprite2D or AnimatedSprite2D frame.
* SnapToMouse: Node2D script that snaps the node's global position to the mouse pointer.
* Spin: Node2D script that rotates the node every frame.


Generated by AI (Codex) on 2026-07-10
