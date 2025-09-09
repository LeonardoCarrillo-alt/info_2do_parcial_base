extends Node2D

@export var color: String
var matched = false
var special_type = null # "line", "bomb" o null
@export var is_explosive: bool = false # nueva propiedad para dulces explosivos permanentes



func dim():
	modulate = Color(1, 1, 1, 0.5)

func move(target: Vector2):
	position = target

func explode(board):
	# Solo explota si es un tipo especial activo
	if special_type == "line":
		board.explode_line(position)
	elif special_type == "bomb" or is_explosive:
		board.explode_area(position)
	elif is_explosive:
		# Ejemplo: puedes hacer que explote como un "bomb" cuando se active
		board.explode_area(position)
