# Comedot - How To Do Basic Stuff

## Your Main Game Scene

* Must have the `/Scripts/Start.gd` script attached to the root node (or any other node as long as it runs before other scripts, just to be safe) so it can initialize the Comedot framework environment and flags etc.

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

----

💬 For more questions, @Syntaks.io on Discord