extends HBoxContainer


export (int) var tile_line = 0
signal n_tile_line


#when the node is ready it sends its line number to the children. 
#this is done in order to make the children understand what their number is in the index.
func _ready():
	for c in get_children():
		connect("n_tile_line",c,"_tile_line_number")
	
	emit_signal("n_tile_line",tile_line)
