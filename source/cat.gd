extends Bot

class_name Cat

var NeuralNetwork = preload("Neural Network/Brain.gd")
var brain = NeuralNetwork.new(3, 5, 4)
var score = 0.0
var fitness = 0.0
var lastTile
var lastDir
onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Dir = MoveDirection.RIGHT
	lastDir = Dir
	#speed = 400
	Moving = true

# use the neural network to predict the next move
func think(actualTile, isEnemyInView, isEnemyInOnSide):
	var inputs = []
	inputs.append(isEnemyInView)
	inputs.append(isEnemyInOnSide)
	inputs.append(1.0 if lastTile == actualTile else 0)
	
	if lastTile == actualTile:
		score-=10
		if timer.is_stopped():
			timer.start(3)
	else:
		score+=1
		timer.stop()
	lastTile = actualTile
	
	var outputs = brain.predict(inputs)
	
	var action = outputs[0]
	if outputs[1] > action:
		action = outputs[1]
	if outputs[2] > action:
		action = outputs[2]
	if outputs[3] > action:
		action = outputs[3]
	
	if action == outputs[0]:
		move(0)
	elif action == outputs[1]:
		move(1)
	elif action == outputs[2]:
		move(2)
	else:
		move(3)

# apply motion
func _physics_process(delta):
	#score += 1
	pass

func move(dir) -> void:
#	Moving = true
	lastDir = Dir
	Dir = dir
#	_updateP()


func mutate():
	brain.mutate()


func _on_Area2D_body_entered(body: Node) -> void:
	if "Dog" in body.name:
		score-=1000
		get_child(0).play("dead")
		Dead = true
		emit_signal("death", self)


func _on_Timer_timeout() -> void:
	score-=1000
	get_child(0).play("dead")
	Dead = true
	emit_signal("death", self)
