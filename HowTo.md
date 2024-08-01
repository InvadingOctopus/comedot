# Comedot - How To Do Basic Stuff

* 🏠 [Setup Your Main Game Scene](#your-main-game-scene)
* 👤 [Make a Player Entity](#make-a-player-entity)
* 🕹️ [Add Player Control](#add-player-control-and-movement)
* ⚔️ [Mortal Comebat](#add-combat)
* 🧩 [Create New Components](#create-new-components)
* ♟️ [Make a Turn-Based Game](#make-a-turn-based-game)

## Your Main Game Scene

❗️ Must have the `/Scripts/Start.gd` script attached to the root node (or any other node as long as it runs before other scripts, just to be safe) so it can initialize the Comedot framework environment and flags etc.

## Make a Player Entity

1. Create a `CharacterBody2D` node.

2. Attach the `/Entities/Characters/PlayerEntity.gd` script.

3. Add other necessary nodes like `Sprite2D` or `AnimatedSprite2D`, `CollisionShape2D`, `Camera2D` and set them up.

4. Set the Body's Physics Collision Layer to `players` and the Mask to `terrain`. Add other categories as needed.

* 💡 Try one of the templates in `/Templates/Entity/`

### Add Player Control and Movement

1. Select the Player Entity.

2. Choose `Instantiate Child Scene` from the context menu.

3. Add components from `/Components/Control/` as children of the Entity node, such as `OverheadControlComponent.tscn`.

4. Add `/Components/Physics/CharacterBodyComponent.tscn` as the last component in the Entity's tree. This component takes the velocity updates from other components and applies them to the `CharacterBody2D`.

* 📖 Read the documentation comments in the scripts of each component to see how to use it.

* ❕ If you use the `PlatformerPhysicsComponent` then you must also add the `PlatformerControlComponent` and `JumpControlComponent`.

## Add Combat

1. Add a `FactionComponent` and set the Faction to either `players` or `enemies`

2. Add a `HealthComponent`

3. Add a `DamageReceivingComponent`

* For monsters, add a `DamageComponent` to hurt the player on contact.

* ❕ Remember to set the correct Physics Collision Layers and Masks for all bodies, otherwise they will not be able to detect collisions with each other.

* 💡 For the player, you may also add an `InvulnerabilityOnHitComponent`.

## Create New Components

❕ Components are the core of the Comedot flow. Whenever you need a new kind of *behavior* in your game — e.g. the player needs to climb a wall or do a dash, a monster needs a specific movement pattern, or a bullet needs to explode into multiple smaller bullets — you must make a new Component:

1. Create a new Scene in the appropriate category subfolder in `/Components/` or create a new subfolder. If your component needs to display visuals, the **Root Type** must be "2D Scene" which is a `Node2D`. If your component only has logic code, the **Root Type** should be `Node`.

2. Select the root node of your component scene and add it to the `components` group. This makes it easier to manage multiple components. If the Scene is a `Node2D` then also enable `Group Selected Nodes` in the Scene Editor Toolbar. This makes it easier to move your component along with its children in the Entity's scene.

3. Right-click the root node » Attach Script. Type `Component` in **Inherits** and choose one of the base components in **Template**.

## Make a Turn-Based Game

1. Go to Project Settings » Globals. Make sure the `TurnBasedCoordinator` Autoload is enabled.

2. In your scene, add a `TurnBasedEntity`.

3. Create new components which extend `TurnBasedComponents`.

4. Connect player input or a UI control such as a "Next Turn" button to the `TurnBasedCoordinator.startTurnProcess()` function.

5. Each turn, all turn-based objects cycle through the following functions: `processTurnBegin()` → `processTurnUpdate()` → `processTurnEnd()`

	Your turn-based components must implement one or more of those methods and may connect to each other's signals to build your gameplay.

----

💬 For more questions, @Syntaks.io on Discord