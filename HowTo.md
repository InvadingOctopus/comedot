# Comedot - How To Do Shit

* 🏠 [Organize Your Project](#-organize-your-project)
* 👤 [Make a Player Entity](#-make-a-player-entity)
* 🕹️ [Add Player Control](#%EF%B8%8F-add-player-control-and-movement)
* ⚔️ [Mortal Comebat](#%EF%B8%8F-add-combat)
* ⚡️ [Add New Functionality](#-add-new-functionality)
* 🧩 [Create New Components](#-create-new-components)
* 🎲 [Make a Turn-Based Game](#-make-a-turn-based-game)
* ❗️ [Fix Common Problems](#-fix-common-problems)


## 🏠 Organize Your Project

1. Create a new git branch for your game (say `game-of-the-year-2069`) in your local repository, and

2. Make subfolders for your game in the existing folder structure like `/Scenes/YourGame/` or `/YourGame/etc/` to organize your own files separately from the framework and avoid accidental conflicts.

* 💡 You could also use a single `/Comedot/Game/` subfolder for multiple game projects: Create a new git repository in the `/Game/` subfolder, and use multiple git branches for each game. This may help experiment with different ideas while keeping the Comedot framework separate, so that any updates or modifications to the framework may be used for all your games.

❗️ Your main game scene must have the `/Scripts/Start.gd` script attached to the root node (or any other node as long as it runs before other scripts, just to be safe) so it can initialize the Comedot framework environment and apply global flags etc.


## 👤 Make a Player Entity

1. Create a `CharacterBody2D` node.

2. Attach the `/Entities/Characters/PlayerEntity.gd` script.

3. Add other necessary nodes like `Sprite2D` or `AnimatedSprite2D`, `CollisionShape2D`, `Camera2D` and set them up.

4. Set the Body's Physics Collision Layer to `players` and the Mask to `terrain`. Add other categories as needed.

* 💡 Try one of the templates in `/Templates/Entities/`


### 🕹️ Add Player Control and Movement

1. Select the Player Entity.

2. Choose `Instantiate Child Scene` from the context menu.

3. Add components from `/Components/Control/` as children of the Entity node, such as `OverheadControlComponent.tscn`.

4. Add `/Components/Physics/CharacterBodyComponent.tscn` as the last component in the Entity's tree. This component takes the velocity updates from other components and applies them to the `CharacterBody2D`.

* 📖 Read the documentation comments in the scripts of each component to see how to use it.

* ❕ If you use the `PlatformerPhysicsComponent` then you must also add the `PlatformerControlComponent` and `JumpControlComponent`.


## ⚔️ Add Combat

1. Add a `FactionComponent` and set the Faction to either `players` or `enemies`

2. Add a `HealthComponent`

3. Add a `DamageReceivingComponent`

* For monsters, add a `DamageComponent` to hurt the player on contact.

* ❕ Remember to set the correct Physics Collision Layers and Masks for all bodies, otherwise they will not be able to detect collisions with each other.

* 💡 For the player, you may also add an `InvulnerabilityOnHitComponent`.


## ⚡️ Add New Functionality

When you need more game-specific functionality, you have the following options, in order of ease → power:

* Select a component in your Scene Tree and enable "Editable Children" to modify its internal sub-nodes, such as a `GunComponent`'s pivot point, or collision shapes and timers. Those modifications will only apply to *that one specific instance.*

* Create a new scene which inherits an existing component's scene, then add new child nodes to it, such as additional graphics for a `GunComponent`.

* Make a subclass of a component's script, e.g. `extends DamageComponent` and add your own features on top of the existing functionality. Override any `func` and call `super.funcName()` to run the original code before or after your code.

* Modify the original scene/script of a component to permanently modify or replace the default functionality. Those modifications will affect *all instances* of that component.

* Create your own entirely new components, by creating a new scene and attaching the `Component.gd` script to the root node.


### 🧩 Create New Components

❕ Components are the core of the Comedot flow. Whenever you need a new kind of *behavior* in your game — e.g. the player needs to climb a wall, or a monster needs a specific movement pattern, or a bullet needs to explode into multiple smaller bullets, or you simply want to attach graphics like a health bar on all characters — you can add that as a new Component:

1. Create a new Scene in the appropriate category subfolder in `/Components/` or create a new subfolder. If your component needs to display visuals, the **Root Type** must be "2D Scene" which is a `Node2D`. If your component only has logic code, the **Root Type** should be `Node`.

2. Select the root node of your component scene and add it to the `components` group. This makes it easier to manage multiple components. If the Scene is a `Node2D` then also enable `Group Selected Nodes` in the Scene Editor Toolbar. This makes it easier to move your component along with its children in the Entity's scene.

3. Right-click the root node » Attach Script. Type `Component` in **Inherits** and choose one of the base components in **Template**.


## 🎲 Make a Turn-Based Game

1. Go to Project Settings » Globals. Make sure the `TurnBasedCoordinator` Autoload is enabled.

2. In your scene, add a `TurnBasedEntity`.

3. Create new components which extend `TurnBasedComponents`.

4. Connect player input or a UI control such as a "Next Turn" button to the `TurnBasedCoordinator.startTurnProcess()` function.

5. Each turn, all turn-based objects cycle through the following functions: `processTurnBegin()` → `processTurnUpdate()` → `processTurnEnd()`

	Your turn-based components must implement one or more of those methods and may connect to each other's signals to build your gameplay.


## ❗️ Fix Common Problems

* ⚠️ The first time you load a copy of this project, there may be errors because Godot will re-import various files and set the internal IDs for assets, textures etc. To fix: Close and reopen the project.

* The icons/emojis used in the log messages require Apple's SF Symbols which may not work on Windows or Linux: https://developer.apple.com/sf-symbols/

#### Common Reasons for Crashes

* Missing component dependencies: Also check the ORDER of components in an entity's node tree.

* Incorrect component parameters: Check all fields in the Godot Editor Inspector and make sure all values are correct.

* I forgor: Check the latest "develop" branch or wait or fix it yourself. 🥲


----

💬 For more questions, summon @Syntaks.io on Discord on a night of a full moon.
