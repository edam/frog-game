extends CanvasLayer

const CHAT_SPEED = 25 # characters per second

@export_range(0.0, 1.0) var fade: float = 0.0:
	set(value):
		if %Fade != null:
			%Fade.color.a = value
	get:
		return %Fade.color.a

@onready var _main = get_node('/root/Main')

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
var _title = false

func _ready() -> void:
	_is_pink = _main.game_state('Player.pink', false)
	%Chat.visible = false
	%Templates.visible = false
	%Chat/Polygon2D.visible = false
	%Congrats.visible = false
	%Congrats.process_mode = Node.PROCESS_MODE_DISABLED
	%PauseMenu.visible = false
	%TitleMenu.visible = true
	%LevelMenu.visible = false

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
	if press && %Chat/Polygon2D.visible:
		_main.advance_chat()
	elif press && _text != '':
		_time = 9999
	if Input.is_action_just_pressed('menu') && %Chat.visible:
		_main.end_chat()

	# check player pink
	var pink = _main.game_state('Player.pink', false)
	if pink != _is_pink:
		_is_pink = pink
		for kid in %Lives.get_children():
			%Lives.remove_child(kid)
			kid.queue_free()
		_recalc_lives()

	if !_title && get_tree().paused && _was_paused && Input.is_action_just_pressed('menu'):
			end_pause_menu()
	_was_paused = get_tree().paused

func _on_menu_button_pressed() -> void:
	if !get_tree().paused:
		start_pause_menu()

func _on_unpause_button_pressed() -> void:
	end_pause_menu()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_start_button_pressed() -> void:
	%LevelMenu.visible = true
	%AnimationPlayer.play("title")

func _after_title():
	_title = false
	%TitleMenu.visible = false
	%LevelMenu.visible = false
	get_tree().paused = false
	%MenuButton.visible = true
	%Cups.visible = true
	%Lives.visible = true

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
	_pause_fade = fade
	fade = maxf(fade, 0.5)
	%PauseMenu.visible = true
	get_tree().paused = true
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
	get_tree().quit()

# bring up title
func start_title_menu():
	print("title")
	_title = true
	fade = 1
	%TitleMenu.visible = true
	get_tree().paused = true
	%MenuButton.visible = false
	%Cups.visible = false
	%Lives.visible = false
	%TitleMenu.find_children("*", "Button")[0].grab_focus()
	%AnimationPlayer.play('title-reset')
