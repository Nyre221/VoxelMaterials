extends HSlider

signal value_selected
var set_only_status = false

#value_selected is the signal connected to the main node


#this is used to set the current value of the slider without sending the signal to the main node.
# Without this I had problems with double entries in the lists.
func _set_status(val):
	set_only_status = true
	value = val
	set_only_status = false

#this synchronize the spinbox value with that of the slider.
#for some reason doing it directly with a signal in this case does not create problems with double entries in the lists.
func _on_slider_number_value_changed(number_value):
	value = number_value


func _on_roughness_slider_value_changed(value):
	#value_selected is not emitted if i'm only changing the status.
	if not set_only_status:
		emit_signal("value_selected",value)
