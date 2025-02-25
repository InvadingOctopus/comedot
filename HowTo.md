# Comedot - How To Do Shit

* 🏠 [Organize Your Project](#-organize-your-project)
* 👀 [See Usage Examples](#-see-usage-examples)
* 👤 [Make a Player Entity](#-make-a-player-entity)
* 🕹️ [Add Player Control and Movement](#%EF%B8%8F-add-player-control)
* 🧩 [Add Components to Entities](#-add-components-to-entities)
* ⚔️ [Mortal Comebat](#%EF%B8%8F-add-combat)
* ⚡️ [Add New Functionality](#%EF%B8%8F-add-game-specific-functionality)
* 🧩 [Create New Components](#-create-new-components)
* 🎲 [Make a Turn-Based Game](#-make-a-turn-based-game)
* 🔧 [Fix Common Problems](#-fix-common-problems)


# 🏠 Organize Your Project

Create a separate copy of the entire Comedot project folder for each of your games and modify anything in any way, _or_

1. Create a new git branch for your game (say `game-of-the-year-2069`) in your local Comedot repository, and

2. Make subfolders for your game in the existing folder structure like `/Scenes/YourGame/` or `/YourGame/etc/` to organize your own files separately from the framework and avoid accidental conflicts.

💡 _You could also use a single `/Comedot/Game/` subfolder for multiple game projects: Create a new git repository in the `/Game/` subfolder, and use multiple git branches for each game. This may help with experimenting on different ideas while keeping the Comedot framework separate, so that any updates or modifications to the framework can be easily shared between all your games._

❗️ Your main game scene must have the `/Scripts/Start.gd` script attached to the root node (or any other node as long as it runs before other scripts, just to be safe) so it can initialize the Comedot framework environment and apply global flags etc.


# 👀 See Usage Examples

* The quickest way to learn/teach something is usually by example, so take a look in `/Templates/Examples/` and `/Templates/Scenes/` for very basic gameplay that you can duplicate and modify.

* Scenes in  `/Tests/` are used in the development process of various components and subsystems such as `/Tests/Upgrades/UpgradeTest.tscn` and `/Tests/TurnBased/TurnBasedTest.tscn` that you can examine to see how those features work.


# 👤 Make a Player Entity

1. Create a `CharacterBody2D` Node.

2. Attach the `/Entities/Characters/PlayerEntity.gd` Script.

3. Add other necessary nodes like `Sprite2D` or `AnimatedSprite2D`, `CollisionShape2D`, `Camera2D` and set them up.

4. Set the Body's Physics Collision Layer to `players` and the Mask to `terrain`. Add other categories as needed.

💡 _Try one of the templates in `/Templates/Entities/`_


### 🕹️ Add Player Control

1. Select the Player Entity Node in the Godot Scene Editor.

2. Add components from `/Components/Control/` and `/Components/Physics/` as children of the Entity node.

	🍄 For platformer "run and jump" movement: `PlatformerControlComponent` + `JumpControlComponent` + `PlatformerPhysicsComponent`

	🛸 For "overhead" RPG or flying movement:  `OverheadControlComponent` + `OverheadPhysicsComponent`

3. Add `/Components/Physics/CharacterBodyComponent.tscn` as the _last_ component in the Entity's tree. This component takes the velocity updates from other components and applies them to the Entity's `CharacterBody2D`.


# 🧩 Add Components to Entities

_Most components require their Scene file, not just the Script, because they may add graphics or depend on internal nodes such as Timer and signals etc._

* Use **"Instantiate Child Scene"** (SHIFT+Control/Command+A)

	❌ Do **NOT** use "Add Child Node" (Control/Command+A): This will not include the component's child nodes or other properties.

* Drag the `.tscn` Scene file of a Component from the FileSystem Dock to add it as a child node of an Entity.

	❌ Do **NOT** drag a Component's `.gd` Script file to an Entity node; entities should only have a Script which `extends Entity` or `TurnBasedEntity`

📖 _Read the documentation comments in the script of each component to see how to use it._


# ⚔️ Add Combat

1. Add a `FactionComponent` and set the Faction to either `players` or `enemies`

2. Add a `HealthComponent` + `DamageReceivingComponent`

* For monsters, add a `DamageComponent` to hurt the player on contact.

❕ _Remember to set the correct Physics Collision Layers and Masks for all bodies/areas, otherwise they won't be able to detect collisions with each other._

💡 _You may also add `HealthVisualComponent` + `InvulnerabilityOnHitComponent` etc._


# ⚡️ Add Game-specific Functionality

When you need more game-specific functionality, you have the following options, in order of ease → power:

* Select a component in your Scene Tree and enable **"Editable Children"** to modify its internal sub-nodes, such as a `GunComponent`'s pivot point, or collision shapes and timers. Those modifications will only apply to *that one specific instance.*

* Create a new scene which inherits an existing component's scene, then add new child nodes to it, such as additional graphics for a `GunComponent`.

* Make a subclass of a component's script, e.g. `extends DamageComponent` and add your own features on top of the existing functionality. Override any `func` and call `super.funcName()` to run the original code before or after your code.

* Modify the original scene/script of a component to permanently modify or replace the default functionality. Those modifications will affect *all instances* of that component.

* Create your own entirely new components, by creating a new scene and attaching the `Component.gd` script to the root node.


### 🧩 Create New Components

📜 Components are the core of the Comedot flow. Whenever you need a new kind of *behavior* in your game — e.g. the player needs to climb a wall, or a monster needs a specific movement pattern, or a bullet needs to explode into multiple smaller bullets, or you simply want to attach graphics like a health bar on all characters — you can add that as a new Component:

1. Create a new Scene in the appropriate category subfolder in `/Components/` or create a new subfolder. If your component needs to display visuals, the **"Root Type"** must be "2D Scene" which is a `Node2D`. If your component only has logic code, the **"Root Type"** should be `Node`.

2. Select the root node of your component scene and add it to the `components` group. This makes it easier to manage multiple components. If the Scene is a `Node2D` then also enable **"Group Selected Nodes"** in the Scene Editor Toolbar. This makes it easier to move your component along with its children in the Entity's scene.

3. Right-click the root node » **"Attach Script"**. Type `Component` in **"Inherits"** and choose one of the base components in **"Template"**.

💡 _If you don't like having many small components, you can just create one "monolithic" super-component like a "PlayerComponent" or "MonsterComponent" and put everything specific to your gameplay in that one component. You could also forego components and do things the old Godot way for certain entities: just dump everything in a big "MyPlayerEntity.gd" script which `extends Entity`_


# 🎲 Make a Turn-Based Game

1. Go to Project Settings » Globals. Make sure the `TurnBasedCoordinator` Autoload is enabled.

2. In your scene, add a `TurnBasedEntity`

3. Create new components which `extend TurnBasedComponent`

4. Connect player input or a UI control such as a "Next Turn" button to the `TurnBasedCoordinator.startTurnProcess()` function.

5. Each turn, all turn-based objects cycle through the following states/phases: `processTurnBegin()` → `processTurnUpdate()` → `processTurnEnd()`

	Your turn-based components must implement one or more of those methods and may connect to each other's signals to build your gameplay.


# 🔧 Fix Common Problems

* ⚠️ The first time you load a copy of this project, there may be errors because Godot will re-import various files and set the internal IDs for assets, textures etc. To fix: Close and reopen the project.

* 🪲 The `debugMode` property on Components and many Scripts is your friend! It will print extra debug information in the logs and/or enable extra visual cues.

* 📜 Use the logging methods in the `Debug.gd` AutoLoad to help you track down nasty bugs! `Debug.printTrace()`, `Debug.printHighlight()` etc.

* 📈 Use `DebugComponent`, `ChartWindow`, `Chart` to monitor a real-time graph of any variable or property! e.g. `../CharacterBodyComponent:body:velocity:x` to help with perfecting physics parameters etc.

* The icons/emojis used in the log messages require Apple's SF Symbols which may not work on Windows or Linux: https://developer.apple.com/sf-symbols/

#### Common Reasons for Crashes

* Missing component dependencies: Also check the ORDER of components in an entity's node tree.

* Incorrect component parameters: Check all fields in the Godot Editor Inspector and make sure all values are correct.

* I forgor: Check the latest "develop" branch or wait or fix it yourself. 🥲


----

💬 For more questions, summon @Syntaks.io on Discord on a night of a full moon.
