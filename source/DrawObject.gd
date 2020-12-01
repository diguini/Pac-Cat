extends Node

class_name DrawObject

var pos1: = Vector2(0,0)
var pos2: = Vector2(0,0)

func setPos1(pos : Vector2):
	pos1 = pos
	
func setPos2(pos : Vector2):
	pos2 = pos

func getPos1() -> Vector2:
	return pos1
	
func getPos2() -> Vector2:
	return pos2
	
func getVectorAB() -> Vector2:
	return pos2 - pos1
	
func getVectorBA() -> Vector2:
	return pos1 - pos2
	
func getVectorS() -> Vector2:
	return pos1 + pos2
	
func getDir() -> Vector2:
	return pos1.direction_to(pos2).round()
	
