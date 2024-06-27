extends Area2D

var _frog = false
var _done = false

@onready var _main = get_node('/root/Main')

func _on_body_entered(_body: Node2D) -> void:
	var data = JSON.parse_string(self.editor_description)
	if _done:
		_main.game.start_chat(data.after, null)
	else:
		_main.game.start_chat(data.dialogue, func(): _main.game.switch_player())
		_done = true
		_main.game.set_state(self.name + '.done', true)

func _on_body_exited(_body: Node2D) -> void:
	_main.game.unset_interaction(self.name)

func _ready() -> void:
	_done = _main.game.state(self.name + '.done', false)
	_frog = !_main.game.state('Player.pink', false) # force redraw

func _process(_delta: float) -> void:
	var frog = _main.game.state('Player.pink', false)
	if frog != _frog:
		_frog = frog
		%AnimatedSprite2D.play('frog' if frog else 'pink')
