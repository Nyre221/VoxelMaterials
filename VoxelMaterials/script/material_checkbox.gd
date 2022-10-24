extends CheckBox


signal selected
var set_only_status = false

#this is used to set the current status of the checkbox without sending the signal to the main node.
# Without this I had problems with double entries in the lists.
func _set_status(val):
	set_only_status = true
	pressed = val
#	yield(get_tree(),"idle_frame")
	set_only_status = false

func _on_material_checkbox_toggled(button_pressed):
	#selected is not emitted if i'm only changing the status.
	if not set_only_status:
		emit_signal("selected",button_pressed)
