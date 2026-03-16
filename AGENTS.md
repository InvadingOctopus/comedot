# AGENTS.md
# Repository Guidelines


## Project Overview
- This project is a template for the Godot game engine.
- It's a component-based framework similar to ECS for making 2D games.
- It's open-source and hosted at https://github.com/InvadingOctopus/comedot
- For more details, see `README.md`


## Folder Structure & Module Organization
- `Components/`, `Entities/`: The core foundational classes of the framework and common gameplay components.
- `AutoLoad/`: Global singletons, startup scripts and shared helper functions.
- `Scripts/`: Shared scripts that can be used for any node type that isn't an entity or component.
- `Resources/`: Classes for Godot `.tres` "Resources" (not media assets): Data containers for core gameplay elements such as `Stat.gd`
- `Scenes/`, `UI/`: Reusable and customizable scenes/nodes and UI controls/layouts.
- `Templates/`: Prebuilt entity+component sets and scenes for quick gameplay prototyping.
- `Assets/`: Art/sound/music and other media, including third-party packs for placeholders and prototyping.
- `Tests/`: Playable scenes and supporting scripts for manually testing subsystems and mechanics such as combat or tile-based/turn-based components. Name format: `*Test.tscn` + `*Test.gd`
- `addons/`: Godot Editor plugins.
- `Temporary/`, `Lab/`: Transient experiments. All files in these folders should always be ignored. Disregard any errors or warnings in files in those folders. If a file in these folders prevents compilation/parsing/export, consider removing that file.
- `Scripts/Tools.gd`: A monolithic class script containing global static helper functions for builtin Godot nodes & types. This is a workaround for the inability to extend builtin Godot types with custom methods without using subclasses.
- `Game/`: Game-specific files that are NOT part of the Comedot framework itself. These files should be ignored when referring to the framework, and only accessed when considering an actual game being made with Comedot. Everything outside the `Game/` subtree is part of the framework that is shared between multiple games. When generating code for a game, only the files in the `Game/` subtree should be modified. `Game/AGENTS.override.md` takes precedence for any activity inside the `Game/` subtree.


## Subsystems
- Various sets or "chains" of components/scripts work together to implement the different "subsystems" involved in gameplay:
	- Combat or passive damage: `DamageComponent`, `DamageReceivingComponent`, `FactionComponent`, `HealthComponent`
	- Stats: `Stat`, `StatsComponent`, `StatUI`
	- Collectibles (items that can be picked up): `CollectibleComponent`, `CollectorComponent`
	- Interactive objects: `InteractionComponent`, `InteractionControlComponent`
	- Special actions (such as a "dash" move, or magic spells, or abilities in an RPG etc.): `Action`, `ActionsComponent`, `ActionControlComponent`
	- and their auxiliaries, such as `KnockbackOnHitComponent` which extends the combat/damage subsystem etc.
- Classes with a "Base" suffix are used as the foundation for several other classes/systems, such as `GameplayResourceBase.gd` and `StatDependentResourceBase.gd`
- In general, when a certain gameplay mechanic or feature is needed, search the framework for synonyms of that system to see if there is a component or script for it.


## Build, Run, Test & Export
- Open the Comedot template in Godot by selecting `project.godot` 
- `project.godot` contains the required Godot version under `config/features` and other metadata. Comedot always targets the latest version (release or beta).
- Refer to the official documentation when needed, at `https://docs.godotengine.org/en/latest/`
- Run locally from the editor (F5) or run individual scenes (F6) for focused testing.
- To verify scripts and check parser errors etc. run Godot in "headless" mode by passing the following flags to the Godot executable: `--headless --check-only --path [path] --script [filename]`
	- To run for N frames, use `--quit-after [frame count]`
	- Godot may crash at startup in headless mode if it cannot write the default `user://logs` file: Pass an explicit writable `--log-file` argument in `/tmp` or another suitable folder.
	- If the Godot executable is unavailable or live execution is not necessary, just read/lint GDScript manually for static analysis. 
	- For other commands and flags, see `https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html`
- Exports are driven by Godot’s export presets (`export_presets.cfg`); use the editor’s Export dialog for builds.
- Tests are represented as Godot scenes/scripts under `Tests/` to be played manually. `*Test.tscn` with companion `.gd` where needed.
- Run tests by opening a test scene and manually running it in the editor.
- No formal coverage targets are defined; keep regression tests near the relevant feature.


## Review Guidelines
- Ignore the contents of `Temporary/` and `Lab/`
- Functions and types marked with an `@experimental` comment are expected to have bugs and incomplete implementations. Findings involving experimental code should be a lower priority and not expected to be fixed, unless important non-experimental code depends on that experimental code.
- Not all `null` references need to be guarded: In some cases, a crash may be better than a warning or a silent failure/skip, specially if it's a core object which should never be missing at runtime under normal circumstances.
- Ignore the contents of `Game/` unless the prompt and context involves a specific game being made with the main framework project.
- The contents of `Game/` are subject to the instructions in `Game/AGENTS.override.md`


## Coding Style & Naming Conventions
Follow the guidelines in `Conventions.md`, which includes these key rules:
- Tabs, not spaces; GDScript is indentation-sensitive.
- Prefer camelCase for everything, including constants; avoid underscores except in rare cases.
- Types (class names, enums) are Capitalized.
- Two empty lines between major code sections or different "categories" (functions, properties, signals, regions).
- Booleans should start with `is`/`has`/`should` wherever it makes grammatical sense, but may use shorter concise names.
- Function/method names should be imperative verbs wherever it makes grammatical sense: `doSomething()`, `checkRequirements()`
- Signal handlers should be named as `on[Emitter]_[signal]`
- Prefer strong static typing: Write out explicit types, e.g. `var number: int = 42` instead of `var number := 42`, but `:=` may be used where the type isn't certain at coding time.
- If instructions conflict or drift, `Conventions.md` takes precedence and includes exceptions for some rules. In case of ambiguity, match existing patterns.
- There is no automated formatter configured; match existing style manually.


## Generating New Code & Scenes
- DO NOT EDIT ANY FILES UNLESS EXPLICITLY TOLD TO.
- See `HowTo.md` and `Conventions.md` (specially the "Avoid" section)
- New gameplay behaviors should generally be implemented as components that can be reused in multiple games. 
- "Components" are any node with a script that is a subclass of `Components/Component.gd`, and "entities" are any node with the `Entities/Entity.gd` script or its subclasses. Entities are just a container for components and multiple components can be added to an entity. Components are generally standalone and provide a single specific behavior or set of closely-related behaviors, but components may depend on each other and modify each other at runtime, such as `DamageComponent` + `DamageReceivingComponent` + `KnockbackOnHitComponent`
- Components are always a pair of a `.tscn` Godot scene file + a `.gd` GDScript file, even if the scene is empty, so they can be easily added to entity nodes. Component scripts must ultimately inherit from `Component.gd` or a subclass. Component root nodes must be added to the `components` node group.
- A `class_name` must be used for all components and entities, and also for other types that are expected to be referenced from code or instantiated at runtime. Exceptions are short specific scripts such as `Spin.gd`
- The root node of component scenes must be the closest relevant Godot builtin node type that matches the component's core purpose: For example, if the component uses a `Timer` and no other nodes, then the root node must be a `Timer` instead of `Node` with a `Timer` child.
	- Simple components that don't need a specialized node and don't have any visual features should use `Node` as the root node instead of `Node2D`
	- If a single specialized node component needs to be changed to include more subnodes, consider refactoring the root to a `Node` or `Node2D` and make the former root a child of the new root, e.g. `/Timer` -> `/Node/Timer`
	- If a component has visual child nodes that have position etc. the root node should be `Node2D` to allow offsetting all children from the entity etc.
- Entities may be any node type with the `Entity.gd` script or one of its subclasses. Entities are just containers for components: Games should not create new entity scripts except in rare unavoidable cases; game-specific functionality should always be implemented as new components. Entity nodes must be added to the `entities` node group. Entities do not have to be just visual/interactive elements: "abstract" concepts such as the "WorldEnvironment" may also be an entity, with components for "Weather", "DayNightCycle", "GlobalBuffs" etc.
- Entities, components and other nodes must be added to the relevant preset node groups such as `turnBased`, `players`, `enemies`, `collectibles` etc. as applicable.
- Scripts that extend specific Godot builtin nodes types for a specific purpose or a simple effect do not have to be entities or components, such as `SpawnArea.gd` for `Area2D`,  or `Spin.gd` for any `Node2D`, or UI scripts such as `StatUI.gd` and `StatBar.gd` that are meant for `Control` nodes.
- Filenames should be clear and precise. Add suffixes like `Entity` and `Component` to assist referencing and searching etc. Entities should be named like `MonsterEntity.gd` and components should be named like `MonsterAttackComponent.gd`. There may be exceptions for brevity for certain resources such as `Health.gd` instead of `HealthStat.gd` unless there is ambiguity. Standalone scripts that are not for an entity or component, such be named as a verb describing the action if applicable, like `Spin.gd` and `SnapToMouse.gd`. Filenames don't have to be short, for example `TurnBasedTileBasedPlatformerControlComponent`
- Avoid "shadowing" properties; do not give a function or loop/block variable the same name as property of the class or inherited from the superclass, e.g. `body` in `PlatformerPhysicsComponent.gd`


## Common Godot Errors & Gotchas to Avoid
- Do not cast types using a direct `as` or `is`: Avoid `var otherNodeAsCastedType: CastedType = otherNode as CastedType` or `if otherNode is CastedType:` because the Godot parser considers it as an error; instead use this workaround: `var otherNodeAsCastedType: CastedType = nodeToCast.get_node(^".") as CastedType` (the `as` in this case is superfluous and may be omitted) or `if is_instance_of(someNode, CastedType)`


## Commit & Pull Request Guidelines
Commit messages should have a title that is short and imperative like `Add TurnBasedLab` or `Fix TurnBasedStateUIComponent`, referencing the file/class/type/issue.
The commit message content should be a bullet list, using this notation for the bullet symbols:
* Asterisk for changes that are not explicit additions of new features or removals of previous features, such as renames.
+ A plus sign for additions of new properties/methods added to a class/type/file.
- A minus sign for removal of properties/methods deleted from a class/type/file.
! An exclamation sign for high impact fixes or the most important changes in the commit.
? A question mark for some comments such as possible bugs, uncertain behavior, "TBD" (To Be Decided) remarks, etc.
! TODO: An exclamation sign + `TODO:` etc. for updating dependents etc. affected by this commit, to be included in the following next commits, especially if this commit leaves the project in a broken state.

For PRs:
- The submitter should describe the gameplay impact and affected components/scenes.
- Link related issues, if any.
- Include screenshots or short clips for UI/scene changes when applicable.
