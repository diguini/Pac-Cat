extends Node2D

class_name DrawEvents

var draw_list = Array()

func _draw():
	for i in draw_list:
		draw_line(i.pos1,
		i.pos2,
		Color(255, 0, 0), 10)

func clear():
	draw_list.clear()

func addToDraw(pos1 : Vector2, pos2 : Vector2):
	print("pos1: " + String(pos1/101))
	print("pos2: " + String(pos2/101))
	var aux: = DrawObject.new()
	aux.setPos1(pos1)
	aux.setPos2(pos2)
	draw_list.append(aux)
	update()
