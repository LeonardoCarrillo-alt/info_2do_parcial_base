extends Node2D

# state machine
enum {WAIT, MOVE}
var state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int
@export var score_label: Label
@export var counter_label: Label
@export var is_explosive = true

#var score: int = 12
var moves_left: int = 30

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]
# special pieces
var special_pieces = [
	preload("res://scenes/special_blue_piece.tscn"),
	preload("res://scenes/special_green_piece.tscn"),
	preload("res://scenes/special_light_green_piece.tscn"),
	preload("res://scenes/special_orange_piece.tscn"),
	preload("res://scenes/special_pink_piece.tscn"),
	preload("res://scenes/special_yellow_piece.tscn")
	
]
# explosive pieces
var explosive_pieces = [
	preload("res://scenes/special_blue_piece.tscn"),
	preload("res://scenes/special_green_piece.tscn"),
	preload("res://scenes/special_light_green_piece.tscn"),
	preload("res://scenes/special_orange_piece.tscn"),
	preload("res://scenes/special_pink_piece.tscn"),
	preload("res://scenes/special_yellow_piece.tscn")
	
]
var special_piece_i = {
	"blue": 0,		#special blue
	"green": 1,      # special green
	"light_green": 2, # special light green
	"orange": 3,     # special orange
	"pink": 4,       # special pink
	"yellow": 5     # special yellow
}
var explosive_piece_i = {
	"blue": 0,		#special blue
	"green": 1,      # special green
	"light_green": 2, # special light green
	"orange": 3,     # special orange
	"pink": 4,       # special pink
	"yellow": 5     # special yellow
}

# current pieces in scene
var all_pieces = []

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false

# scoring variables and signals
#score vars and signal
var score = 0
var score_final = 0
signal score_changed(new_score)

# time vars and signal
var time = 120 
var time_passed = 0 
var time_left = time 
signal time_changed(new_time)
# counter variables and signals
# movements vars
var movement = 20
signal movements_changed(new_moves)
func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	emit_signal("movements_changed", movement)
	start_timer()
	
# Inicializar los valores
	
func start_timer():
	var timer_label = get_parent().get_node("MarginContainer/HBoxContainer/time_label")
	if timer_label:
		timer_label.text = str(time_left) 

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height
	
func spawn_pieces():
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() -1)
			# instance 
			var piece = possible_pieces[rand].instantiate()
			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() -1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true

func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
	# swap
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	#first_piece.position = grid_to_pixel(column + direction.x, row + direction.y)
	#other_piece.position = grid_to_pixel(column, row)
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	if not move_checked:
		find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if state == MOVE:
		touch_input()
		time_passed += delta
	if time_passed >= 1:
		time_left -= 1
		emit_signal("time_changed", time_left)
		time_passed = 0
		check_game_over()

func find_matches():
	var matches_found = false

	for i in width:
		for j in height:
			var piece = all_pieces[i][j]
			if piece == null:
				continue

			var color = piece.color

			# ---------------- HORIZONTAL ----------------
			var hor_match = [Vector2(i,j)]
			var x = i - 1
			while x >= 0 and all_pieces[x][j] != null and all_pieces[x][j].color == color:
				hor_match.append(Vector2(x, j))
				x -= 1
			x = i + 1
			while x < width and all_pieces[x][j] != null and all_pieces[x][j].color == color:
				hor_match.append(Vector2(x, j))
				x += 1

			# ---------------- VERTICAL ----------------
			var ver_match = [Vector2(i,j)]
			var y = j - 1
			while y >= 0 and all_pieces[i][y] != null and all_pieces[i][y].color == color:
				ver_match.append(Vector2(i, y))
				y -= 1
			y = j + 1
			while y < height and all_pieces[i][y] != null and all_pieces[i][y].color == color:
				ver_match.append(Vector2(i, y))
				y += 1

			# ---------------- MARCAR MATCHES ----------------
			var hor_count = hor_match.size()
			var ver_count = ver_match.size()

			if hor_count >= 3:
				for pos in hor_match:
					var p = all_pieces[pos.x][pos.y]
					if p != null:
						p.matched = true
						p.dim()
				matches_found = true

			if ver_count >= 3:
				for pos in ver_match:
					var p = all_pieces[pos.x][pos.y]
					if p != null:
						p.matched = true
						p.dim()
				matches_found = true

			# ---------------- SPECIAL PIECE ----------------
			if hor_count == 4 or ver_count == 4:
				create_special_piece(Vector2(i,j), color)

			# ---------------- EXPLOSIVE PIECE ----------------
			if hor_count >= 3 and ver_count >= 3:
				create_explosive_piece(Vector2(i,j), color)

	if matches_found:
		get_parent().get_node("destroy_timer").start()
	else:
		swap_back()

func create_explosive_piece(position: Vector2, color: String):
	if (color in explosive_piece_i): 
		var explosive_i = explosive_piece_i[color]
		var explosive_piece = explosive_pieces[explosive_i].instantiate()
		add_child(explosive_piece)
		explosive_piece.position = grid_to_pixel(position.x, position.y)
		
		explosive_piece.is_explosive = true
		explosive_piece.color = color
		explosive_piece.special_type = "bomb"  # <-- nuevo
		
		if (all_pieces[position.x][position.y] != null):
			var normal_piece = all_pieces[position.x][position.y]
			if is_instance_valid(normal_piece) and normal_piece.has_method("queue_free"):
				normal_piece.queue_free()
		
		all_pieces[position.x][position.y] = explosive_piece

func create_special_piece(position: Vector2, color: String):
	if (color in special_piece_i): 
		var special_i = special_piece_i[color]
		var special_piece = special_pieces[special_i].instantiate()
		add_child(special_piece)
		special_piece.position = grid_to_pixel(position.x, position.y)
		
		if (all_pieces[position.x][position.y] !=null):
			var normal_piece = all_pieces[position.x][position.y]
			if is_instance_valid(normal_piece) and normal_piece.has_method("queue_free"):
				normal_piece.queue_free()
				
		all_pieces[position.x][position.y] = special_piece
		special_piece.color = color
		special_piece.special_type = "line"  # <-- nuevo

		
func destroy_matched():
	var was_matched = false
	var pieces_destroyed = 0

	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				var piece = all_pieces[i][j]
				was_matched = true
				pieces_destroyed += 1

				# Si es especial -> activar su poder
				if piece.special_type != null or piece.is_explosive:
					piece.explode(self)

				# Eliminar la pieza
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null

	# si hubo destrucciones, sumar puntaje
	if pieces_destroyed > 0:
		score += pieces_destroyed * 10  # 10 puntos por pieza destruida
		emit_signal("score_changed", score)
		print("Score: ", score)

	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
		movement -= 1
		emit_signal("movements_changed", movement)
		check_game_over()
	else:
		swap_back()


func explode_line(position: Vector2):
	var grid_pos = pixel_to_grid(position.x, position.y)
	var col = grid_pos.x
	var row = grid_pos.y

	# Aleatoriamente destruye fila o columna (puedes decidir fijo si prefieres)
	if randi() % 2 == 0:
		# Destruir fila
		for x in width:
			if all_pieces[x][row] != null:
				all_pieces[x][row].matched = true
				all_pieces[x][row].dim()
	else:
		# Destruir columna
		for y in height:
			if all_pieces[col][y] != null:
				all_pieces[col][y].matched = true
				all_pieces[col][y].dim()
	get_parent().get_node("destroy_timer").start()

func explode_area(position: Vector2):
	var grid_pos = pixel_to_grid(position.x, position.y)
	var col = grid_pos.x
	var row = grid_pos.y

	for x in range(col - 1, col + 2):
		for y in range(row - 1, row + 2):
			if in_grid(x, y) and all_pieces[x][y] != null:
				all_pieces[x][y].matched = true
				all_pieces[x][y].dim()
	get_parent().get_node("destroy_timer").start()


func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				print(i, j)
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# random number
				var rand = randi_range(0, possible_pieces.size() - 1)
				# instance 
				var piece = possible_pieces[rand].instantiate()
				# repeat until no matches
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	state = MOVE
	
	move_checked = false

func _on_destroy_timer_timeout():
	print("destroy")
	destroy_matched()

func _on_collapse_timer_timeout():
	print("collapse")
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()
	
func check_game_over():
	# Verificacion game over
	if time_left <= 0 or movement <= 0:
		game_over()
		return true
	return false
	
func game_over():
	state = WAIT
	score_final = score
	print("GAME OVER")
	print("Tiempo restante: ", time_left)
	print("Movimientos restantes: ", movement)
	print("Reiniciando en 3 segundos...")
	print("tu score final es: ", score_final)
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
