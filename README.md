# Comedot

**Component-based framework and project template for 2D games in the Godot engine**

> [!IMPORTANT]
> This is still mostly a private personal project; it's what I'm using to make my own awesome games while learning Godot and GDScript as I go.

⭐️ It lets you do stuff like put a `GunComponent` and `MouseRotationComponent` on any object and _It Just Works:_ 

[![Rocks with Guns](https://i.imgur.com/wH84m23.gif)](https://i.imgur.com/wH84m23.gifv)

⭐️ One of the best benefits of "composition" is the ability to easily add and remove abilities/buffs/debuffs at runtime, like this example of swapping between platform movement and flying movement:

[![Swapping Control Components](https://i.imgur.com/IxxOXX6.gif)](https://i.imgur.com/IxxOXX6.gifv)

_(darn GitHub, if the images do not animate, click on them to go to the Imgur pages)_

_(You can see some of what's being made with this framework at [syntaks.itch.io](https://syntaks.itch.io))_

## How To Use

🚀 **For a quick glance:** See one of the scenes in the `/Templates/Scenes` folder.

⚙️ **To use this framework for your own games:**
1. Clone this repository to your local storage (this entire Godot project)
2. Make a subfolder for your game in the `/Games/` folder (say `/Games/EldenRing2D/`)
3. Drag-and-drop nodes from the `/Entities/` and `/Components/` etc. folders to build your scenes, like Lego blocks or puzzle pieces.
	1. Some components have sub-children, like a `GunComponent`'s pivot point. To modify them, select the component node in the Scene Tree dock and enable "Editable Children".
	2. The `/Scripts/` folder can be used for any node even if it is not inherited from the `Entity` class.

🧩 Whenever you want to add an object or "actor" to your game which has to react to events, or is made up of "behaviors" which could be reused for other objects:
1. Create a new `Entity` scene or node (a Node2D/CharacterBody2D/Area2D with the `Entity.gd` script attached)
2. Add `Component` child nodes to the entity. A component is a Node/Node2D/Area2D etc. with a script which extends the `Component` class.
3. Modify component parameters in the editor's inspector.

> [!TIP]
> 📜 **Read [HowTo.md](HowTo.md) to see how to do common tasks** like player movement and combat.

💬 For more details, bug Syntaks.io on Discord.

----

©? MMXXIV ShinryakuTako@GitHub / Syntaks.io@Discord
