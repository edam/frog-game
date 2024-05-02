extends Node2D

const ROTATE_SPEED = 25

@onready var _main = get_node('/root/Main')

var _on: bool

func _ready() -> void:
	_on = _main.game_state(self.name, false)

func _physics_process(delta: float) -> void:
	var a = deg_to_rad(135 if _on else 45)
	var d = ROTATE_SPEED * delta
	%Sprite2D.rotation = move_toward(%Sprite2D.rotation, a, d)

func _on_body_entered(_body: Node2D) -> void:
	_main.set_interaction(self.name, func():
		self.toggle())

func _on_body_exited(_body: Node2D) -> void:
	_main.unset_interaction(self.name)

# --

func toggle():
	print("lever pulled: ", self.name)
	_on = !_on
	_main.set_game_state(self.name, _on)
	_main.toggle_interactive(self.editor_description, _on)
	_main.sound('lever-' + ('on' if _on else 'off'))
