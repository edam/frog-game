extends ReferenceRect

const WAVE_W = 4    # lateral movement
const WAVE_L = 512  # wavelength
const WAVE_V = 2    # velocity
const SMASH_T = 0.1 # seconds between blocks

var _smashed = false
var _time = 0.0
var _pop_time = 0.0
var _num = 0

@onready var _main = get_node('/root/Main')

func _ready() -> void:
	_smashed = _main.game.state(self.name, false)

	if !_smashed:
		# move collision box to mirror parent
		%CollisionShape2D.position = Vector2(floor(self.size.x / 2), floor(self.size.y / 2))
		%CollisionShape2D.shape = RectangleShape2D.new()
		%CollisionShape2D.shape.size = self.size

		# calculate number boxes
		_num = floor((self.size.y) / 64)
		for i in range(_num):
			var elem = Sprite2D.new()
			elem.position = Vector2(32, 32 + i * 64)
			elem.texture = %Sprite2D.texture
			elem.scale = Vector2(2, 2)
			elem.rotation = PI / 4
			%Elements.add_child(elem)
			if i * 64 + 64 < self.size.y:
				elem = Sprite2D.new()
				elem.position = Vector2(32, 64 + i * 64)
				elem.texture = %Sprite2D2.texture
				elem.scale = Vector2(2, 2)
				%Elements.add_child(elem)

func _physics_process(delta: float) -> void:
	_time += delta * WAVE_V

	if _pop_time < _time:
		_pop_time = _time + SMASH_T
		#_remove_bits()

		if _smashed && _num == 0:
			_main.game.release_camera(self.name)

		if _smashed && _num > 0:
			_num -= 1
			_main.sound("pop")

			# remove block
			var kids = %Elements.get_children()
			for i in range(kids.size()):
				var kid = kids[i]
				if i >= _num * 2:
					%Elements.remove_child(kid)
					kid.queue_free()

			# add bits
			var bits = preload('res://scenes/barricade/pop/pop.tscn').instantiate()
			bits.position = Vector2(32, 40 + _num * 64)
			%Bits.add_child(bits)

	for elem in %Elements.get_children():
		elem.position.x = 32 + sin(_time + elem.position.y / WAVE_L * 2 * PI) * WAVE_W

# --

# toggle element
func toggle(on: bool):
	if on:
		smash()

# smash barracade
func smash():
	if _smashed: return

	print("barricade smashed: ", self.name)
	_smashed = true
	_main.game.set_state(self.name, true)

	# remove collision box
	%CollisionShape2D.position = Vector2(0, 0)
	var colbox = %CollisionShape2D.shape as RectangleShape2D
	colbox.size = Vector2(0, 0)

	_main.game.capture_camera(self.name, self.position)
