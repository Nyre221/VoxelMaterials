extends ColorRect



#this node and its position serves to separate the area of the color palette from that of the rest of the interface.
#this is done to prevent the tiles from being selected by mistake when the roughness slider is used.
#the related function is located at the end of the script of the main node.
func _ready():
	Global.app_separator = self

