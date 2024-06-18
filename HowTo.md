# Comedot - How To Do Basic Stuff

## Your Main Game Scene

* Must have the `/Scripts/Start.gd` script attached to the root node (or any other node as long as it runs before other scripts, just to be safe) so it can initialize the Comedot framework environment and flags etc.

## Make a Player Entity

1. Create a `CharacterBody2D` node.
2. Attach the `/Entities/Characters/PlayerEntity.gd` script.
3. Add other necessary nodes like `Sprite2D` or `AnimatedSprite2D`, `CollisionShape2D`, `Camera2D` etc and set them up.
4. Remember to set the Physics Collision Layer to `players` and set the Mask to `terrain` at least.

### Add Player Control and Movement

1. Instantiate Child Scene

2. Add one of the components from `/Components/Control/` as children of the Entity node, like `OverheadControlComponent`

* Read the documentation in the script for each component to see how to use them.

* ❕ If you add the `PlatformerControlComponent` then you must also add the `JumpControlComponent` and `/Components/Physics/GravityComponent`

## Add Combat

1. Add a `FactionComponent` and set the Faction to either `players` or `enemies`

2. Add a `HealthComponent`

3. Add a `DamageReceivingComponent`

* For monsters, add a `DamageComponent` to hurt the player on contact.

* 💡 For the player, you may also add an `InvulnerabilityOnHitComponent`.

* ❕ Remember to set the correct Physics Collision Layers and Masks for everything, otherwise they will not register collisions with each other.

----

💬 For more questions, @Syntaks.io on Discord