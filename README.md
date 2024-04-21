# Godoctopus

**Component-based framework and project template for 2D games in the Godot engine**

> [!IMPORTANT]
> This is still mostly a private personal project; it's what I'm using to make my own awesome games while learning Godot and GDScript as I go.

To check it out, see one of the scenes in the `/Templates/Scenes` folder.

To use this framework for your own games, create a copy of the repository and make a subfolder for your game in the `/Games` folder, then drag-and-drop nodes from the `/Entities` and `/Components` etc. folders to build your scenes.

The intended workflow is that whenever you want to add an object or "actor" to your game which has to react to events or is made up of "behaviors" which could be reused for other objects, you create an `Entity` node, then you add `Component` child-nodes to the entity, and modify their parameters in the editor's inspector. For more details, ask me on Discord.

----

©? MMXXIV ShinryakuTako@GitHub / Syntaks.io@Discord
