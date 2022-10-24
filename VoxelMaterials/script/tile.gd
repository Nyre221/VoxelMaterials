extends Button

var color setget _set_color
export (int) var tile_number = 0
var n_tile_line
var index_number = 0
var selected = false


func _ready():
	
	connect("button_down",self,"_on_tile_button_down")


#the color is set by the main node
func _set_color(val):
	color = val
	$ColorRect.color = color


func _on_tile_button_down():
	_selection_manager(false)

#here the different cases in which a tile must be selected are managed. 
#a lot of this is due to the multi selection I have implemented.
#drag_selection is the selection with the mouse only (left click pressed)
func _selection_manager(drag_selection = false):
	
	var multi_select_pressed = Input.is_action_pressed("multi_select")
	
	
	if selected and drag_selection:
		return
	if selected and not multi_select_pressed:
		_remove_others_selection()
	elif selected and multi_select_pressed:
		_remove_selection()
	elif not selected and (multi_select_pressed or drag_selection):
		_select()
	elif not selected:
		_select()
		_remove_others_selection()

#(index_number,color,selected) selected is a bool:
#this allows the main node to know if a tile should be eliminated from the list of selected tiles.
func _send_data():
	Global.level_node._new_selection(index_number,color,selected)
	


func _select():
	selected = true
	$selected.show()
	_send_data()

#if this function is called by "_remove_others_selection()", the node that called it reselects itself.
#I did this because it is an easy way to refresh the data (color, etc) in the main node when reselecting
# a single tile that was already selected after a multi selection.
func _remove_selection(from_index_number = null):
	$selected.hide()
	selected = false
	_send_data()
	
	#
	if from_index_number == index_number:
		_select()


func _remove_others_selection():
	get_tree().call_group("tile","_remove_selection",index_number)



#this is done to understand what number this tile is.
#_tile_line_number is called from the parent.
func _tile_line_number(val):
	n_tile_line = val
	index_number = tile_number + ((n_tile_line-1)*8)
	$number.text = String(index_number)



#this is done to understand if the cursor is over the tile and the left button is pressed.
#Global.drag_selection_enabled this variable is set in the main node to understand if the key is initially pressed over the tiles.
#this is done to avoid accidentally selecting the tiles when moving the roughness slider.
#I certainly could have done better here, but I didn't want to waste too much time on it. 
#It's also problematic to do it better because I didn't design it with multi-selection in mind from the start.
func _input(event):
	if Global.drag_selection_enabled == false:
		return
	if not event.is_class("InputEventMouseMotion"):
		return
	if  not Input.is_action_pressed("drag_selection"):
		return
	
	var mouse_pos = get_global_mouse_position()
	var rect_center_point = rect_global_position + (rect_size/2)
	
	if rect_center_point.distance_to(mouse_pos) < 12:
		_selection_manager(true)


#from the main node the loaded palette signal is sent only to index 1.
#this is done to make it autoselect and update the colors when a palette is loaded.
func _on_main_palette_loaded():
	emit_signal("button_down")
