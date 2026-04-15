## Helper functions to assist with common tasks involving files & folders.

class_name FileSystemTools
extends GDScript



## Returns a copy of the specified [param path] with the specified [param prefix] added if the path does not begin with "res://" or "user://".
## If the path already has a prefix then it is returned unmodified.
## NOTE: Case-sensitive.
static func addPathPrefixIfMissing(path: String, prefix: String = "res://") -> String:
	if  not path.begins_with("res://") \
	and not path.begins_with("user://"):
		return prefix + path
	else:
		return path


## Returns a list of all the subfolders and recursively searches for any deeper subfolders inside the folder at [param initialPath]
## IMPORTANT: The [param initialPath] must begin with `"res://"` or `"user://"`
## Callers should first verify that the [param initialPath] is valid and can be accessed, as this method returns an empty array on failure, which may be indistinguishable from a valid but empty folder.
## NOTE: Includes [param initialPath] in the returned [PackedStringArray]
static func findAllSubfolders(initialPath: String = "res://") -> PackedStringArray:
	var subfolders: PackedStringArray
	var dirAccess:  DirAccess = DirAccess.open(initialPath)
	if not dirAccess:
		print("Error: Cannot open DirAccess @ " + initialPath) # NOTE: Don't use Debug.gd logging so this method can be used by the Comedot plugin/addon.
		return []

	# PLAN: Go through each folder in the `subfolders` array,
	# index-wise, not via iterator as the array will be modified during iteration.
	# Get the subfolders of each folder, and append them at the end of the array.
	# This way, all child folders are added to the list, and then their children are added, ensuring a full traversal.

	subfolders.append(initialPath) # Add the initial folder to enumerate the contents of

	var index: int = 0
	var parentPath: String
	var newSubfoldersToAppend: PackedStringArray

	while index < subfolders.size():
		# WORKAROUND: Dummy Godot does not give us the full path in each item returned by DirAccess.get_directories_at()
		# so we have to prefix it manually >:(
		parentPath = subfolders[index] # Get the current folder being enumerated, which is assumed to be prefixed with its full path already.
		newSubfoldersToAppend.clear() # Clear any previous additions
		for newSubfolder in DirAccess.get_directories_at(parentPath):
			newSubfoldersToAppend.append(parentPath + "/" + newSubfolder) # Prefix the parent folder's path to each subfolder's name. grrr
		subfolders.append_array(newSubfoldersToAppend)
		index += 1 # Enumerate the next folder

	return subfolders


## Returns an array of all files at the specified path which include [param filter] (case-insensitive) in the filename.
## If [param filter] is empty then all files are returned.
## If the [param folderPath] does not begin with "res://" or "user://" (case-sensitive) then "res://" is added.
## NOTE: When used on a "res://" path in an exported project, only the files actually included in the PCK at the given folder level are returned.
static func getFilesInFolder(folderPath: String, filter: String = "") -> PackedStringArray:
	folderPath = FileSystemTools.addPathPrefixIfMissing(folderPath, "res://") # Use the exported/packaged resources path if omitted.
	var folder: DirAccess = DirAccess.open(folderPath)
	if folder == null:
		Debug.printWarning("getFilesFromFolder() cannot open " + folderPath)
		return []

	folder.list_dir_begin() # CHECK: Necessary for get_files()?
	var files: PackedStringArray

	for fileName: String in folder.get_files():
		if filter.is_empty() or fileName.containsn(filter):
			files.append(folder.get_current_dir() + "/" + fileName) # CHECK: Use get_current_dir() instead of folderPath?

	folder.list_dir_end() # CHECK: Necessary for get_files()?
	return files


## Returns an array of the exported resources in the specified folder which include [param filter] (case-insensitive) in the exported filename.
## If [param filter] is empty then all resources are returned.
## If the [param folderPath] does not begin with "res://" or "user://" (case-sensitive) then "res://" is added.
static func getResourcesInFolder(folderPath: String, filter: String = "") -> PackedStringArray:
	folderPath = FileSystemTools.addPathPrefixIfMissing(folderPath, "res://") # Use the exported/packaged resources path if omitted.
	var resources: PackedStringArray = ResourceLoader.list_directory(folderPath)
	if resources.is_empty(): return []

	if not folderPath.ends_with("/"): folderPath += "/" # Tack the tail on

	var filteredResources: PackedStringArray
	for resourceName: String in resources:
		if filter.is_empty() or resourceName.containsn(filter):
			filteredResources.append(folderPath + resourceName)

	return filteredResources


## Returns a file path after replacing the extension with the specified string.
## If the resulting path with the alternative extension does not exist, an empty string is returned.
## TIP: EXAMPLE: Getting the accompanying `.gd` [Script] for a `.tscn` [Scene] or `.tres` [Resource], IF they share the same file name.
## NOTE: Does NOT rename the actual file.
static func getPathWithDifferentExtension(sourcePath: String, replacementExtension: String) -> String:
	# var sourcePath: String = object.get_script().resource_path
	if sourcePath.is_empty(): return ""

	# First, sanitize the `replacementExtension`
	if not replacementExtension.is_empty() and not replacementExtension.begins_with("."):
		replacementExtension = "." + replacementExtension

	var replacementPath: String = sourcePath.get_basename() + replacementExtension
	Debug.printDebug(str("getPathWithDifferentExtension() sourcePath: ", sourcePath, ", replacementPath: ", replacementPath))

	if FileAccess.file_exists(replacementPath): return replacementPath
	else:
		Debug.printDebug(str("replacementPath does not exist: ", replacementPath))
		return ""
