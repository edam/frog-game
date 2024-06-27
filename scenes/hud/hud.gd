extends CanvasLayer

const CHAT_SPEED = 25 # characters per second

@onready var _main = get_node('/root/Main')

@export_category("HUD")
@export_range(0.0, 1.0) var fade: float = 0.0:
	get:
		return %Fade.color.a
	set(value):
		if is_inside_tree():
			%Fade.color.a = value

var _is_pink = false
var _speaker: TextureRect
var _time: float
var _text = ''
var _text_now = ''
var _text_prefix: String
var _text_suffix: String
var _sound: AudioStreamPlayer
var _was_paused = false
var _pause_fade = 0.0

func _ready() -> void:
	_is_pink = _main.game.state('Player.pink', false)
	%Chat.visible = false
	%Templates.visible = false
	%Chat/Polygon2D.visible = false
	%Congrats.visible = false
	%Congrats.process_mode = Node.PROCESS_MODE_DISABLED
	%PauseMenu.visible = false
	%LevelMenu.visible = false
	fade = 1

func _recalc_lives():
	_recalc_items(%Templates/Pink if _is_pink else %Templates/Frog, lives, 1, %Lives)

func _recalc_items(template: TextureRect, count: int, dir: int, container: Node2D):

	# remove surplus
	var kids = container.get_children()
	for i in range(kids.size()):
		if i >= count:
			var kid = kids[i]
			container.remove_child(kid)
			kid.queue_free()

	# add deficit
	for i in range(count):
		if i >= kids.size():
			var kid = template.duplicate()
			kid.position.x += i * 72 * dir
			container.add_child(kid)

func _process(delta: float) -> void:

	if !get_tree().paused:
		_time += delta

	if _text != '':

		# reveal text
		var length = min(ceil(_time * CHAT_SPEED), _text.length())
		if length > _text_now.length():
			_text_now = _text.left(length)
			%Chat/Text.text = _text_prefix + _text_now + _text_suffix
			if _text_now.length() == _text.length():
				_text = ''
				_sound.stop()
				%Chat/Polygon2D.visible = true

	# check for presses
	var press = Input.is_action_just_pressed('down') || Input.is_action_just_pressed('use')
	if press && %Chat/Polygon2D.visible && !get_tree().paused:
		_main.game.advance_chat()
	elif press && _text != '':
		_time = 9999

	# check player pink
	var pink = _main.game.state('Player.pink', false)
	if pink != _is_pink:
		_is_pink = pink
		for kid in %Lives.get_children():
			%Lives.remove_child(kid)
			kid.queue_free()
		_recalc_lives()

	if get_tree().paused && _was_paused && Input.is_action_just_pressed('menu'):
		end_pause_menu()
	_was_paused = get_tree().paused

func _on_menu_button_pressed() -> void:
	if !get_tree().paused:
		start_pause_menu()

func _on_unpause_button_pressed() -> void:
	end_pause_menu()

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	_main.end_game()

func _after_level_screen():
	%LevelMenu.visible = false

# --

# number of lives
var lives:
	set(value):
		lives = value
		_recalc_lives()

# number of cups
var cups: int = 0:
	set(value):
		cups = value
		_recalc_items(%Templates/Cup, value, -1, %Cups)

var pausable = true

# max number of cups
var max_cups: int = 0:
	set(value):
		max_cups = value
		_recalc_items(%Templates/CupBg, value, -1, %CupBgs)

# turn on chat (with a message)
func chat(frog: bool, text: String):
	%Chat/Text.text = ''
	%Chat/Polygon2D.visible = false
	%Chat.visible = true
	_time = 0.0
	_text = text
	_text_now = ''
	(%Chat/Pink if frog else %Chat/Frog).visible = false
	_speaker = %Chat/Frog if frog else %Chat/Pink
	_speaker.visible = true
	_sound = _main.sound('chat')
	_sound.pitch_scale = 1.2 if frog else 0.9
	%AnimationPlayer.play('flash-arrow')

# turn off chat
func chat_off():
	%Chat.visible = false
	%Chat/Polygon2D.visible = false

# bring up menu
func start_pause_menu():
	if !pausable: return
	print("pause")
	get_tree().paused = true
	_pause_fade = fade
	fade = maxf(_pause_fade, 0.5)
	%PauseMenu.visible = true
	%PauseMenu.find_children("*", "Button")[0].grab_focus()
	%MenuButton.disabled = true

# end pause
func end_pause_menu():
	print("unpause")
	fade = _pause_fade
	%PauseMenu.visible = false
	get_tree().paused = false
	%MenuButton.disabled = false

# start congrats sequence
func start_congrats():
	pausable = false
	%Congrats.visible = true
	%Congrats.process_mode = Node.PROCESS_MODE_INHERIT
	%AnimationPlayer.play('congrats')

# end congrats sequence
func end_congrats():
	_main.end_game()

# bring up title
func start_level_screen():
	print("start level screen")
	%LevelMenu.visible = true
	%MenuButton.visible = true
	%Cups.visible = true
	%Lives.visible = true
	%Fade.visible = true
	fade = 1
	get_tree().paused = false
	%AnimationPlayer.play("start-level-screen")
