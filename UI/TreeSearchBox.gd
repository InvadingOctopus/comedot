## A single-line text box that filters the items of a [Tree] control based on a fuzzy search query.
## Uses a [Timer] to delay updates for better performance.

@tool
# class_name TreeSearchBox # Not needed yet
extends LineEdit

# CREDIT: @datouzhu125@GitHub <116731303+datouzhu125@users.noreply.github.com>


#region Parameters
@export var tree: Tree ## The [Tree] to filter.
#endregion


#region State

@onready var fuzzySearch: FuzzySearch = FuzzySearch.new()

var treeRoot: TreeItem:
	get:
		if not is_instance_valid(treeRoot): treeRoot = tree.get_root()
		return treeRoot

#endregion


#region Events

func _ready() -> void:
	self.right_icon = self.get_theme_icon(&"Search", &"EditorIcons")
	# TBD: These values are @experimental
	fuzzySearch.case_sensitive	= false
	fuzzySearch.max_misses		= 0
	fuzzySearch.max_results		= 200
	fuzzySearch.filter_low_scores = true


func onGuiInput(event: InputEvent) -> void:
	if not self.has_focus() or not event is InputEventKey or event.is_echo(): return

	if event.is_action_pressed(&"ui_cancel"):
		if not self.text.is_empty():
			self.text = ""
			setVisibilityOfAll(true)
			accept_event() # [Control]'s wrapper for set_input_as_handled()


func onTextChanged(_new_text:String) -> void:
	# NOTE: PERFORMANCE: Don't update the list immediately after every keystroke;
	# Update the filter after a short delay, to reduce performance impact if a user types fast.
	if $UpdateDelayTimer.is_stopped(): $UpdateDelayTimer.start()


func onUpdateDelayTimer_timeout() -> void:
	updateFilter()

#endregion


#region Filter

func updateFilter() -> void:
	if self.text.is_empty(): setVisibilityOfAll(true)
	else: filter(self.text)


func filter(searchQuery: String) -> void:
	var childCount:	int
	searchQuery = searchQuery.replace(" ", "") # Compact to assist fuzzy search

	# TBD: Allow less exact matches when the string is long?
	# if   searchQuery.length() <= 4:	fuzzySearch.max_misses = 0
	# elif searchQuery.length() <= 8:	fuzzySearch.max_misses = 1
	# else:								fuzzySearch.max_misses = 2

	# Sift through all categories
	for category: TreeItem in treeRoot.get_children():
		childCount = category.get_child_count()

		if childCount > 0: # Skip iterating over empty categories
			# Sift through all the items in a category
			for item: TreeItem in category.get_children():
				if fuzzySearch.search(searchQuery, item.get_text(0)):
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


#region Experimental

var treeItemsCache:		PackedStringArray ## @experimental
var shouldUpdateCache:	bool = false ## @experimental

## @experimental
func buildCache() -> void:
	var childCount:	int
	for category: TreeItem in treeRoot.get_children(): # Categories
		childCount = category.get_child_count()
		if childCount < 1: continue
		for item: TreeItem in category.get_children(): # Components
			treeItemsCache.append(item.get_text(0)) # Can't use a Dictionary because duplicate component names in different categories will overwrite each other

#endregion
