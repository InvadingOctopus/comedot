## A single-line text box that filters the items of a [Tree] control based on a search query.
## Uses a [Timer] to delay updates for better performance.

@tool
# class_name TreeSearchBox # Not needed yet
extends LineEdit

# CREDIT: @datouzhu125@GitHub <116731303+datouzhu125@users.noreply.github.com>


#region Parameters
@export var tree: Tree ## The [Tree] to filter.
#endregion


#region State
var treeRoot: TreeItem:
	get:
		if not treeRoot: treeRoot = tree.get_root()
		return treeRoot
#endregion


#region Events

func _ready() -> void:
	self.right_icon = self.get_theme_icon(&"Search", &"EditorIcons")


func _unhandled_key_input(event: InputEvent) -> void:
	if not self.has_focus(): return
	
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			if not self.text.is_empty():
				self.text = ""
				setVisibilityOfAll(true)
				accept_event()
				self.get_viewport().set_input_as_handled()


func onTextChanged(_new_text:String) -> void:
	# NOTE: PERFORMANCE: Update the filter after a short delay, to reduce performance impact if a user types fast.
	if $UpdateDelayTimer.is_stopped(): $UpdateDelayTimer.start()


func onUpdateDelayTimer_timeout() -> void:
	updateFilter()

#endregion


#region Filter

func updateFilter() -> void:
	if self.text.is_empty(): setVisibilityOfAll(true)
	else: filter(self.text)


func filter(searchQuery: String) -> void:
	# Sift through all categories
	for category in treeRoot.get_children():
		var childCount: int = category.get_child_count()

		if childCount > 0: # Skip iterating over empty categories
			for item in category.get_children():
				var itemName: String = item.get_text(0)
				
				if itemName.containsn(searchQuery):
					item.visible = true
				else:
					item.visible = false
					childCount  -= 1 # Keep track of how many rows have been hidden

		# Hide the entire category if all the rows under it have been hidden
		category.visible = childCount > 0


func setVisibilityOfAll(visibility: bool) -> void:
	for category in treeRoot.get_children():
		category.visible = visibility
		for item in category.get_children():
			item.visible = visibility

#endregion
