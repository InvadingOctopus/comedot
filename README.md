# Comedot

**Component-based framework and project template for 2D games in the Godot engine**

![Godot+Comedot Logo][logo]

> [!IMPORTANT]
> This is still mostly a private personal project; it's what I'm using to make [my own awesome games][itch] while learning Godot and GDScript as I go. Shit will break quickly and no backwards compatibility is guaranteed.

⭐️ It lets you do stuff like put a `GunComponent` and `MouseRotationComponent` on any object and _It Just Works:_ 

https://github.com/InvadingOctopus/media/assets/11238708/bb03147b-b4b0-4388-ac35-b31b23519bde

⭐️ A "[composition][composition-over-inheritance]" architecture helps you easily change abilities/buffs/debuffs at runtime; just add/remove components in simple event handlers, like this example of swapping between platformer-style movement and flying movement:

https://github.com/InvadingOctopus/media/assets/11238708/a067368c-489c-42f1-aedb-b210b5549489

_(if the videos don't display, view on imgur: [1][rocks-with-guns], [2][swapping-components])_

## How To Use

> [!IMPORTANT]
> **Godot 4.3 is required**. Embrace the Future ✨

🚀 **For a quick glance:** See one of the scenes in the `/Templates/Scenes` folder.

🌳 An example of what a player entity's scene tree looks like:  
![components-tree]

⚙️ **To use this framework for your own games:**

1. Clone this repository (make a local copy of this entire Godot project).
2. Create a new git branch for your game (say `game-of-the-year-2069`) **in your local repository**.
3. Drag-and-drop nodes from the `/Entities/` and `/Components/` folders to build your scenes.
	1. Some components have sub-children, like a `GunComponent`'s pivot point. To modify them, select the component node in the Scene Tree and enable "Editable Children".
	2. The `/Scripts/` folder can be used for any node even if it does not inherit from the `Entity` class.

> [!TIP]
> * Try the existing `game-lab` branch as an example to experiment in.  
> * Create subfolders for your game in the existing folder structure like `/Assets/YourGame/` and `/Scenes/YourGame/` to organize your game-specific files and keep them separate from the framework to avoid accidental overwriting.

🧩 Whenever your game needs an object or "actor" which has to react to events, such as a player or enemy character, or is made up of "behaviors" which could be reused for other objects:
1. Create a new `Entity` scene or node (a Node2D/CharacterBody2D/Area2D/etc/ with the `Entity.gd` script attached)
2. Add `Component` child nodes to the entity. A component is a Node/Node2D/Area2D/etc. with a script which extends the `Component` class.
3. Modify component parameters in the editor's inspector.

> [!TIP]
> 📜 **Read [HowTo.md][howto] to see how to do common tasks** like player movement and combat.
>
> 💬 For more deets, ping Syntaks.io on Discord.

----

[Comedot][repository] ©? MMXXIV [ShinryakuTako@GitHub][github] • [Syntaks.io@Discord][discord]
 
[repository]: https://github.com/invadingoctopus/comedot
[website]: https://invadingoctopus.io
[license]: https://about:blank
[discord]: https://discord.gg/jZG3cBFt7u
[twitter]: https://twitter.com/invadingoctopus
[patreon]: https://www.patreon.com/invadingoctopus
[github]:  https://github.com/ShinryakuTako
[itch]:    https://syntaks.itch.io

[howto]:		HowTo.md
[conventions]:	Conventions.md
[thanks]:		Thanks.md
[todo]:			ToDo.md

[composition-over-inheritance]: https://en.wikipedia.org/wiki/Composition_over_inheritance
[entity–component–system]: https://en.wikipedia.org/wiki/Entity_component_system
[swift-api-guidelines]: https://swift.org/documentation/api-design-guidelines/

[rocks-with-guns]: https://i.imgur.com/wH84m23.gifv "Rocks with Guns"
[swapping-components]: https://i.imgur.com/iS0xjdI.mp4 "Swapping Control Components"
[components-tree]: https://i.imgur.com/WW2grLs.png "Example Components Tree for a Player Entity"

[logo]: /Assets/Logos/Comedot.png "Godot+Comedot Logo"