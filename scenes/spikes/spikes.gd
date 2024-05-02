extends ColorRect

@onready var _main = get_node('/root/Main')

func _enter_tree() -> void:
	color = Color(0, 0, 0, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# move collision box
	%CollisionShape2D.position.x = size.x / 2
	%CollisionShape2D.shape = RectangleShape2D.new()
	%CollisionShape2D.shape.size = Vector2(size.x, 16)

	# lay out spikes
	for i in range(floor(self.size.x / 32)):
		if i == 0: continue
		var elem = %Sprite2D.duplicate()
		elem.position.x += i * 32
		add_child(elem)

func _on_area_2d_body_entered(_body: Node2D) -> void:
	_main.kill_player()
