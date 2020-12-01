extends Node2D

var Tile_Type = {
	18 : "dr",
	19 : "udrl",
	20 : "ru",
	21 : "d",
	22 : "du",
	23 : "u",
	24 : "r",
	25 : "rl",
	26 : "l",
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
onready var MapsObj = $Maps
onready var GUI = $CanvasLayer/RichTextLabel
var timer = 0
export(PackedScene) var DogObj
export(PackedScene) var CatObj
export(PackedScene) var MapObj

var Dogs : Array
var Cats : Array
var DeadCats : Array
var Maps : Array

var pause = false

var generations = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in numAgents:
		var newMap = MapObj.instance()
		newMap.position.x = i/3 * 3000
		newMap.position.y = i%3 * 3000
		MapsObj.add_child(newMap)
		Maps.append(newMap.get_children()[0])
		var newCat = CatObj.instance()
		newCat.Dir = MoveDirection.RIGHT
		newCat.position = newMap.get_children()[0].map_to_world(Vector2(11,11)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
		newCat.target = newMap.get_children()[0].map_to_world(Vector2(12,11)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
		newCat.posOnMap = Vector2(11,11)
		newCat.setScaleFactor(scaleFactor)
		#DrawEvents.addToDraw(newCat.position, newCat.target)
		add_child(newCat)
		Cats.append(newCat)
		var dogsInMap = Array()
		for a in numDogsPerMap:
			var newDog = DogObj.instance()
			rng.randomize()
			var random = rng.randi_range(21,24)
			#Somente pode spawnar nas posições 21, 23, 24 e 26
			random = random if random == 21 or random == 23 or random == 24 or random == 26 else 21
			match random:
				21:
					newDog.Dir = MoveDirection.DOWN
				23:
					newDog.Dir = MoveDirection.UP
				24:
					newDog.Dir = MoveDirection.RIGHT
			var SpawnLocations = newMap.get_children()[0].get_used_cells_by_id(random)
			random = rng.randi_range(0, SpawnLocations.size() - 1)
			#Multiplica por tamanho do tile
			newDog.posOnMap = SpawnLocations[random]
			#Soma posição com metade do tamanho do tile para centralizar
			newDog.position = newMap.get_children()[0].map_to_world(Vector2(newDog.posOnMap.x,newDog.posOnMap.y)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
			newDog.setScaleFactor(scaleFactor)
			add_child(newDog)
			dogsInMap.append(newDog)
		Dogs.append(dogsInMap)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if pause:
		return
	timer+=delta
	drawGUI()
	var deadCounts = 0
	for i in Maps.size():
		for a in Dogs[i].size():
			var actualTile = Tile_Type[Maps[i].get_cell(Dogs[i][a].posOnMap.x, Dogs[i][a].posOnMap.y)]
			Dogs[i][a]._update(actualTile, 3)
		if Cats[i].Dead:
			deadCounts+=1
			continue
		if Cats[i].Moving:
			continue
		var actualTile = Maps[i].get_cell(Cats[i].posOnMap.x, Cats[i].posOnMap.y)
		var isEnemyInRange = 0
		var isEnemyOnSide = 0
		for dog in Dogs[i]:
			match Cats[i].Dir:
				MoveDirection.RIGHT:
					if round(dog.posOnMap.y) == round(Cats[i].posOnMap.y):
						isEnemyInRange = 1
					if round(dog.posOnMap.x) == round(Cats[i].posOnMap.x):
						isEnemyOnSide = 1
				MoveDirection.LEFT:
					if round(dog.posOnMap.y) == round(Cats[i].posOnMap.y):
						isEnemyInRange = 1
					if round(dog.posOnMap.x) == round(Cats[i].posOnMap.x):
						isEnemyOnSide = 1
				MoveDirection.UP:
					if round(dog.posOnMap.x) == round(Cats[i].posOnMap.x):
						isEnemyInRange = 1
					if round(dog.posOnMap.y) == round(Cats[i].posOnMap.y):
						isEnemyOnSide = 1
				MoveDirection.DOWN:
					if round(dog.posOnMap.x) == round(Cats[i].posOnMap.x):
						isEnemyInRange = 1
					if round(dog.posOnMap.y) == round(Cats[i].posOnMap.y):
						isEnemyOnSide = 1
#			DrawEvents.clear()
		Cats[i].think(actualTile, isEnemyInRange, isEnemyOnSide)
		#print("think #"+String(i))
		actualTile = Tile_Type[actualTile]
		var sameDir = false
		match Cats[i].Dir:
			MoveDirection.RIGHT:
				if "r" in actualTile:
					Cats[i].target = Maps[i].map_to_world(Vector2(Cats[i].posOnMap.x + 1,Cats[i].posOnMap.y)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
					Cats[i].Moving = true
#						DrawEvents.addToDraw(Cats[i].position, Cats[i].target)
					Cats[i].posOnMap.x += 1
					sameDir = true
			MoveDirection.LEFT:
				if "l" in actualTile:
					Cats[i].target = Maps[i].map_to_world(Vector2(Cats[i].posOnMap.x - 1,Cats[i].posOnMap.y)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
					Cats[i].Moving = true
#						DrawEvents.addToDraw(Cats[i].position, Cats[i].target)
					Cats[i].posOnMap.x -= 1
					sameDir = true
			MoveDirection.UP:
				if "u" in actualTile:
					Cats[i].target = Maps[i].map_to_world(Vector2(Cats[i].posOnMap.x,Cats[i].posOnMap.y - 1)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
					Cats[i].Moving = true
#						DrawEvents.addToDraw(Cats[i].position, Cats[i].target)
					Cats[i].posOnMap.y -= 1
					sameDir = true
			MoveDirection.DOWN:
				if "d" in actualTile:
					Cats[i].target = Maps[i].map_to_world(Vector2(Cats[i].posOnMap.x,Cats[i].posOnMap.y + 1)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
					Cats[i].Moving = true
#						DrawEvents.addToDraw(Cats[i].position, Cats[i].target)
					Cats[i].posOnMap.y += 1
					sameDir = true
		if sameDir:
			return
		match Cats[i].lastDir:
			MoveDirection.UP:
				if "u" in actualTile:
					Cats[i].target = Maps[i].map_to_world(Vector2(Cats[i].posOnMap.x,Cats[i].posOnMap.y - 1)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
					Cats[i].Moving = true
#						DrawEvents.addToDraw(Cats[i].position, Cats[i].target)
					Cats[i].Dir = MoveDirection.UP
					Cats[i].posOnMap.y -= 1
			MoveDirection.DOWN:
				if "d" in actualTile:
					Cats[i].target = Maps[i].map_to_world(Vector2(Cats[i].posOnMap.x,Cats[i].posOnMap.y + 1)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
					Cats[i].Moving = true
#						DrawEvents.addToDraw(Cats[i].position, Cats[i].target)
					Cats[i].Dir = MoveDirection.DOWN
					Cats[i].posOnMap.y += 1
			MoveDirection.RIGHT:
				if "r" in actualTile:
					Cats[i].target = Maps[i].map_to_world(Vector2(Cats[i].posOnMap.x + 1,Cats[i].posOnMap.y)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
					Cats[i].Moving = true
#						DrawEvents.addToDraw(Cats[i].position, Cats[i].target)
					Cats[i].Dir = MoveDirection.RIGHT
					Cats[i].posOnMap.x += 1
			MoveDirection.LEFT:
				if "l" in actualTile:
					Cats[i].target = Maps[i].map_to_world(Vector2(Cats[i].posOnMap.x - 1,Cats[i].posOnMap.y)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
					Cats[i].Moving = true
#						DrawEvents.addToDraw(Cats[i].position, Cats[i].target)
					Cats[i].Dir = MoveDirection.LEFT
					Cats[i].posOnMap.x -= 1
	if deadCounts == numAgents:
		DeadCats = Cats
		for cat in Cats:
			cat.queue_free()
		for i in Maps.size():
			for dog in Dogs[i]:
				dog.queue_free()
		Dogs = []
		Cats = []	
		nextGeneration()

# do a weighted selection of player in order to mutate the fittest
func pick_one():
	var index = 0
	var r = randf()
	
	while r > 0:
		r = r - DeadCats[index].fitness
		index += 1
	index -= 1
	
	var cat = DeadCats[index]
	cat.mutate()
	return cat.duplicate()

func calculate_fitness():
	var sum = 0
	for cat in DeadCats:	
		sum += cat.score
	
	for cat in DeadCats:
		cat.fitness = cat.score / sum


func nextGeneration():
	calculate_fitness()
	for i in range(numAgents):
		var newCat = pick_one()
		newCat.Dir = MoveDirection.RIGHT
		newCat.position = Maps[i].map_to_world(Vector2(11,11)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
		newCat.target = Maps[i].map_to_world(Vector2(12,11)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
		newCat.posOnMap = Vector2(11,11)
		newCat.setScaleFactor(scaleFactor)
		add_child(newCat)
		Cats.append(newCat)
		var dogsInMap = Array()
		for a in numDogsPerMap:
			var newDog = DogObj.instance()
			rng.randomize()
			var random = rng.randi_range(21,24)
			#Somente pode spawnar nas posições 21, 23, 24 e 26
			random = random if random == 21 or random == 23 or random == 24 or random == 26 else 21
			match random:
				21:
					newDog.Dir = MoveDirection.DOWN
				23:
					newDog.Dir = MoveDirection.UP
				24:
					newDog.Dir = MoveDirection.RIGHT
			var SpawnLocations = Maps[i].get_used_cells_by_id(random)
			random = rng.randi_range(0, SpawnLocations.size() - 1)
			#Multiplica por tamanho do tile
			newDog.posOnMap = SpawnLocations[random]
			#Soma posição com metade do tamanho do tile para centralizar
			newDog.position = Maps[i].map_to_world(Vector2(newDog.posOnMap.x,newDog.posOnMap.y)) + halfTileSize + Vector2(i/3 * 3000,i%3 * 3000)
			newDog.setScaleFactor(scaleFactor)
			add_child(newDog)
			dogsInMap.append(newDog)
		Dogs.append(dogsInMap)
	DeadCats = []
	generations+=1
	

func drawGUI():
	GUI.clear()
	GUI.add_text("Época: " + String(generations))
	GUI.newline()
	GUI.add_text("Tempo de Simulação: " + String(timer))
	for i in Cats.size():
		GUI.newline()
		GUI.add_text("Score cat " + String(i) + " : " + String(Cats[i].score))
