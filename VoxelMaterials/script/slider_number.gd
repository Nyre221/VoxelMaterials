extends SpinBox

#this synchronize the spinbox value with that of the slider.
func _on_roughness_slider_value_changed(slider_value):
	value = slider_value
