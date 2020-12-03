extends Node2D

var Tile_Type = {
	18 : "dr",
	19 : "udrl",
	20 : "ru",
	21 : "d",
	22 : "u",
	23 : "r",
	24 : "l",
	25 : "du",
	26 : "rl",
	27 : "ld",
	28 : "udrl",
	29 : "udrl",
	30 : "udrl",
	31 : "lu",
	32 : "udrl",
	33 : "b",
	34 : "lur",
	35 : "ldr",
	36 : "lud",
	37 : "urd"
}

enum MoveDirection{RIGHT, UP, DOWN, LEFT}

class_name Game

export var numAgents = 9
export var numDogsPerMap = 3
export var scaleFactor = 1.0

var tileSize = Vector2(100, 100)
var halfTileSize = Vector2(50, 50)

var rng = RandomNumberGenerator.new()

onready var DrawEvents = $DrawEvents
onready var GUI = $CanvasLayer/RichTextLabel
onready var timerForNewG = $TimerForNewGeneration
var timer = 0
export(PackedScene) var DogObj
export(PackedScene) var CatObj
export(PackedScene) var MapObj

var Dogs : Array
var Cats : Array
var DeadCats : Array
var Map

var pause = false

var generations = 1

var bestFitness = -999999
var bestFitnessInGeneration = -999999
var bestCat = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var newMap = MapObj.instance()
	add_child(newMap)
	Map = newMap.get_children()[0]
	for i in numAgents:
		var newCat = CatObj.instance()
		newCat.setScaleFactor(scaleFactor)
		add_child(newCat)
		Cats.append(newCat)
		newCat.position = newMap.get_children()[0].map_to_world(Vector2(11,11)) + halfTileSize
		newCat.target = newMap.get_children()[0].map_to_world(Vector2(12,11)) + halfTileSize
	rng.randomize()
	for a in numDogsPerMap:
		var newDog = DogObj.instance()
		var random = rng.randi_range(21,24)
		match random:
			21:
				newDog.Dir = MoveDirection.DOWN
			22:
				newDog.Dir = MoveDirection.UP
			23:
				newDog.Dir = MoveDirection.RIGHT
			24:
				newDog.Dir = MoveDirection.LEFT
		#var cells = newMap.get_children()[0].get_cell(16,11)
		var SpawnLocations = newMap.get_children()[0].get_used_cells_by_id(random)
		random = rng.randi_range(0, SpawnLocations.size() - 1)
		#Multiplica por tamanho do tile
		newDog.posOnMap = SpawnLocations[random]
		#Soma posição com metade do tamanho do tile para centralizar
		newDog.position = newMap.get_children()[0].map_to_world(Vector2(newDog.posOnMap.x,newDog.posOnMap.y)) + halfTileSize
		newDog.setScaleFactor(scaleFactor)
		add_child(newDog)
		Dogs.append(newDog)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if pause:
		return
	timer+=delta
	drawGUI()
	var deadCounts = 0
	for dog in Dogs:
		var actualTile = Tile_Type[Map.get_cell(dog.posOnMap.x, dog.posOnMap.y)]
		dog._update(actualTile)
	for cat in Cats:
		if cat.Dead:
			deadCounts+=1
			continue
		if cat.Moving:
			continue
		var isEnemyInRange = 0
		var isEnemyOnSide1 = 0
		var isEnemyOnSide2 = 0
		var enemyRange = 2
		for dog in Dogs:
			#Vetores de distância entre gato e cachorro
			var distXA = dog.posOnMap.x - cat.posOnMap.x
			var distXB = cat.posOnMap.x - dog.posOnMap.x
			var distYA = dog.posOnMap.y - cat.posOnMap.y
			var distYB = cat.posOnMap.y - dog.posOnMap.y
			#Verifica distância com base para onde o gato está olhando
			match cat.Dir:
				MoveDirection.RIGHT:
					if dog.posOnMap.y == cat.posOnMap.y and distXA > 0 and distXA < enemyRange:
						isEnemyInRange = 1
					if dog.posOnMap.x == cat.posOnMap.x and distYA > 0 and distYA < enemyRange:
						isEnemyOnSide1 = 1
					if dog.posOnMap.x == cat.posOnMap.x and distYB > 0 and distYB < enemyRange:
						isEnemyOnSide2 = 1
				MoveDirection.LEFT:
					if dog.posOnMap.y == cat.posOnMap.y and distXB > 0 and distXB < enemyRange:
						isEnemyInRange = 1
					if dog.posOnMap.x == cat.posOnMap.x and distYA > 0 and distYA < enemyRange:
						isEnemyOnSide1 = 1
					if dog.posOnMap.x == cat.posOnMap.x and distYB > 0 and distYB < enemyRange:
						isEnemyOnSide2 = 1
				MoveDirection.UP:
					if dog.posOnMap.x == cat.posOnMap.x and distYB > 0 and distYB < enemyRange:
						isEnemyInRange = 1
					if dog.posOnMap.y == cat.posOnMap.y and distXA > 0 and distXA < enemyRange:
						isEnemyOnSide1 = 1
					if dog.posOnMap.y == cat.posOnMap.y and distXB > 0 and distXB < enemyRange:
						isEnemyOnSide2 = 1
				MoveDirection.DOWN:
					if dog.posOnMap.x == cat.posOnMap.x and distYA > 0 and distYA < enemyRange:
						isEnemyInRange = 1
					if dog.posOnMap.y == cat.posOnMap.y and distXA > 0 and distXA < enemyRange:
						isEnemyOnSide1 = 1
					if dog.posOnMap.y == cat.posOnMap.y and distXB > 0 and distXB < enemyRange:
						isEnemyOnSide2 = 1
		#Pega o tile atual para saber as possíveis posições de movimentação
		var actualTile = Map.get_cell(cat.posOnMap.x, cat.posOnMap.y)
		var possibleMove = Tile_Type[actualTile]
		#Executa pensamento, passando inputs e obtendo outputs
		cat.think(possibleMove, actualTile, cat.posOnMap, isEnemyInRange, isEnemyOnSide1, isEnemyOnSide2)
		#Para mecânica de não parar de mover caso a IA faça um output inválido
		var sameDir = false
		match cat.Dir:
			MoveDirection.RIGHT:
				if "r" in possibleMove:
					cat.target = Map.map_to_world(Vector2(cat.posOnMap.x + 1,cat.posOnMap.y)) + halfTileSize
					cat.Moving = true
					cat.posOnMap.x += 1
					sameDir = true
			MoveDirection.LEFT:
				if "l" in possibleMove:
					cat.target = Map.map_to_world(Vector2(cat.posOnMap.x - 1,cat.posOnMap.y)) + halfTileSize
					cat.Moving = true
					cat.posOnMap.x -= 1
					sameDir = true
			MoveDirection.UP:
				if "u" in possibleMove:
					cat.target = Map.map_to_world(Vector2(cat.posOnMap.x,cat.posOnMap.y - 1)) + halfTileSize
					cat.Moving = true
					cat.posOnMap.y -= 1
					sameDir = true
			MoveDirection.DOWN:
				if "d" in possibleMove:
					cat.target = Map.map_to_world(Vector2(cat.posOnMap.x,cat.posOnMap.y + 1)) + halfTileSize
					cat.Moving = true
					cat.posOnMap.y += 1
					sameDir = true
		if sameDir:
			return
		match cat.lastDir:
			MoveDirection.UP:
				if "u" in possibleMove:
					cat.target = Map.map_to_world(Vector2(cat.posOnMap.x,cat.posOnMap.y - 1)) + halfTileSize
					cat.Moving = true
					cat.Dir = MoveDirection.UP
					cat.posOnMap.y -= 1
			MoveDirection.DOWN:
				if "d" in possibleMove:
					cat.target = Map.map_to_world(Vector2(cat.posOnMap.x,cat.posOnMap.y + 1)) + halfTileSize
					cat.Moving = true
					cat.Dir = MoveDirection.DOWN
					cat.posOnMap.y += 1
			MoveDirection.RIGHT:
				if "r" in possibleMove:
					cat.target = Map.map_to_world(Vector2(cat.posOnMap.x + 1,cat.posOnMap.y)) + halfTileSize
					cat.Moving = true
					cat.Dir = MoveDirection.RIGHT
					cat.posOnMap.x += 1
			MoveDirection.LEFT:
				if "l" in possibleMove:
					cat.target = Map.map_to_world(Vector2(cat.posOnMap.x - 1,cat.posOnMap.y)) + halfTileSize
					cat.Moving = true
					cat.Dir = MoveDirection.LEFT
					cat.posOnMap.x -= 1
	if deadCounts == numAgents:
		if timerForNewG.is_stopped():
			timerForNewG.start(3)

# Pega o melhor gato da geração passada e clona ele com mutação
func pick_one():
	var cat = bestCat
	cat.mutate()
	return cat.duplicate()

#Calculo alterado para diretamente dentro da classe cat
func calculate_fitness():
	pass

func nextGeneration():
	#calculate_fitness()
	for i in range(numAgents):
		#Clona o melhor gato e faz mutação
		var newCat = pick_one()
		newCat.setScaleFactor(scaleFactor)
		add_child(newCat)
		Cats.append(newCat)
		newCat.position = Map.map_to_world(Vector2(11,11)) + halfTileSize
		newCat.target = Map.map_to_world(Vector2(12,11)) + halfTileSize
	for a in numDogsPerMap:
		var newDog = DogObj.instance()
		var random = rng.randi_range(21,24)
		match random:
			21:
				newDog.Dir = MoveDirection.DOWN
			22:
				newDog.Dir = MoveDirection.UP
			23:
				newDog.Dir = MoveDirection.RIGHT
			24:
				newDog.Dir = MoveDirection.LEFT
		var SpawnLocations = Map.get_used_cells_by_id(random)
		random = rng.randi_range(0, SpawnLocations.size() - 1)
		#Multiplica por tamanho do tile
		newDog.posOnMap = SpawnLocations[random]
		#Soma posição com metade do tamanho do tile para centralizar
		newDog.position = Map.map_to_world(Vector2(newDog.posOnMap.x,newDog.posOnMap.y)) + halfTileSize
		newDog.setScaleFactor(scaleFactor)
		add_child(newDog)
		Dogs.append(newDog)
	DeadCats = []
	generations+=1
	

#Função auxiliar para mostrar valores
func drawGUI():
	GUI.clear()
	GUI.add_text("Melhor Fitness: " + String(bestFitness))
	GUI.newline()
	GUI.add_text("Melhor Fitness na geração passada: " + String(bestFitnessInGeneration))
	GUI.newline()
	GUI.add_text("Época: " + String(generations))
	GUI.newline()
	GUI.add_text("Tempo de Simulação: " + String(timer))
	for i in Cats.size():
		GUI.newline()
		GUI.add_text("Fitness cat " + String(i) + " : " + String(Cats[i].fitness))

#Cria nova geração em X tempo após todos os gatinhos perderem
func _on_TimerForNewGeneration_timeout() -> void:
	DeadCats = Cats
	bestFitnessInGeneration = -999999
	for cat in Cats:
		if cat.fitness > bestFitness:
			bestFitness = cat.fitness
			bestCat = cat.duplicate()
		if cat.fitness > bestFitnessInGeneration:
			bestFitnessInGeneration = cat.fitness
		cat.queue_free()
	for dog in Dogs:
		dog.queue_free()
	Dogs = []
	Cats = []	
	nextGeneration()
