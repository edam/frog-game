extends Area2D

@onready var _main = get_node('/root/Main')

func _on_body_entered(_body: Node2D) -> void:
	_main.game.set_interaction(self.name, func():
		_main.game.teleport(self.editor_description))

func _on_body_exited(_body: Node2D) -> void:
	_main.game.unset_interaction(self.name)

# --

func get_center() -> Vector2:
	return self.to_global(%CollisionShape2D.shape.get_rect().get_center())
