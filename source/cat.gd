extends Bot

class_name Cat

var NeuralNetwork = preload("Neural Network/Brain.gd")
var brain = NeuralNetwork.new(4, 10, 5)
var score = 0.0
var fitness = 0.0
var lastTile
var lastDir
var countRepeatMovement = 0
onready var timer = $TimerByStuck
onready var timer2 = $TimerByRepeat

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Dir = MoveDirection.RIGHT
	lastDir = Dir
	Moving = true
	posOnMap = Vector2(11,11)

#Usa a rede neural com base nos inputs e obtém os outputs
func think(possibleMoves, actualTile, actualPos, isEnemyInView, isEnemyInOnSide1, isEnemyInOnSide2):
	var inputs = []
	#Tudo está em escala de 0-1
	inputs.append(actualTile/37.0)
	inputs.append(isEnemyInView)
	inputs.append(isEnemyInOnSide1)
	inputs.append(isEnemyInOnSide2)
	
	#Mecânica de morrer caso fique parado, se mover ganha recompensa
	if lastTile == actualPos:
		if timer.is_stopped():
			timer.start(1)
	else:
		fitness+=1
		timer.stop()
	lastTile = actualPos
	
	#Obtém os outputs
	var outputs = brain.predict(inputs)
	
	#Verifica qual tem maior peso
	var action = outputs[0]
	if outputs[1] > action:
		action = outputs[1]
	if outputs[2] > action:
		action = outputs[2]
	if outputs[3] > action:
		action = outputs[3]
	if outputs[4] > action:
		action = outputs[4]
	
	#Direita
	if action == outputs[0]:
		#Se a IA tentou fazer um movimento inválido sofre penalização
		if not "r" in possibleMoves:
			fitness-=1
		#Se fez um movimento válido, ganha recompensa
		else:
			fitness+=10
		#Se IA decide ir para outras direções diferente da "básica" é recompensada
		#Incentivo para que ela se mova mais ao longo do mapa
		if Dir == MoveDirection.UP or Dir == MoveDirection.DOWN:
			fitness+=1000
		#Se IA decidi ir "apertar botão desnecessário", pois já está indo para essa direção
		#Sofre penalização
		if lastDir == MoveDirection.RIGHT:
			fitness-=11
		#Caso escolha outra direção e válida ganha recompensa
		else:
			fitness+=10
		#mecânica de morte, para evitar movimentos em Loop
		if Dir == MoveDirection.LEFT and lastDir == MoveDirection.RIGHT:
			countRepeatMovement+=1
			if countRepeatMovement > 3:
				_on_TimerByRepeat_timeout()
		
		print("direita")
		#Diz que próxima direção será a escolhida
		move(0)
	#Cima
	elif action == outputs[1]:
		#Se a IA tentou fazer um movimento inválido sofre penalização
		if not "u" in possibleMoves:
			fitness-=1
		#Se fez um movimento válido, ganha recompensa
		else:
			fitness+=10
		#Se IA decide ir para outras direções diferente da "básica" é recompensada
		#Incentivo para que ela se mova mais ao longo do mapa
		if Dir == MoveDirection.RIGHT or Dir == MoveDirection.LEFT:
			fitness+=1000
		#Se IA decidi ir "apertar botão desnecessário", pois já está indo para essa direção
		#Sofre penalização
		if lastDir == MoveDirection.UP:
			fitness-=11
		else:
		#Caso escolha outra direção e válida ganha recompensa
			fitness+=10
		#mecânica de morte, para evitar movimentos em Loop
		if Dir == MoveDirection.DOWN and lastDir == MoveDirection.UP:
			countRepeatMovement+=1
			if countRepeatMovement > 3:
				_on_TimerByRepeat_timeout()
		print("cima")
		#Diz que próxima direção será a escolhida
		move(1)
	#Baixo
	elif action == outputs[2]:
		#Se a IA tentou fazer um movimento inválido sofre penalização
		if not "d" in possibleMoves:
			fitness-=1
		#Se fez um movimento válido, ganha recompensa
		else:
			fitness+=10
		#Se IA decide ir para outras direções diferente da "básica" é recompensada
		#Incentivo para que ela se mova mais ao longo do mapa
		if Dir == MoveDirection.RIGHT or Dir == MoveDirection.LEFT:
			fitness+=1000
		#Se IA decidi ir "apertar botão desnecessário", pois já está indo para essa direção
		#Sofre penalização
		if lastDir == MoveDirection.DOWN:
			fitness-=11
		#Caso escolha outra direção e válida ganha recompensa
		else:
			fitness+=10
		#mecânica de morte, para evitar movimentos em Loop
		if Dir == MoveDirection.UP and lastDir == MoveDirection.DOWN:
			countRepeatMovement+=1
			if countRepeatMovement > 3:
				_on_TimerByRepeat_timeout()
		print("baixo")
		#Diz que próxima direção será a escolhida
		move(2)
	#Esquerda
	elif action == outputs[3]:
		#Se a IA tentou fazer um movimento inválido sofre penalização
		if not "l" in possibleMoves:
			fitness-=1
		#Se fez um movimento válido, ganha recompensa
		else:
			fitness+=10
		#Se IA decide ir para outras direções diferente da "básica" é recompensada
		#Incentivo para que ela se mova mais ao longo do mapa
		if Dir == MoveDirection.UP or Dir == MoveDirection.DOWN:
			fitness+=1000
		#Se IA decidi ir "apertar botão desnecessário", pois já está indo para essa direção
		#Sofre penalização
		if lastDir == MoveDirection.LEFT:
			fitness-=11
		#Caso escolha outra direção e válida ganha recompensa
		else:
			fitness+=10
		#mecânica de morte, para evitar movimentos em Loop
		if Dir == MoveDirection.RIGHT and lastDir == MoveDirection.LEFT:
			countRepeatMovement+=1
			if countRepeatMovement > 3:
				_on_TimerByRepeat_timeout()
		print("esquerda")
		#Diz que próxima direção será a escolhida
		move(3)
	#Não faz nada
	else:
		print("Espera")
		move(4)

# apply motion
func _physics_process(delta):
	#score += 1
	pass

#Função que muda direção
func move(dir) -> void:
	if dir == 4:
		return
	if not lastDir == Dir:
			lastDir = Dir
	Dir = dir


func mutate():
	brain.mutate()

#Função de morte e penalização
func setDeath():
	fitness-=1000
	get_child(0).play("dead")
	Dead = true
	emit_signal("death", self)

#Caso colida com cachorro
func _on_Area2D_body_entered(body: Node) -> void:
	if "Dog" in body.name and not Dead:
		#score-=100000
		setDeath()

#Função para caso morra por mecânica de ficar preso
func _on_Timer_timeout() -> void:
	if not Dead:
		print("morte por ficar preso")
		setDeath()

#Função para caso morra por mecânica de loop de movimento
func _on_TimerByRepeat_timeout() -> void:
	if not Dead:
		print("morte por repetição de movimento")
		setDeath()
