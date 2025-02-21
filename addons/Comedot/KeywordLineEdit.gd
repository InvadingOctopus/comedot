@tool
extends LineEdit

@onready var componentsTree: Tree = %ComponentsTree


func onTextChanged(new_text: String) -> void:
	if new_text == "":
		showAll()
	else:
		filter(new_text)


func filter(keyword: String):
	var root = componentsTree.get_root()

	for category in root.get_children():
		var childCount = category.get_child_count()
		if childCount <= 0:
			break

		for item in category.get_children():
			var text = item.get_text(0)
			if fuzzy_match(text, keyword):
				item.visible = true
			else:
				item.visible = false
				childCount -= 1

		category.visible = childCount > 0


func showAll():
	var root = componentsTree.get_root()
	for category in root.get_children():
		category.visible = true
		for item in category.get_children():
			item.visible = true


func fuzzy_match(target: String, query: String) -> bool:
	var target_lower = target.to_lower()
	var query_lower = query.to_lower()

	var query_index = 0
	var target_index = 0

	while query_index < query_lower.length() and target_index < target_lower.length():
		if query_lower[query_index] == target_lower[target_index]:
			query_index += 1
		target_index += 1

	# If query_index is equal to query_lower.length(),all characters match.
	return query_index == query_lower.length()


func _input(event: InputEvent) -> void:
	if !self.has_focus():
		return
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			if self.text != "":
				self.text = ""
				showAll()
				accept_event()
