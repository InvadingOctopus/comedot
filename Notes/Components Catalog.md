# Components Catalog

An index of reusable Components in Comedot's shared library, to help humans and AI agents quickly choose components for a task. Detailed documentation is inside each component's `.gd` script. Omits temporary/test/example components.


## AI

* TimerAgentComponentBase: Experimental base for simple AI agent components driven by a Timer, such as random attack checks.


## Combat

* BulletlessGunComponent: Cooldown-based weapon that applies instant damage at a target position instead of spawning projectiles. Use with DamageComponent and aiming components for towers or hitscan-style attacks.
* BulletModifierComponent: Modifies projectile Entities emitted by GunComponent, such as changing damage or adding extra visual/effect components. Must run after GunComponent.
* DamageComponent: Area2D hitbox component that damages DamageReceivingComponent hurtboxes, with optional faction filtering and hit chance.
* DamageOverTimeComponent: Adds timed repeated damage to the entity's DamageReceivingComponent without requiring ongoing collision contact. Useful for poison, burn, and similar lingering effects.
* DamageRayComponent: DamageComponent variant that uses RayCast2D so a projectile or attack reports only the first physics contact in a frame.
* DamageReceivingComponent: Area2D hurtbox component that accepts DamageComponent hits and forwards damage to HealthComponent, with optional faction filtering.
* DamageRepeatingComponent: Timer-based DamageComponent variant for hazards or turrets that repeatedly damage all opposing receivers that remain in contact.
* FactionComponent: Assigns one or more gameplay factions to an Entity for combat filtering and possible NPC or AI relationship checks.
* GunComponent: Cooldown-based projectile weapon component with editable gun sprite, pivot, and bullet emission point. Processes unhandled input so UI can intercept firing.
* HealthComponent: Stores health, handles health changes, and manages destruction-related behavior. Use DamageReceivingComponent for combat damage intake.
* InvulnerabilityOnHitComponent: Grants temporary damage immunity after DamageReceivingComponent takes damage. Useful for lives-based combat or post-hit invulnerability windows.
* KnockbackOnHitComponent: Pushes a CharacterBody2D when DamageReceivingComponent takes damage. Place after friction-heavy movement components when knockback must win.
* ShieldedHealthComponent: HealthComponent subclass where a shield or armor Stat absorbs damage before health is reduced.
* TileDamageComponent: Experimental TileCollisionComponent subclass that damages destructible TileMapLayer cells by changing or erasing tiles based on TileSet custom data.


## Control (Player/AI Input)

* AbilityControlComponent: Converts input actions into AbilityComponent.performAbility() calls and creates an AbilityTargetingComponentBase subclass when an Ability needs a target. Requires AbilityComponent.
* AbilityTargetingComponentBase: Abstract base for components that prompt a player or other Entity to choose a target for an Ability.
* AbilityTargetingCursorComponentBase: Abstract base for target-picking components that show a cursor or targeting UI. Targets are usually Entities with AbilityTargetableComponent.
* AbilityTargetingMouseComponent: Mouse-controlled Ability targeting cursor for choosing a world position or AbilityTargetableComponent target.
* AbilityTargetingPositionComponent: Joystick or mouse controlled Ability targeting cursor. Use when target selection should work with gamepad-style position control.
* AimingCursorComponent: Reticle component for aiming GunComponent or similar tools with right-stick or mouse control. Combines cursor movement, facing, tethering, and hide-when-stationary behavior.
* AsteroidsControlComponent: Unified spaceship or tank-style control component for turning, thrusting, and braking a CharacterBody2D. Use instead of combining TurningControlComponent and ThrustControlComponent.
* BasicOverheadControlComponent: Directly moves a CanvasItem or Node2D from input every frame, without CharacterBody2D physics. Useful for quick overhead prototypes.
* ClimbComponent: Enables platformer climbing inside climbable Area2Ds such as ladders, ropes, or cliffs. Handles grabbing, confinement, walking into climb areas, and jump/cancel cases.
* ClimbTileMapComponent: Experimental tile-map ladder or rope climbing for platformers, switching between freeform movement and TileBasedPositionComponent grid movement.
* InputComponent: Shared control-input state for player, AI, or demo sources. Other components can read or modify movement, actions, and input signals without handling raw InputEvents directly.
* JumpComponent: Handles jump input and applies vertical velocity using CharacterBody2D.up_direction. Use with PlatformerPhysicsComponent for gravity and air friction.
* MouseRotationComponent: Rotates the Entity or a chosen Node2D to face the mouse pointer. Add InputComponent when resolving conflicts with keyboard or joystick rotation.
* MouseTrackingComponent: Moves the Entity to the mouse position, either instantly or gradually. Can use InputComponent to resolve exclusivity with joystick-based movement.
* MovementFacingComponent: Rotates a node based on InputComponent movement direction. Useful for aiming a gun in the direction a character last moved.
* PositionControlComponent: Direct input-to-position control without physics. Useful for cursors, cameras, or simple movement where collisions are not needed.
* RandomInputComponent: InputComponent subclass that generates random input on a Timer or connected signals. Useful for NPC wandering, demo mode, or turn-based random actions.
* ScrollerControlComponent: CharacterBody2D control for runners or scrolling shooters, applying constant thrust and maintaining minimum X/Y velocity.
* ThrustControlComponent: Applies forward/backward thrust or braking to a CharacterBody2D from input. Combine with TurningControlComponent for Asteroids-like controls.
* TileBasedAsteroidsControlComponent: TileBasedControlComponentBase subclass for grid-based Asteroids/tank movement, with turn input rotating through compass directions and thrust input moving forward/backward.
* TileBasedControlComponent: Converts InputComponent movement into TileBasedPositionComponent grid movement. Use TileBasedRandomMovementComponent or RandomInputComponent for NPC wandering.
* TileBasedControlComponentBase: Abstract base for tile-based movement controllers that feed TileBasedPositionComponent, including shared step delay and wait-for-arrival behavior.
* TileBasedMouseControlComponent: Snaps TileBasedPositionComponent coordinates to the mouse pointer. Useful for grid selection cursors.
* TurningControlComponent: Rotates a node, such as a gun or vehicle body, from left/right input. Combine with ThrustControlComponent for tank-like movement.


## Core

* Component: Abstract core component base for reusable Entity child nodes that provide distinct gameplay behavior, traits, state, or interactions.
* DebugComponent: Displays debugging values, labels, and charts for an Entity, its components, or other referenced nodes.
* NodeModifierComponentBase: Abstract base for components that create/remove components, remove nodes, or remove the entity. Used by ModifyOnCollisionComponent and ModifyOnTimerComponent.


## Data

* StatModifierComponent: Modifies Stat resources over time using its child Timer. Useful for regeneration, poison, draining mana, or similar timed stat changes.
* StatsComponent: Stores and indexes an Entity's Stat resources, such as health, ammo, or XP, by name and UID.


## Gameplay

* AbilityComponent: Stores gameplay abilities an Entity can perform, such as skills, spells, or commands. Use with AbilityControlComponent for player input and StatsComponent when abilities have Stat costs.
* AbilityReactionComponent: AbilityTargetableComponent subclass that runs Payload reactions after this Entity is chosen as an Ability target. Useful for target-specific commands like activate, talk, or switch on.
* AbilityTargetableComponent: Marks an Entity as a valid target for AbilityTargetingComponentBase flows. Requires a Node2D-style component node to receive mouse events.
* ComponentSwapperComponent: Experimental component-set switcher that removes and adds groups of components from ComponentSet resources at runtime.
* CooldownComponent: Deprecated wrapper around CooldownTimer for actions that need externally visible cooldown state. Prefer CooldownTimer for new simple cooldowns.
* InjectorComponent: Transfers its child nodes, including optional Components, into the first Entity it collides with. Useful for applying buffs, debuffs, or on-hit component payloads.
* InventoryComponent: Stores InventoryItems owned by an Entity.
* LevelUpComponent: Shows a UI or triggers subclass behavior when an XP-style Stat reaches its maximum. Useful for upgrade-choice flows.
* ModifyOnTimerComponent: Adds or removes nodes/components, or removes the entity, when an internal or external Timer times out.
* StatModifierOnDeathComponent: Modifies Stat resources when the entity's HealthComponent reaches death. Useful for score, XP, lives, or kill rewards.
* TimerComponentBase: Abstract base for components that depend on a Timer or are Timer nodes themselves.
* UpgradesComponent: Tracks Upgrade resources owned by an Entity. Use UpgradeChoiceUI or UpgradeChoicesList for player-facing upgrade selection.


## Interaction

* InteractionComponent: Area-based object interaction target activated by an Entity's InteractionControlComponent. Use InteractionWithCostComponent when the target also has cooldown and Stat cost.
* InteractionControlComponent: Player interaction controller for triggering InteractionComponent targets in range via an input action. Its node must be an Area2D.
* InteractionMouseControlComponent: InteractionControlComponent subclass that triggers a specific interaction under the mouse cursor. Requires object picking and input_pickable interaction Areas.
* InteractionWithCooldownComponent: InteractionComponent subclass with a CooldownTimer. Use when an interaction target needs a delay between activations.
* InteractionWithCostComponent: InteractionWithCooldownComponent subclass with a Stat cost. Use with StatsVisualComponent when cost feedback should be shown.
* MineableComponent: Interaction component with a consumable Stat limiting repeated interactions, such as mining rocks or chopping trees for resource drops.
* ModalInteractionComponent: Interaction component that displays a modal UI Control and pauses the entity while the interaction is active.
* PortalInteractionComponent: InteractionComponent subclass for doors, portals, and teleporters, with optional Payload requirements such as keys.
* TextInteractionComponent: Experimental InteractionWithCooldownComponent subclass for signboards, static NPC dialogue, and other cycling text interactions.


## Movement

* AttachmentComponent: Keeps another Node2D or Entity positioned at this component every frame. For mount/rider gameplay, use RideableComponent.
* ChaseComponent: Drives movement toward another Node2D by setting InputComponent.movementDirection. Use NavigationComponent when pathfinding around obstacles is needed.
* IndependentPathFollowComponent: Moves an Entity along a Path2D without PathFollow2D so multiple Entities can have independent progress on the same path.
* LinearMotionComponent: Directly moves an Entity using its rotation or an override direction. Good for simple high-count projectiles.
* NavigationComponent: NavigationAgent2D component for pathfinding toward a target while avoiding obstacles. Falls back to direct movement when no InputComponent is available.
* PathFollowComponent: Moves an Entity by advancing a PathFollow2D parent along a Path2D. Use IndependentPathFollowComponent when multiple Entities need independent positions on one path.
* PlatformerPatrolComponent: Writes horizontal patrol input for platformer enemies that walk back and forth on floors. Requires CornerCollisionComponent for edge/wall awareness.
* PositionClampComponent: Restricts the entity's global position every frame.
* RandomMovementComponent: Moves an Entity randomly by manipulating InputComponent or by directly setting position.
* RelativePathMovementComponent: Applies a finite list of relative movement vectors to a node or Entity over time. Use carefully with other movement-manipulating components.
* RideableComponent: Lets another Entity mount and ride this Entity through a RemoteTransform2D child offset. Use AttachmentComponent for simpler node attachment.
* SpinComponent: Rotates the entity or another Node2D every physics frame.
* TetherComponent: Clamps the entity within a maximum radius of another node.
* TileBasedLinearMotionComponent: Moves in a straight line through one of the eight compass directions on a TileMapLayer grid. Requires TileBasedPositionComponent.
* TileBasedPositionComponent: Maps an Entity to TileMapLayer cell coordinates, handles bounds/vacancy/collision checks, occupancy, and movement between cells. It does not provide input or pathfinding.
* TileBasedRandomMovementComponent: TileBasedControlComponentBase subclass for random grid movement. Use RandomInputComponent for lower-level random input generation.
* WaveMotionComponent: Applies sine/cosine wave movement directly to the entity position, supporting axis waves or circular motion.


## Objects

* CollectibleComponent: Base component for items that can be picked up by an Entity with CollectorComponent. Provides Payload-driven collection behavior.
* CollectibleInventoryComponent: CollectibleComponent subclass that adds an InventoryItem to the collector Entity's InventoryComponent.
* CollectibleStatComponent: CollectibleComponent subclass that increments or decrements a Stat when collected.
* CollectorComponent: Detects CollectibleComponent collisions and executes the collectible Payload on the collector Entity.
* DropOnDeathComponent: Spawns a configured node or scene when the entity's HealthComponent reaches death, such as loot, coins, or cosmetic remains.


## Physics

* AreaCollisionComponent: Area2D collision signal component for detecting Areas, PhysicsBody2Ds, and TileMapLayers without keeping a persistent contact list. Use AreaContactComponent when current contacts must be tracked.
* AreaComponentBase: Abstract base for components that depend on an Area2D, whether the area is the component node, the entity, or a shared Area2D.
* AreaContactComponent: Tracks all Areas, PhysicsBody2Ds, and TileMapLayers currently touching this component's Area2D. Use when gameplay needs a live contact list.
* CharacterBodyComponent: Centralizes CharacterBody2D movement so move_and_slide() is called once per frame after other movement components update velocity. Place after components that modify body motion.
* CharacterBodyDependentComponentBase: Abstract base for components that manipulate a CharacterBody2D through CharacterBodyComponent before or after movement.
* CornerCollisionComponent: Places four Area2Ds around an Entity sprite to help detect nearby floors, walls, and ceilings. Requires Sprite2D.
* GravityComponent: Applies standalone gravity to a CharacterBody2D. Do not combine with PlatformerPhysicsComponent because that component already applies gravity.
* GunRecoilComponent: Applies recoil to the parent CharacterBody2D when GunComponent fires. Pair with VelocityClampComponent if recoil can accumulate too much velocity.
* ModifyOnCollisionComponent: Adds or removes nodes/components, or removes the entity, when Area2D collision criteria are met. Useful for projectile impact behavior.
* OverheadPhysicsComponent: Top-down CharacterBody2D movement physics for friction and velocity processing. Input usually comes from InputComponent, AI, or other movement components.
* PlatformerPhysicsComponent: CharacterBody2D physics for platformer gravity, acceleration, and friction. Does not handle input directly and should not be combined with GravityComponent.
* PushRigidBodyComponent: Lets a CharacterBody2D push RigidBody2Ds after other move_and_slide() users have processed.
* TileCollisionComponent: Area2D component that reports collisions with TileMapLayers and the specific cell coordinates involved.
* VelocityClampComponent: Clamps CharacterBody2D velocity after control components and before CharacterBodyComponent movement. Useful with recoil, knockback, or multiple velocity sources.


## Turn-Based

* TurnBasedAnimationComponent: Plays AnimationPlayer or AnimatedSprite2D animations in response to this component's turn-based signals.
* TurnBasedComponent: Abstract base for components processed by TurnBasedEntity through begin, execute, and end turn phases.
* TurnBasedCounterComponent: Debug/testing component that displays the entity's current turn number and phase.
* TurnBasedStateUIComponent: Experimental UI component for showing TurnBasedEntity and TurnBasedCoordinator state. Intended for a single master turn-based UI Entity.
* TurnBasedTileBasedControlComponent: Moves a turn-based Entity through TileBasedPositionComponent when it is ready to take a turn.
* TurnBasedTileBasedGravityComponent: Experimental turn-based pseudo-gravity for TileBasedPositionComponent entities, using a Timer to advance turns while falling.
* TurnBasedTileBasedPlatformerControlComponent: Experimental turn-based, tile-based platformer control layer. Use TurnBasedTileBasedGravityComponent for gravity.


## Visual

* AnimationComponentBase: Abstract base for visual components that drive an AnimatedSprite2D, such as PlatformerAnimationComponent or OverheadAnimationComponent.
* BlinkPauseComponent: Temporarily pauses and blinks an Entity, then unpauses it and removes itself. Useful for spawn delays, death effects, or attention-grabbing transitions.
* CameraComponent: Wraps an enhanced Camera child, replaces the Entity's previous primary camera reference with it, and can reparent it when the Entity is removed to preserve the view.
* CompassComponent: Tracks a target node and optionally displays a compass indicating the angle from the entity to that target.
* DamageVisualComponent: Experimental visual feedback for actual damage received through DamageReceivingComponent and HealthComponent. Use HealthVisualComponent for generic health Stat changes.
* HealthVisualComponent: Experimental visual feedback for HealthComponent Stat changes, including healing or damage-like decreases from any source.
* HideWhenStationaryComponent: Hides an Entity or chosen node when movement input is idle and shows it again when movement resumes.
* LabelComponent: Experimental animated Label display component attached to an Entity.
* NodeFacingComponent: Rotates an Entity or chosen Node2D to face another node. Useful for aiming guns or visuals toward a cursor or target.
* OffscreenRemovalComponent: Requests deletion of the entity after its VisibleOnScreenNotifier2D leaves the screen, optionally with a delay.
* OverheadAnimationComponent: Drives directional idle/walk AnimatedSprite2D animations from overhead movement input. Uses a naming convention such as idleN, walkN, idleSE, and walkSE.
* PlatformerAnimationComponent: Drives AnimatedSprite2D animations from CharacterBodyComponent and optional InputComponent state for platformer movement.
* ShapeDrawComponent: Experimental vector-shape drawing component for simple visual markers or prototype/debug visuals.
* StatsVisualComponent: Emits TextBubbles and other UI feedback when selected Stats change. Use CollectibleStatComponent for collectible-origin stat bubbles.
* TileBasedAnimationComponent: Plays AnimatedSprite2D animations based on TileBasedPositionComponent grid movement.
* TileBasedSightComponent: Experimental data-only field-of-view component for tile-based games. Computes visibility/brightness values from TileBasedPositionComponent coordinates.


Total listed: 124  
Generated by AI (Codex) on 2026-07-15
