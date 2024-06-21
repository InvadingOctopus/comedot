# Comedot

**Component-based framework and project template for 2D games in the Godot engine**

> [!IMPORTANT]
> This is still mostly a private personal project; it's what I'm using to make [my own awesome games][itch] while learning Godot and GDScript as I go. Shit will break quickly and no backwards compatibility is guaranteed.

⭐️ It lets you do stuff like put a `GunComponent` and `MouseRotationComponent` on any object and _It Just Works:_ 

[![Rocks with Guns](https://i.imgur.com/wH84m23.gif)](https://i.imgur.com/wH84m23.gifv)

⭐️ One of the best benefits of "[composition][composition-over-inheritance]" is the ability to easily change abilities/buffs/debuffs at runtime. There is no need to maintain complex `if/else` pyramids in a "master" script; just add/remove components in simple event handlers, like this example of swapping between platformer-style movement and flying movement:

[![Swapping Control Components](https://i.imgur.com/IxxOXX6.gif)](https://i.imgur.com/IxxOXX6.gifv)

_(darn GitHub, if the images do not animate, click on them to go to the Imgur pages)_

## How To Use

> [!IMPORTANT]
> **Godot 4.3 is required**.

🚀 **For a quick glance:** See one of the scenes in the `/Templates/Scenes` folder.

🌳 An example of what a player entity's scene tree looks like:  
![components-tree]

⚙️ **To use this framework for your own games:**

1. Clone this repository (make a local copy of this entire Godot project)
2. Make a subfolder for your game in the `/Games/` folder (say `/Games/EldenRing2D/`)
3. Drag-and-drop nodes from the `/Entities/` and `/Components/` folders to build your scenes.
	1. Some components have sub-children, like a `GunComponent`'s pivot point. To modify them, select the component node in the Scene Tree and enable "Editable Children".
	2. The `/Scripts/` folder can be used for any node even if it does not inherit from the `Entity` class.

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

[rocks-with-guns]: https://i.imgur.com/wH84m23.gif "Rocks with Guns"
[swapping-components]: https://i.imgur.com/IxxOXX6.gif "Swapping Control Components"
[components-tree]: https://i.imgur.com/WW2grLs.png "Example Components Tree for a Player Entity"