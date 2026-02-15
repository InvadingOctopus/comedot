# AGENTS.md
# Repository Guidelines


## Project Overview
- This project is a template for the Godot game engine.
- It's a component-based framework similar to ECS for making 2D games.
- It's open-source and hosted at https://github.com/InvadingOctopus/comedot


## Folder Structure & Module Organization
- `Components/`, `Entities/`: The core foundational classes of the framework and common gameplay components.
- `addons/`: Godot Editor plugins.
- `Assets/`: Art/media/sound/music, and third-party assets for prototyping.
- `AutoLoad/`: Global singletons and startup scripts.
- `Scripts/`: Shared scripts that can be used for any node type, not just entities/components.
- `Scenes/`, `UI/`, `Resources/`: Reusable scenes/nodes, UI layouts, and reusable resources.
- `Templates/`: Prebuilt entities and scenes for quick gameplay prototyping.
- `Tests/`: Playable scenes and supporting scripts for testing subsystems and mechanics such as combat or tile-based/turn-based components (e.g., `*Test.tscn`, `*Test.gd`).
- `Temporary/`, `Lab/`: Files in these folders are temporary experiments and should always be ignored. Disregard any errors or warnings in files in those folders.
- `Game/`: Game-specific files that are NOT part of the Comedot framework itself. These files should be ignored when referring to the framework, and only accessed when considering an actual game being made with Comedot. Everything outside the `Game/` subtree is part of the framework that is shared between multiple games. When generating code for a game, only the files in the `Game/` subtree should be modified. `Game/AGENTS.override.md` takes precedence for any activity inside the `Game/` subtree.


## Build, Test, Run & Export
- Open the project in Godot by selecting `project.godot`.
- See `project.godot` for the required Godot version; Comedot always targets the latest version (release or beta).
- Run locally from the editor (F5) or run individual scenes (F6) for focused testing.
- Exports are driven by Godot’s export presets (`export_presets.cfg`); use the editor’s Export dialog for builds.
- Tests are represented as Godot scenes/scripts under `Tests/` to be played manually. `*Test.tscn` with companion `.gd` where needed.
- Run tests by opening a test scene and manually running it in the editor.
- No formal coverage targets are defined; keep regression tests near the relevant feature.


## Coding Style & Naming Conventions
Follow the guidelines in `Conventions.md`, which includes these key rules:
- Tabs, not spaces; GDScript is indentation-sensitive.
- Prefer camelCase for everything, including constants; avoid underscores except in rare cases.
- Types (class names, enums) are Capitalized.
- Booleans should start with `is`/`has`/`should` wherever it makes grammatical sense, but may use shorter concise names.
- Function/method names should be imperative verbs wherever it makes grammatical sense: `doSomething()`, `checkRequirements()`
- Two empty lines between major sections or different "categories" (functions, properties, signals, regions).
- Signal handlers use `on[Emitter]_[signal]` (exceptions may be noted in `Conventions.md`).
- Prefer strong static typing: Write out explicit types, e.g. `var number: int = 42` instead of `var number := 42`, but `:=` may be used where the type isn't certain at coding time.
- If instructions conflict, `Conventions.md` takes precedence. In case of ambiguity, match existing patterns.

There is no automated formatter configured; match existing style manually.


## Review Guidelines
- Ignore the contents of `Temporary/` and `Lab/`.
- Ignore the contents of `Game/` unless the prompt and context involves a specific game being made with the main framework project.
- The contents of `Game/` are subject to the instructions in `Game/AGENTS.override.md`.
- Functions and types marked with an `@experimental` comment are expected to have bugs and incomplete implementations. Findings involving experimental code should be a lower priority and not expected to be fixed, unless more important non-experimental code depends on that experimental code.


## Creating New Code & Scenes
- New gameplay behaviors should generally be implemented as components for others to reuse in multiple games.
- Components are always a pair of `.tscn` Godot scene file + `.gd` GDScript file, even if the scene is empty, so they can be easily added to entity nodes. Component scripts must ultimately inherit from `Component.gd` or a subclass. Component root nodes must be added to the `components` node group.
- The root node of component scenes must be the closest relevant Godot builtin node type that matches the component's core purpose. For example, if the component uses a `Timer` and no other nodes, then the root node must be a `Timer` instead of `Node` with a `Timer` child. Components that do not have any visual features must use `Node` as the root node instead of `Node2D`.
- Entities may be any node type with the `Entity.gd` script or one of its subclasses. Entities are just containers for components: Games should not create new entity scripts except in rare unavoidable cases; game-specific functionality should always be implemented as new components. Entity nodes must be added to the `entities` node group. Entities do not have to be just visual/interactive elements: "abstract" concepts such as the "WorldEnvironment" may also be an entity, with components for "Weather", "DayNightCycle", "GlobalBuffs" etc.
- Entities, components and other nodes must be added to the relevant preset node groups such as `turnBased`, `players`, `enemies`, `collectibles` etc. as applicable.
- Scripts that extend single specific Godot builtin nodes types such as `SpawnArea.gd` for `Area2D` do not have to be entities or components.


## Commit & Pull Request Guidelines
Commit messages should have a title that is short and imperative like `Add TurnBasedLab` or `Fix TurnBasedStateUIComponent`, referencing the file/class/type/issue.
The commit message content should be a bullet list, using this notation for the bullet symbols:
* Asterisk for changes that are not explicit additions of new features or removals of previous features, such as renames.
+ A plus sign for additions of new properties/methods added to a class/type/file.
- A minus sign for removal of properties/methods deleted from a class/type/file.
! An exclamation sign for high impact fixes or the most important changes in the commit.
? A question mark for some comments such as possible bugs, uncertain behavior, "TBD" (To Be Decided) remarks, etc.

For PRs:
- Describe the gameplay impact and affected components/scenes.
- Link related issues (see `ToDo.md` references in `CONTRIBUTING.md`).
- Include screenshots or short clips for UI/scene changes when practical.
