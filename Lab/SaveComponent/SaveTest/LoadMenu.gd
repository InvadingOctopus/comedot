extends Control

class_name SaveList

signal save_selected(path: String)
signal loaded

@export var saves_dir: String = "user://saved_games"
@export var container_path: NodePath            # set this to a VBoxContainer / GridContainer in the scene
@export var allowed_extensions: PackedStringArray = ["save", "json"]  # filter as you like
@export var show_modified_time: bool = true
@export var newest_first: bool = true
@export var auto_create_dir: bool = true        # create the saves dir if missing

@onready var _container: Control = get_node(container_path)
var noSaves: bool = true
var _manager: SavableStateManager

func _ready() -> void:
	if auto_create_dir:
		_ensure_dir(saves_dir)
	refresh()
	loaded.emit()
	_manager = GameState.get_node_or_null("SavableStateManager")

func refresh() -> void:
	_clear_container()
	var items := _list_saves(saves_dir, allowed_extensions)
	if newest_first:
		items.sort_custom(func(a, b): return a.mtime > b.mtime)
	else:
		items.sort_custom(func(a, b): return a.mtime < b.mtime)

	if items.is_empty():
		_add_label("(no saves found)")
		noSaves = true
		return
	else:
		noSaves = false

	for item in items:
		_add_save_button(item.name, item.path, item.mtime)

func _list_saves(dir_path: String, exts: PackedStringArray) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir_path)
	if d == null:
		return out
	d.list_dir_begin()
	while true:
		var name := d.get_next()
		if name == "":
			break
		if d.current_is_dir():
			continue
		var ext := name.get_extension().to_lower()
		if exts.is_empty() or exts.has(ext):
			var path := dir_path.path_join(name)
			var mtime := 0
			# FileAccess.get_modified_time returns seconds since epoch (int)
			if FileAccess.file_exists(path):
				mtime = FileAccess.get_modified_time(path)
			out.append({
				"name": name.get_basename().get_file(), # filename without extension
				"path": path,
				"mtime": mtime
			})
	d.list_dir_end()
	return out

func _add_save_button(label: String, path: String, mtime: int) -> void:
	var btn := Button.new()
	btn.text =  "%s  —  %s" % [label, _fmt_time(mtime)] if show_modified_time else label
	btn.tooltip_text = path
	btn.set_meta("save_path", path)
	btn.pressed.connect(func():
		_manager.loadStateFromFile(path)
		GameState.startMainScene()
		#var p: String = btn.get_meta("save_path")
		#emit_signal("save_selected", p)
	)
	_container.add_child(btn)

func _add_label(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.modulate = Color(1,1,1,0.7)
	_container.add_child(l)

func _clear_container() -> void:
	for c in _container.get_children():
		c.queue_free()

func _fmt_time(ts: int) -> String:
	if ts <= 0:
		return "unknown"
	var dt := Time.get_datetime_dict_from_unix_time(ts)
	# e.g., 2025-08-24 14:32
	return "%04d-%02d-%02d %02d:%02d" % [
		dt.year, dt.month, dt.day, dt.hour, dt.minute
	]

static func _ensure_dir(dir_path: String) -> void:
	# Create if missing (safe to call even if it exists)
	DirAccess.make_dir_recursive_absolute(dir_path)
