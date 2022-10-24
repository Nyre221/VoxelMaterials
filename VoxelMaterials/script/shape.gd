extends MeshInstance



func _physics_process(delta):
	rotate_y(deg2rad(0.2*delta*60))
