@tool
extends ScrollContainer

@onready var keyword_input: LineEdit = $VBoxContainer/KeywordInput
@onready var componentsTree: Tree = %ComponentsTree


func _ready():
	keyword_input.connect("text_changed", Callable(self, "onKeywordInput_textChanged"))


func onKeywordInput_textChanged(keyword: String):
	var root = componentsTree.get_root()

	for category in root.get_children():
		for item in category.get_children():
			var text = item.get_text(0)
			item.set_visible(keyword == "" or fuzzy_match(text, keyword))


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
