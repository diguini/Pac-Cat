extends KinematicBody2D

class_name Bot

enum MoveDirection{RIGHT, UP, DOWN, LEFT}

var Dir
var Moving : bool
var target = Vector2()
var velocity = Vector2()
var posOnMap = Vector2()
var Dead = false
export (int) var speed = 400
export (int) var initialSpeed = 400

signal death

var tileSize = Vector2(100, 100)
var halfTileSize = Vector2(50, 50)

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target = position
	rng.randomize()

func setScaleFactor(scale):
	speed= scale * initialSpeed

func _physics_process(delta):
	if Dead:
		return
	velocity = (target - position).normalized() * speed
	if Dir == MoveDirection.RIGHT:
		get_child(0).play("right")
	if Dir == MoveDirection.LEFT:
		get_child(0).play("left")
	elif Dir == MoveDirection.UP:
		get_child(0).play("up")
	elif Dir == MoveDirection.DOWN:
		get_child(0).play("down")
	if (target - position).length() > 10:
		velocity = move_and_slide(velocity)
	else:
		Moving = false
	


func _update(tileOnMap: String, scale: float = 1) -> void:
	if Moving:
		return
	if tileOnMap == "l":
		Dir = MoveDirection.LEFT
	elif tileOnMap == "lud":
		Dir = rng.randi_range(1,3)
	elif tileOnMap == "r":
		Dir = MoveDirection.RIGHT
	elif tileOnMap == "d":
		Dir = MoveDirection.DOWN
	elif tileOnMap == "ld":
		Dir = rng.randi_range(2,3)
	elif tileOnMap == "u":
		Dir = MoveDirection.UP
	elif tileOnMap == "dr":
		var r = rng.randi_range(0,1)
		Dir = 0 if r == 0 else 2
	elif tileOnMap == "rl":
		var r = rng.randi_range(0,1)
		Dir = 0 if r == 0 else 3
	elif tileOnMap == "lu":
		var r = rng.randi_range(1,2)
		Dir = 1 if r == 1 else 3
	elif tileOnMap == "lur":
		var r = rng.randi_range(0,3)
		Dir = r if r == 0 or r == 1 else 3
	elif tileOnMap == "ldr":
		var r = rng.randi_range(0,3)
		Dir = r if r == 0 or r == 2 else 3
	elif tileOnMap == "ru":
		Dir = rng.randi_range(0,1)
	elif tileOnMap == "du":
		Dir = rng.randi_range(1,2)
	elif tileOnMap == "udrl":
		Dir = rng.randi_range(0,3)
	elif tileOnMap == "urd":
		Dir = rng.randi_range(0,2)
	match Dir:
		MoveDirection.RIGHT:
			target = position + tileSize * Vector2.RIGHT
			posOnMap.x+=1
			Moving = true
		MoveDirection.LEFT:
			target = position + tileSize * Vector2.LEFT
			posOnMap.x-=1
			Moving = true
		MoveDirection.UP:
			target = position + tileSize * Vector2.UP
			posOnMap.y-=1
			Moving = true
		MoveDirection.DOWN:
			target = position + tileSize * Vector2.DOWN
			posOnMap.y+=1
			Moving = true
