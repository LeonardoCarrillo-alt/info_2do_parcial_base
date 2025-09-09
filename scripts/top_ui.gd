extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
@onready var timer_label = $MarginContainer/HBoxContainer/time_label

var current_score = 0
var current_count = 0
var time = 0

func _ready():
	var node_p = get_parent()
	var game = node_p.get_node("grid")
	game.connect("time_changed", Callable(self, "_on_time_change"))
	timer_label.text = str(time)
	game.connect("movements_changed", Callable(self, "on_movements_change"))
	
	game.connect("score_changed", Callable(self, "_on_score_change"))

func _on_time_change (new_timer): 
	time = new_timer
	timer_label.text = str(time)

func on_movements_change (new_count): 
	current_count = new_count
	counter_label.text = str(current_count)

func _on_score_change (new_score):
	current_score = new_score
	score_label.text = str(current_score)
	
