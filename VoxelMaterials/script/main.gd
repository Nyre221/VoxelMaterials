extends Control

export (Material) var shape_material :Material
var color_list :Array
var img
var metal_list :Array
var emissive_list :Array
var glass_list :Array
var current_index_list :Array= []
var current_index = 0
var last_user_dir="/"
var settings_file="user://settings.txt"
var current_color = Color(1,1,1,1)
var img_selected = false

var roughness_list:Dictionary
onready var roughness_number = $container/info/roughness/roughness_number
onready var emissive_number = $container/info/emissive/emissive_number
onready var metal_number = $container/info/metal/metal_number
onready var glass_number = $container/info/glass/glass_number
onready var roughness_slider = $container/info/roughness/roughness_slider
onready var glass_checkbox = $container/info/glass/glass_checkbox
onready var emissive_checkbox = $container/info/emissive/emissive_checkbox
onready var metal_checkbox = $container/info/metal/metal_checkbox
onready var index_number_label = $container/info/header/number
var internal_materials_file = "user://materials.txt"
signal palette_loaded


func _ready():
#	TranslationServer.set_locale("en")
	_load_last_user_dir()
	_load(internal_materials_file)
	_set_current_directory()
	$stop.show()
	$PaletteDialog.popup()
	Global.level_node = self


func _gen_palette():
	img.lock()
	var tile_line = $container/grid.get_children()
#this is the simplest way to have the index numbers arranged like in magicavoxel:
# divide into rows and then invert.
	tile_line.invert()
	
# here I get the colors from each pixel.
	for n in 256:
		color_list.append(img.get_pixel(n,0))
	
	
# because they are divided into rows I have to do 32*8 loop to apply all the colors to the tiles.
	for tile in 32:
		var child = tile_line[tile].get_children()
		for c in child:
			c.color = color_list[0]
			color_list.pop_front()
			
#the palette_loaded signal is sent to make the first tile in the index autoselect.
# and update the info.
	emit_signal("palette_loaded")



#set the current path for the file dialog.
func _set_current_directory():
	for d in get_tree().get_nodes_in_group("dialog"):
		d.current_path = last_user_dir+"/"



#is called from the tile when they get selected
func _new_selection(index_number,color,selected):
	if selected:
		current_index_list.append(index_number)
		current_color = color
		current_index = index_number
	else:
		current_index_list.erase(index_number)
		
	_check_status()



##something i use like an update function.
#this function check the current state of the materials and call the funcion _set_info() to update the information on screen.
func _check_status():
	
	var is_metal = String(current_index) in metal_list
	var is_emissive = String(current_index) in emissive_list
	var is_glass = String(current_index) in glass_list
	var roughness_setted = roughness_list.has(String(current_index))
	_set_info(is_metal,is_emissive,is_glass,roughness_setted)
	_save(internal_materials_file)

func _set_info(is_metal,is_emissive,is_glass,roughness_setted):
	# the list is sorted for better reading the number in the interface.
	metal_list.sort()
	emissive_list.sort()
	glass_list.sort()
	#here the text is assigned
	metal_number.text = String(metal_list)
	metal_number.hint_tooltip = String(metal_list)
	
	emissive_number.text = String(emissive_list)
	emissive_number.hint_tooltip = String(emissive_list)
	
	glass_number.text = String(glass_list)
	glass_number.hint_tooltip = String(glass_list)
	
	
	
# i create an array in order to sort the list.
# this is the only way i know to sort dictionary data.
	var roughness_data:Array
	for r in roughness_list:
		roughness_data.append(r+":"+String(roughness_list[r]))
	roughness_data.sort()
	roughness_number.text = String(roughness_data)
	roughness_number.hint_tooltip = String(roughness_list)
	
	#here the color of the spatial material and the current index number is setted
	shape_material.set("albedo_color",current_color)
	index_number_label.text = String(current_index_list)
	
	#here is where the spatial material settings for the cube and the slider/checkbox status are setted.
	_set_metal(is_metal)
	_set_emissive(is_emissive)
	_set_glass(is_glass)
	_set_roughness(roughness_setted)


#here is where the spatial material settings for the cube and the slider/checkbox status are setted.
func _set_metal(is_metal):
	metal_checkbox._set_status(is_metal)
	shape_material.set("metallic",is_metal)

func _set_emissive(is_emissive):
	emissive_checkbox._set_status(is_emissive)
	if is_emissive:
		shape_material.set("emission",current_color)
	else:
		shape_material.set("emission",Color(0,0,0,0))

func _set_glass(is_glass):
	glass_checkbox._set_status(is_glass)
	var new_color = current_color
	new_color.a = 0.8
	if is_glass:
		shape_material.set("albedo_color",new_color)
	else:
		shape_material.set("albedo_color",current_color)

func _set_roughness(is_setted):
	var value = 1
	if is_setted:
		value = roughness_list[String(current_index)]
	else:
		value = 1
	shape_material.set("roughness",value)
	roughness_slider._set_status(value * 100)








# _add_remove_material is called and the list to be modified is passed to it as an argument.
# button_press is used to tell if it should be removed or added to the list.
func _on_metal_checkbox_selected(button_pressed):
	metal_list = _add_remove_material(button_pressed,metal_list)

func _on_emissive_checkbox_selected(button_pressed):
	emissive_list = _add_remove_material(button_pressed,emissive_list)

func _on_glass_checkbox_selected(button_pressed):
	glass_list = _add_remove_material(button_pressed,glass_list)





#function to add or remove a material from the list of modified materials.
#roughness is not handled here.
func _add_remove_material(button_pressed,list):
	if button_pressed:
		for i in current_index_list:
			if not i in list:
				list.append(String(i))
	else:
		for i in current_index_list:
			list.erase(String(i))
	_check_status()
	return list


func _on_roughness_slider_value_selected(value):
	#the values are added or removed from the roughness_list (modified materials list)
	for i in current_index_list:
		#the value is converted to a string to make it work better with the save system.
		roughness_list[String(i)] = value/100
	if value == 100:
		for i in current_index_list:
			roughness_list.erase(String(i))
	#check_status() update the info.
	_check_status()









#save and load functions
func _save_last_user_dir():
	var save_file = File.new()
	var error = save_file.open(settings_file,File.WRITE)
	if error == OK:
		save_file.store_line(JSON.print(last_user_dir))
		save_file.close()
	else:
		print("error")

func _load_last_user_dir():
	var save_file = File.new()
	if save_file.file_exists(settings_file):
		var error = save_file.open(settings_file,File.READ)
		if error == OK:
			last_user_dir = JSON.parse(save_file.get_line()).result
			save_file.close()


#I decided to save as text strings because I wanted the saved document to be readable directly by users as well.
#this unfortunately involved converting all the numbers in the dictionary to a string.
func _save(path):
	var save_file = File.new()
	var error = save_file.open(path,File.WRITE)
	if error == OK:
		save_file.store_line(JSON.print(metal_list))
		save_file.store_line(JSON.print(emissive_list))
		save_file.store_line(JSON.print(glass_list))
		save_file.store_line(JSON.print(roughness_list))
		save_file.close()
	else:
		print("error")

#I decided to save as text strings because I wanted the saved document to be readable directly by users as well.
func _load(path):
	var save_file = File.new()
	if save_file.file_exists(path):
		var error = save_file.open(path,File.READ)
		if error == OK:
			var data1 = JSON.parse(save_file.get_line()).result
			var data2 = JSON.parse(save_file.get_line()).result
			var data3 = JSON.parse(save_file.get_line()).result
			var data4 = JSON.parse(save_file.get_line()).result
			#check if the data is corrupted
			#saving strings is a very bad way to save data
			if typeof(data1) == TYPE_ARRAY:
				metal_list = data1
			if typeof(data2) == TYPE_ARRAY:
				emissive_list = data2
			if typeof(data3) == TYPE_ARRAY:
				glass_list = data3
			if typeof(data4) == TYPE_DICTIONARY:
				roughness_list = data4
			
			save_file.close()
		else:
			print("error")
	
	# _check_status() is called to make the info update.
	_check_status()







#here the maps are created
func _gen_metal_map(path):
	var metal_img = Image.new()
	metal_img.copy_from(img)
	metal_img.lock()

	for n in 256:
		if String(n+1)  in metal_list:
			metal_img.set_pixel(n,0,Color(1,1,1,1))
		else:
			metal_img.set_pixel(n,0,Color(0,0,0,1))
	metal_img.save_png(path)

func _gen_emissive_map(path):
	var emissive_img = Image.new()
	emissive_img.copy_from(img)
	emissive_img.lock()
	for n in 256:
		if not String(n+1)  in emissive_list:
			emissive_img.set_pixel(n,0,Color(0,0,0,1))
	emissive_img.save_png(path)

func _gen_glass_map(path):

	var glass_img_1 = Image.new()
	glass_img_1.copy_from(img)
	glass_img_1.lock()

	for n in 256:
		if String(n+1)  in glass_list:
			glass_img_1.set_pixel(n,0,Color(1,1,1,0))
	glass_img_1.save_png(path + "-glass_less.png")
	
# second part
	var glass_img_2 = Image.new()
	glass_img_2.copy_from(img)
	glass_img_2.lock()
	for n in 256:
		if not String(n+1)  in glass_list:
			glass_img_2.set_pixel(n,0,Color(1,1,1,0))
	glass_img_2.save_png(path + "-glass-only.png")

func _gen_roughness_map(path):
	var roughness_img = Image.new()
	roughness_img.copy_from(img)
	roughness_img.lock()
	for n in 256:
		if String(n+1)  in roughness_list.keys():
			var roughness_color = roughness_list[String(n+1)]
			roughness_img.set_pixel(n,0,Color(roughness_color,roughness_color,roughness_color,1))
		else:
			roughness_img.set_pixel(n,0,Color(1,1,1,1))
	roughness_img.save_png(path)



#here is managed what needs to be done after pressing the clear and bottom button.
func _on_import_palette_pressed():
	$PaletteDialog.popup()

func _on_clear_all_button_down():
	metal_list.clear()
	emissive_list.clear()
	glass_list.clear()
	roughness_list.clear()
	
	_check_status()

func _on_export_metal_button_down():
	$MetalDialog.popup()

func _on_export_emission_button_down():
	$EmissiveDialog.popup()

func _on_export_glass_button_down():
	$glass_confirmation.popup()

func _on_export_roughness_button_down():
	$RoughnessDialog.popup()

func _on_import_mapping_button_down():
	$import_map_Dialog.popup()


func _on_current_mapping_button_down():
	$Save_map_Dialog.popup()

func _on_glass_confirmation_confirmed():
	$GlassDialog.popup()







#here is managed what needs to be done after selecting a file or folder.
#if path.get_basename().strip_edges(false,true) == (path.get_base_dir()+"/"):
#it is used to prevent the user from not giving a name.
func _on_PaletteDialog_file_selected(path):
	var source = Image.new()
	source.load(path)
	#check if the image is correct
	if not source.get_size() == Vector2(256,1):
		
		return
	$stop.hide()
	img_selected = true

	var t = ImageTexture.new()

	t.create_from_image(source)
	img  = t.get_data()
	
	last_user_dir=path.get_base_dir()
	_save_last_user_dir()
	_set_current_directory()
	_gen_palette()

func _on_MetalDialog_file_selected(path):
	if path.get_basename().strip_edges(false,true) == (path.get_base_dir()+"/"):
		yield(get_tree(),"idle_frame")
		$MetalDialog.popup()
		return
		
	_gen_metal_map(path)

func _on_EmissiveDialog_file_selected(path):
	if path.get_basename().strip_edges(false,true) == (path.get_base_dir()+"/"):
		yield(get_tree(),"idle_frame")
		$EmissiveDialog.popup()
		return
	_gen_emissive_map(path)

func _on_RoughnessDialog_file_selected(path):
	if path.get_basename().strip_edges(false,true) == (path.get_base_dir()+"/"):
		yield(get_tree(),"idle_frame")
		$RoughnessDialog.popup()
		return
	_gen_roughness_map(path)

func _on_GlassDialog_file_selected(path):
	if path.get_basename().strip_edges(false,true) == (path.get_base_dir()+"/"):
		yield(get_tree(),"idle_frame")
		$GlassDialog.popup()
		return
	_gen_glass_map(path)


func _on_Save_map_Dialog_file_selected(path):
	if path.get_basename().strip_edges(false,true) == (path.get_base_dir()+"/"):
		yield(get_tree(),"idle_frame")
		$Save_map_Dialog.popup()
		return
	_save(path)


func _on_import_map_Dialog_file_selected(path):
	_load(path)



#this is to prevent the file dialog from closing at the beginning when the program is opened.
#I know there is an option in the settings but it doesn't work when the "cancel" button is pressed.
#I did this because the user has to be forced to select a color palette.
func _on_PaletteDialog_hide():
	if not img_selected:
		$PaletteDialog.show()




#here it is calculated if the cursor has been pressed outside the tile area (based on the position of the separator).
#this is done to prevent the tiles from being selected by mistake when the roughness slider is used.
func _input(event):
	if event.is_action_pressed("drag_selection"):
		Global.drag_selection_enabled = Global.app_separator.rect_global_position.x > get_global_mouse_position().x
