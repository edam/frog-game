extends ReferenceRect

@onready var _main = get_node('/root/Main')

var _on = false

func _ready() -> void:
	_on = _main.game.state(self.name, false)
	modulate = Color(1, 1, 1, 1) if _on else Color(1, 1, 1, 0)
	%StaticBody2D.collision_layer = 1 if _on else 0

	# add tiles
	var num = floor(size.x / 64)
	for i in range(num):
		var kid = %Sprite2D.duplicate()
		kid.visible = true
		kid.position.x += i * 64
		if i == num - 1:
			kid.frame += 2
		elif i > 0:
			kid.frame += 1
		%Parts.add_child(kid)

	# move collision box
	%CollisionShape2D.shape.size.x = num * 64
	%CollisionShape2D.position.x = num * 64 / 2

# --

func toggle(on: bool) -> void:
	if _on != on:
		_on = on
		_main.game.set_state(self.name, on)
		%AnimationPlayer.play('appear' if on else 'disappear')
		%StaticBody2D.collision_layer = 1 if on else 0
		if on: _main.game.capture_camera(self.name, self.position)

func anim_stop():
	_main.game.release_camera(self.name)
