extends Camera2D

export var cameraSpeed = 20.0
export var zoomSpeed = 0.1

func _physics_process(delta):
	if Input.is_action_pressed('ui_right'):
		position.x+=cameraSpeed
	if Input.is_action_pressed('ui_left'):
		position.x-=cameraSpeed
	if Input.is_action_pressed('ui_up'):
		position.y-=cameraSpeed
	if Input.is_action_pressed('ui_down'):
		position.y+=cameraSpeed
	if Input.is_action_pressed('zoomIn') or Input.is_action_just_released('zoomIn'):
		zoom.x-=zoomSpeed
		zoom.y-=zoomSpeed
	if Input.is_action_pressed('zoomOut') or Input.is_action_just_released('zoomOut'):
		zoom.x+=zoomSpeed
		zoom.y+=zoomSpeed
