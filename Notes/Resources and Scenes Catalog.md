# Resources and Scenes Catalog

An index of reusable Godot `.tscn` and `.tres` files where the scene or resource composition is the main reusable object. Excludes `/Game/`, `/Temporary/`, `/Lab/`, imported media assets under `/Assets/`, and the Entity/Component scene/script pairs already covered by their own catalogs.


## AutoLoad Scenes

* Debug: AutoLoad scene for debug UI, log panels, charts, watched values, and the debug background overlay.
* GlobalSonic: AutoLoad scene for persistent music, sound effect, and generated beep players.
* GlobalUI: AutoLoad scene for global overlays, transitions, pause visuals, temporary labels, and UI navigation that should sit above gameplay scenes.
* TurnBasedCoordinator: AutoLoad scene for turn order coordination and turn-state support nodes.


## Editor Plugin Scenes and Resources

* ComponentsDock: Editor dock scene for browsing, filtering, and adding Comedot Components and Entities inside the Godot editor.
* NewComponentInFolderShortcut: Editor shortcut resource for creating a new Component in the selected folder.


## Resources

* BackShortcut: Shortcut resource binding the framework back action to both `back` and `ui_cancel`.
* ComedotProjectSettings: Default framework settings resource for the main scene, GlobalData resource, GameState child scenes, music, turn-based timing, and debugging behavior.
* DefaultAudioBusLayout: Audio bus layout resource defining the shared SFX and Music buses.
* GlobalData: Default shared key-value Resource loaded into GameState through ComedotProjectSettings; starts empty and can be replaced with a game-specific GlobalData resource.
* PlatformerDash: Ability resource for a short platformer dash backed by a ScriptPayload.
* TurnState: StateMachine resource defining the turnReady, turnBegin, turnExecute, and turnEnd flow.


## Scenes/Areas

* PopulateArea: Area2D scene that fills its rectangular region with random copies of a configured scene.
* SpawnArea: Area2D spawn volume with a direct Spawner child that places spawned scenes at random positions inside the area.


## Scenes/Debug

* DebugBackground: Debug background scene with a checkerboard TileMapLayer and simple animated visual helpers for test scenes.
* TestMode: Scene wrapper for toggling test-only nodes, debug flags, and scene-specific development changes.


## Scenes/Decorations

* GameplayResourceBubble: Floating Node2D bubble scene for displaying GameplayResourceBase-derived changes such as Stat changes, loot, or rewards.
* Lightning: Experimental Node2D lightning flash decoration scene.
* TextBubble: Floating text label scene for damage numbers, alerts, and other short temporary messages.


## Scenes/Gameplay

* CooldownTimer: Timer scene configured for cooldown behavior and reusable cooldown state.
* OnScreenTrigger: VisibleOnScreenNotifier2D scene that emits an immediate or delayed trigger on viewport entry, can cancel a pending delay on exit, and supports use limits and final-trigger deletion.
* PlayerSpawnPosition: Marker2D scene that moves the current player Entity to the marker position on ready and can add a CameraComponent when the player has no camera.
* SpawnEdge: CanvasLayer scene with eight edge and corner SpawnPoints plus four offscreen SpawnAreas, coordinating their direct Spawner children around the current viewport with shared spawn-parent overrides.
* SpawnLocationTrigger: OnScreenTrigger scene for map-positioned spawn or wave activation that can align newly spawned nodes with the trigger on selected canvas-space axes.
* SpawnPoint: Marker2D spawn scene with a direct Spawner child that places spawned scenes at a fixed position.
* SpawnTimer: Autostarting Timer scene with the Spawner script attached directly to its root and its timeout signal connected for periodic spawn requests.
* SpawnWaveTrigger: SpawnLocationTrigger scene with an internal SpawnerStack and Timer for launching interval-spaced waves, with optional immediate first spawn and placeholder-based placement.


## Scenes/Launch

* GameFrame: Main launch frame scene with a debug background, mouse-tracking Camera, global UI wiring, and the default main menu.
* IOLogoInvaderSprite: RigidBody2D logo-piece scene used by the Invading Octopus logo animation.
* IOLogoOctopusSprite: RigidBody2D logo-piece scene used by the Invading Octopus logo animation.
* IOLogoScene: Invading Octopus logo animation scene composed from logo-piece sprites.


## Templates

* HUDTemplate: CanvasLayer HUD template with common stat labels and quick prototype UI structure.
* RectangleAreaTemplate: Minimal Area2D rectangle collision template.
* TestSprite16: Simple 16x16 Sprite2D placeholder scene for tests and prototypes.
* TileSetTemplate: Small TileSet resource with physics and `isWalkable`/`isBlocked` custom data for tile-based prototypes.


## Templates/Examples

* ComponentSwappingExampleScene: Example scene demonstrating runtime swapping between walking and flying component sets.
* ControlSwapperExampleComponent: Example-only component scene used by ComponentSwappingExampleScene to switch component sets.
* FlyingComponentSetExample: ComponentSet resource containing OverheadPhysicsComponent for flying-style movement.
* GhostExampleEntity: Example enemy Entity composition with health, chase, overhead physics, and damage behavior.
* TreesWithGunsExampleScene: Example scene showing a player, armed trees, aiming cursors, guns, and a ghost target.
* TreeWithGunExampleEntity: Example armed tree Entity composition with faction, gun, facing, and input components.
* WalkingComponentSetExample: ComponentSet resource containing JumpComponent and PlatformerPhysicsComponent for walking/platformer movement.


## Templates/Scenes

* OverheadSceneTemplate: Starter overhead gameplay scene with HUD and an overhead combat player template.
* PlatformerSceneTemplate: Starter platformer gameplay scene with HUD, a monster template, and a platformer player template.


## Tests

* AreaTest: Manual test scene for Area2D contact tracking, collision behavior, and mouse-tracked area movement.
* ClimbTest: Manual platformer climbing test scene with ladders, tile data, and climb/jump/physics components.
* InteractionTest: Manual interaction test scene covering interaction targets, costs, collectibles, text interaction, and stat feedback.
* ModalUITest: Manual test scene for ModalUI display, pause behavior, and modal dismissal flow.
* PathfindingTest: Manual test scene for NavigationComponent pathfinding around obstacles.
* PopulateTest: Manual test scene for PopulateArea random scene placement.
* TileMovementTest: Manual test scene for tile-based position, movement, linear motion, and collision behavior.
* WaveMovementTest: Manual test scene for WaveMotionComponent and ShapeDrawComponent behavior.


## Tests/Abilities

* AbilityTest: Manual ability-system test scene for ability buttons, costs, targeting, and target reactions.
* TestAbilityLook: Test Ability resource for a Look command backed by a ScriptPayload.
* TestAbilityZoom: Test Ability resource for a Zoom command with cooldown and mana cost.


## Tests/Combat

* CombatTest: Manual combat test scene covering damage, factions, health, projectiles, hazards, and repeat damage.
* DestructibleTilesTest: Manual tile-damage test scene for destructible TileMapLayer cells.
* PoisonArrowTestEntity: Test projectile Entity scene that injects damage-over-time behavior on impact.
* TileDamageBullet: Test bullet Entity scene configured to damage tile cells.


## Tests/Inventory

* InventoryTest: Manual inventory test scene for collecting InventoryItems and showing InventoryList UI.
* TestBlueKey: Test InventoryItem resource for a blue key.
* TestRedKey: Test InventoryItem resource for a red key.
* TestYellowKey: Test InventoryItem resource for a yellow key.


## Tests/Stats

* TestAmmo: Test Stat resource for ammo with a large initial value.
* TestGold: Test Stat resource for gold with a large initial value.
* TestMana: Test Stat resource for mana with a large initial value.


## Tests/TurnBased

* TurnBasedTest: Manual turn-based test scene for TurnBasedCoordinator, turn-based entities, tile movement, and turn UI.
* TurnBasedTestComponent: Test-only TurnBasedComponent scene with simple visuals for validating turn phases.


## Tests/Upgrades

* TestAmmoUpgrade: Test Upgrade resource for ammo-related upgrade behavior.
* TestCooldownUpgrade: Test Upgrade resource for cooldown reduction behavior.
* TestGunUpgrade: Test Upgrade resource for unlocking or improving gun behavior.
* TestSpeedUpgrade: Test Upgrade resource for speed upgrade behavior.
* UpgradeTest: Manual upgrade-system test scene for upgrade choices, costs, stats, and player-facing upgrade UI.


## UI

* Chart: Node2D chart scene for plotting debug or runtime values over time.
* ChartWindow: Window scene that wraps a Chart for floating debug graph display.
* CustomLogEntryUI: Panel scene for showing details about one custom debug log entry.
* InputActionEventUI: HBoxContainer scene for one input event binding row with remove controls.
* InputActionUI: GridContainer scene for one input action and its editable bindings.
* InputMapUI: Input remapping screen scene that lists input actions and supports joystick scrolling.
* ModalUI: Generic modal Control scene that can pause gameplay and display arbitrary modal content.
* PauseOverlay: Pause-screen overlay scene with pause controls and quick settings.
* TreeSearchBox: LineEdit scene that filters a Tree after a short delay.


## UI/Buttons

* AbilityButton: Button scene for displaying and triggering one Ability.
* LongPressButton: Button scene that emits a long-press signal only after being held long enough.
* PauseButton: Button scene for toggling pause and unpause while still processing during pause.


## UI/Labels

* BlinkingLabel: Label scene with blinking animation for temporary emphasis.
* CameraFollowingLabel: CanvasLayer label scene that follows the player Entity's primary camera temporarily and removes itself offscreen.
* FadingLabel: Label scene with fade animation for temporary text.
* TextCyclingLabel: Label scene that cycles through a sequence of text entries on a Timer.


## UI/Menus

* MainMenuButtons: Main menu button stack scene with navigation and initial focus behavior.
* OptionsUI: Options menu scene for audio/settings controls and back navigation.


## UI/Views

* BusVolumeUI: GridContainer scene for stepping an audio bus volume down or up.
* GameplayResourceUI: Base UI view scene for showing a GameplayResourceBase icon/name/value layout.
* InventoryItemUI: GameplayResourceUI-derived scene for displaying an InventoryItem.
* StatBar: StatUI-derived scene that displays a Stat with a ProgressBar.
* StatPips: StatUI-derived scene that displays small-range Stat values as repeated pips or symbols.
* StatUI: GridContainer scene for displaying one Stat and updating when the Stat changes.
* UpgradeChoiceUI: HBoxContainer scene for one selectable Upgrade choice or upgrade-level option.
* UpgradeUI: GameplayResourceUI-derived scene for displaying an Upgrade.


Total listed: 99  
Generated by AI (Codex) on 2026-08-08
