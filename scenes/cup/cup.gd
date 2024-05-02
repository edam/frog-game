extends Area2D

var _collected = false

@onready var _main = get_node('/root/Main')

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_collected = _main.game_state(self.name, false)

func _on_body_entered(_body: Node2D) -> void:
	if !_collected:
		_collected = true
		_main.set_game_state(self.name, true)
		visible = false
		_main.collect_cup()
		_main.sound('cup')
