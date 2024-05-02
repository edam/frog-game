extends CharacterBody2D


const SPEED = 500.0
const JUMP_VELOCITY = 780.0
const DECELERATE = SPEED * 5
const PINK_JUMP_BOOST = 100
const PINK_SPEED_BOOST = -250
const DIE_JUMP = 500

var _is_pink = false
var _gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var _direction = 0
var _jump = false
var _dead = false
var _frozen = 0
var _restart_pos: Vector2
var _last_floor_pos: Vector2
var _default_collision_layer = 0
var _default_collision_mask = 0

@onready var _main = get_node('/root/Main')

func _ready() -> void:
	_is_pink = _main.game_state(self.name + '.pink', false)
	_last_floor_pos = position
	_restart_pos = position
	_default_collision_layer = self.collision_layer
	_default_collision_mask = self.collision_mask

func _physics_process(delta):

	if _dead || not is_on_floor():
		# Add the gravity.
		velocity.y += _gravity * delta
	else:
		# track when we were on land
		_last_floor_pos = position

	# Handle jump.
	if _jump && !_dead:
		if is_on_floor():
			var boost = JUMP_VELOCITY + (PINK_JUMP_BOOST if _is_pink else 0)
			velocity.y = -boost
			get_node('/root/Main').sound('jump')
		_jump = false

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if _direction && !_dead:
		var speed = SPEED + (PINK_SPEED_BOOST if _is_pink else 0)
		velocity.x = _direction * speed
	elif !_dead:
		velocity.x = move_toward(velocity.x, 0, DECELERATE * delta)

	# enforce frozen
	if _frozen > 0:
		velocity = Vector2(0, 0)

	move_and_slide()

	var action = 'default'
	if _dead || not is_on_floor():
		action = 'jumping'
	elif abs(velocity.x) > 0.5:
		action = 'running'
	%Sprite2D.animation = _character() + '-' + action

	if abs(velocity.x) > 0.5:
		%Sprite2D.flip_h = velocity.x < 0

func _character() -> String:
	return 'pink' if _is_pink else 'frog'

func _process(_delta):
	var input = inputs and _frozen == 0

	# left/right
	_direction = Input.get_axis('left', 'right') if input else 0.0

	# jump
	_jump = Input.is_action_just_pressed('jump') if input else false

	# interact
	if input && Input.is_action_just_pressed('up') && is_on_floor():
		get_node('/root/Main').do_interact()

# --

# player will take input
@export var inputs = true

# freeze player
func freeze():
	_frozen += 1

# unfreeze player
func unfreeze():
	_frozen -= 1

# player died (and is out of bounds?)
func die(is_oob: bool):
	if _dead: return
	self.collision_layer = 0
	self.collision_mask = 0
	_dead = true
	inputs = false
	_main.sound(_character() + '-die')
	if not is_oob:
		%AnimationPlayer.play('die')
		var x = clamp(velocity.x, -SPEED / 2, SPEED / 2)
		if abs(x) < SPEED / 8: x = SPEED / 8 * (-1 if x < 0 else 1)
		velocity = Vector2(x, -DIE_JUMP)

# is player dead?
func is_alive():
	return !_dead

# is player pink?
func is_pink() -> bool:
	return _is_pink

# switch to pink
func be_pink(pink: bool):
	_is_pink = pink
	_main.set_game_state(self.name + '.pink', pink)

func set_restart_point():
	if _dead: return
	_restart_pos = _last_floor_pos
	_main.set_game_state(self.name + '.restart', var_to_str(_last_floor_pos))

func reserect() -> void:
	if !_dead: return
	self.collision_layer = _default_collision_layer
	self.collision_mask = _default_collision_mask
	position = _restart_pos
	velocity = Vector2(0, 0)
	_dead = false
	inputs = true
	_frozen = 0
	%AnimationPlayer.play('default')
