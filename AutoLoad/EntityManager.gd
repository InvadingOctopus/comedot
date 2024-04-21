# AutoLoad

extends Node


## Returns all nodes which are in the group "components"
func listAllComponents() -> Array[Node]: # TODO: Change to Array[Component]
	var components: Array[Node] = get_tree().get_nodes_in_group("components")
	print(components)
	return components
